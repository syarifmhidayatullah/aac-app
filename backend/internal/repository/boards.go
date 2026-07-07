package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
)

const boardCols = `id, profile_id, name, grid_rows, grid_cols, is_root, created_at, updated_at, deleted_at`

const cellCols = `id, board_id, row_index, col_index, label, speak_text, symbol_id,
	background_color, action_type, target_board_id, created_at, updated_at, deleted_at`

func scanBoard(row pgx.Row) (*model.Board, error) {
	var b model.Board
	err := row.Scan(&b.ID, &b.ProfileID, &b.Name, &b.GridRows, &b.GridCols,
		&b.IsRoot, &b.CreatedAt, &b.UpdatedAt, &b.DeletedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &b, nil
}

func scanCell(row pgx.Row) (*model.Cell, error) {
	var c model.Cell
	err := row.Scan(&c.ID, &c.BoardID, &c.RowIndex, &c.ColIndex, &c.Label,
		&c.SpeakText, &c.SymbolID, &c.BackgroundColor, &c.ActionType,
		&c.TargetBoardID, &c.CreatedAt, &c.UpdatedAt, &c.DeletedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func insertBoard(ctx context.Context, q querier, b *model.Board) (*model.Board, error) {
	if b.ID == uuid.Nil {
		b.ID = uuid.New()
	}
	created, err := scanBoard(q.QueryRow(ctx, `
		INSERT INTO boards (id, profile_id, name, grid_rows, grid_cols, is_root)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING `+boardCols,
		b.ID, b.ProfileID, b.Name, b.GridRows, b.GridCols, b.IsRoot))
	if isUniqueViolation(err, "boards_one_root_per_profile_uq") {
		return nil, fmt.Errorf("%w: profile already has a root board", ErrConflict)
	}
	return created, err
}

func upsertCell(ctx context.Context, q querier, c *model.Cell) error {
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	_, err := q.Exec(ctx, `
		INSERT INTO cells (id, board_id, row_index, col_index, label, speak_text,
			symbol_id, background_color, action_type, target_board_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		ON CONFLICT (id) DO UPDATE SET
			board_id = EXCLUDED.board_id,
			row_index = EXCLUDED.row_index,
			col_index = EXCLUDED.col_index,
			label = EXCLUDED.label,
			speak_text = EXCLUDED.speak_text,
			symbol_id = EXCLUDED.symbol_id,
			background_color = EXCLUDED.background_color,
			action_type = EXCLUDED.action_type,
			target_board_id = EXCLUDED.target_board_id,
			deleted_at = NULL`,
		c.ID, c.BoardID, c.RowIndex, c.ColIndex, c.Label, c.SpeakText,
		c.SymbolID, c.BackgroundColor, c.ActionType, c.TargetBoardID)
	return err
}

func (r *Repo) ListBoards(ctx context.Context, userID, profileID uuid.UUID) ([]model.Board, error) {
	if _, err := r.GetProfile(ctx, userID, profileID); err != nil {
		return nil, err
	}
	rows, err := r.pool.Query(ctx, `
		SELECT `+boardCols+` FROM boards
		WHERE profile_id = $1 AND deleted_at IS NULL
		ORDER BY is_root DESC, created_at`, profileID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	boards := []model.Board{}
	for rows.Next() {
		b, err := scanBoard(rows)
		if err != nil {
			return nil, err
		}
		boards = append(boards, *b)
	}
	return boards, rows.Err()
}

// CreateBoard membuat papan (opsional beserta sel-selnya) untuk profile
// milik user.
func (r *Repo) CreateBoard(ctx context.Context, userID uuid.UUID, b *model.Board) (*model.Board, error) {
	if _, err := r.GetProfile(ctx, userID, b.ProfileID); err != nil {
		return nil, err
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	created, err := insertBoard(ctx, tx, b)
	if err != nil {
		return nil, err
	}
	for i := range b.Cells {
		b.Cells[i].BoardID = created.ID
		if err := upsertCell(ctx, tx, &b.Cells[i]); err != nil {
			return nil, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	created.Cells, err = r.listCells(ctx, created.ID)
	return created, err
}

// GetBoard mengembalikan papan beserta sel aktifnya.
func (r *Repo) GetBoard(ctx context.Context, userID, id uuid.UUID) (*model.Board, error) {
	b, err := scanBoard(r.pool.QueryRow(ctx, `
		SELECT `+prefixCols("b", boardCols)+`
		FROM boards b
		JOIN profiles p ON p.id = b.profile_id
		WHERE b.id = $1 AND p.user_id = $2 AND b.deleted_at IS NULL`, id, userID))
	if err != nil {
		return nil, err
	}
	b.Cells, err = r.listCells(ctx, id)
	return b, err
}

func (r *Repo) listCells(ctx context.Context, boardID uuid.UUID) ([]model.Cell, error) {
	rows, err := r.pool.Query(ctx, `
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

func (r *Repo) UpdateBoard(ctx context.Context, userID, id uuid.UUID, name string, gridRows, gridCols int) (*model.Board, error) {
	return scanBoard(r.pool.QueryRow(ctx, `
		UPDATE boards b
		SET name = $3, grid_rows = $4, grid_cols = $5
		FROM profiles p
		WHERE b.id = $1 AND p.id = b.profile_id AND p.user_id = $2
		  AND b.deleted_at IS NULL
		RETURNING `+prefixCols("b", boardCols),
		id, userID, name, gridRows, gridCols))
}

// ReplaceCells mengganti seluruh isi grid papan secara atomik: sel lama
// jadi tombstone, sel baru di-upsert (ID stabil dari klien dipertahankan).
func (r *Repo) ReplaceCells(ctx context.Context, userID, boardID uuid.UUID, cells []model.Cell) ([]model.Cell, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	if _, err := scanBoard(tx.QueryRow(ctx, `
		SELECT `+prefixCols("b", boardCols)+`
		FROM boards b
		JOIN profiles p ON p.id = b.profile_id
		WHERE b.id = $1 AND p.user_id = $2 AND b.deleted_at IS NULL`,
		boardID, userID)); err != nil {
		return nil, err
	}

	// Tolak ID sel yang ternyata milik papan lain, supaya upsert tidak
	// bisa "mencuri"/memindahkan sel di luar papan ini.
	ids := make([]uuid.UUID, 0, len(cells))
	for i := range cells {
		if cells[i].ID != uuid.Nil {
			ids = append(ids, cells[i].ID)
		}
	}
	if len(ids) > 0 {
		var n int
		if err := tx.QueryRow(ctx, `
			SELECT count(*) FROM cells
			WHERE id = ANY($1) AND board_id <> $2`, ids, boardID).Scan(&n); err != nil {
			return nil, err
		}
		if n > 0 {
			return nil, fmt.Errorf("%w: cell id belongs to another board", ErrConflict)
		}
	}

	if _, err := tx.Exec(ctx, `
		UPDATE cells SET deleted_at = now()
		WHERE board_id = $1 AND deleted_at IS NULL`, boardID); err != nil {
		return nil, err
	}
	for i := range cells {
		cells[i].BoardID = boardID
		if err := upsertCell(ctx, tx, &cells[i]); err != nil {
			return nil, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return r.listCells(ctx, boardID)
}

func (r *Repo) SoftDeleteBoard(ctx context.Context, userID, id uuid.UUID) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(ctx, `
		UPDATE boards b SET deleted_at = now()
		FROM profiles p
		WHERE b.id = $1 AND p.id = b.profile_id AND p.user_id = $2
		  AND b.deleted_at IS NULL`, id, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	if _, err := tx.Exec(ctx, `
		UPDATE cells SET deleted_at = now()
		WHERE board_id = $1 AND deleted_at IS NULL`, id); err != nil {
		return err
	}
	return tx.Commit(ctx)
}
