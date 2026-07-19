package repository

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
)

const shareTTL = 7 * 24 * time.Hour

// Alfabet tanpa karakter ambigu (0/O, 1/I/L) supaya kode mudah
// dibacakan lewat telepon/chat.
const shareAlphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"

const shareCodeLen = 8

func newShareCode() (string, error) {
	buf := make([]byte, shareCodeLen)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	for i, b := range buf {
		buf[i] = shareAlphabet[int(b)%len(shareAlphabet)]
	}
	return string(buf), nil
}

// CreateBoardShare membuat kode berbagi untuk papan milik user.
func (r *Repo) CreateBoardShare(ctx context.Context, userID, boardID uuid.UUID) (*model.BoardShare, error) {
	// Verifikasi kepemilikan + papan masih aktif.
	if _, err := r.GetBoard(ctx, userID, boardID); err != nil {
		return nil, err
	}

	// Retry kecil untuk tabrakan kode (praktis tak pernah terjadi).
	for attempt := 0; attempt < 3; attempt++ {
		code, err := newShareCode()
		if err != nil {
			return nil, err
		}
		share := &model.BoardShare{}
		err = r.pool.QueryRow(ctx, `
			INSERT INTO board_shares (code, board_id, created_by, expires_at)
			VALUES ($1, $2, $3, now() + $4::interval)
			RETURNING code, board_id, created_by, created_at, expires_at`,
			code, boardID, userID, shareTTL.String()).
			Scan(&share.Code, &share.BoardID, &share.CreatedBy,
				&share.CreatedAt, &share.ExpiresAt)
		if isUniqueViolation(err, "board_shares_pkey") {
			continue
		}
		if err != nil {
			return nil, err
		}
		return share, nil
	}
	return nil, fmt.Errorf("could not generate a unique share code")
}

// ImportSharedBoard menyalin papan dari kode berbagi ke profile milik
// pemanggil: board + sel aktif dengan id baru; simbol custom milik
// pembagi ikut disalin (kepemilikan pindah ke pengimpor), simbol pack
// global dipakai apa adanya. Sel navigate kehilangan target (papan
// tujuannya tidak ikut dibagikan).
func (r *Repo) ImportSharedBoard(ctx context.Context, userID uuid.UUID, code string, profileID uuid.UUID) (*model.Board, error) {
	if _, err := r.GetProfile(ctx, userID, profileID); err != nil {
		return nil, err
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	src, err := scanBoard(tx.QueryRow(ctx, `
		SELECT `+prefixCols("b", boardCols)+`
		FROM board_shares s
		JOIN boards b ON b.id = s.board_id
		WHERE s.code = $1 AND s.expires_at > now() AND b.deleted_at IS NULL`,
		code))
	if errors.Is(err, ErrNotFound) {
		return nil, fmt.Errorf("%w: share code is invalid or expired", ErrNotFound)
	}
	if err != nil {
		return nil, err
	}

	newBoardID := uuid.New()
	if _, err := tx.Exec(ctx, `
		INSERT INTO boards (id, profile_id, name, grid_rows, grid_cols, is_root)
		VALUES ($1, $2, $3, $4, $5, false)`,
		newBoardID, profileID, src.Name, src.GridRows, src.GridCols); err != nil {
		return nil, err
	}

	// Salin simbol milik pembagi yang direferensikan sel; hasilnya milik
	// pengimpor. Simbol global (owner NULL) atau yang sudah milik
	// pengimpor tidak perlu disalin.
	remap := map[uuid.UUID]uuid.UUID{}
	rows, err := tx.Query(ctx, `
		SELECT DISTINCT s.id
		FROM cells c
		JOIN symbols s ON s.id = c.symbol_id
		WHERE c.board_id = $1 AND c.deleted_at IS NULL
		  AND s.owner_user_id IS NOT NULL AND s.owner_user_id <> $2`,
		src.ID, userID)
	if err != nil {
		return nil, err
	}
	srcSymbolIDs := []uuid.UUID{}
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return nil, err
		}
		srcSymbolIDs = append(srcSymbolIDs, id)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for _, srcID := range srcSymbolIDs {
		newID := uuid.New()
		remap[srcID] = newID
		if _, err := tx.Exec(ctx, `
			INSERT INTO symbols (id, owner_user_id, pack, pack_ref, label,
				keywords, image_url, license)
			SELECT $1, $2, pack, pack_ref, label, keywords, image_url, license
			FROM symbols WHERE id = $3`, newID, userID, srcID); err != nil {
			return nil, err
		}
	}

	srcCells, err := listCellsTx(ctx, tx, src.ID)
	if err != nil {
		return nil, err
	}
	for i := range srcCells {
		c := srcCells[i]
		symbolID := c.SymbolID
		if symbolID != nil {
			if mapped, ok := remap[*symbolID]; ok {
				symbolID = &mapped
			}
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO cells (id, board_id, row_index, col_index, label,
				speak_text, symbol_id, background_color, action_type, target_board_id)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NULL)`,
			uuid.New(), newBoardID, c.RowIndex, c.ColIndex, c.Label,
			c.SpeakText, symbolID, c.BackgroundColor, c.ActionType); err != nil {
			return nil, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return r.GetBoard(ctx, userID, newBoardID)
}

func listCellsTx(ctx context.Context, q querier, boardID uuid.UUID) ([]model.Cell, error) {
	rows, err := q.Query(ctx, `
		SELECT `+cellCols+` FROM cells
		WHERE board_id = $1 AND deleted_at IS NULL
		ORDER BY row_index, col_index`, boardID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	cells := []model.Cell{}
	for rows.Next() {
		c, err := scanCell(rows)
		if err != nil {
			return nil, err
		}
		cells = append(cells, *c)
	}
	return cells, rows.Err()
}
