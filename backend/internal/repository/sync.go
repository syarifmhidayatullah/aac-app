package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
)

// SyncData adalah payload pull/push sinkronisasi. Pull menyertakan baris
// terhapus (tombstone) supaya klien bisa menghapus data lokalnya.
type SyncData struct {
	ServerTime time.Time       `json:"server_time"`
	Profiles   []model.Profile `json:"profiles"`
	Boards     []model.Board   `json:"boards"`
	Cells      []model.Cell    `json:"cells"`
	Symbols    []model.Symbol  `json:"symbols"`
}

func (r *Repo) SyncPull(ctx context.Context, userID uuid.UUID, since time.Time) (*SyncData, error) {
	data := &SyncData{
		Profiles: []model.Profile{},
		Boards:   []model.Board{},
		Cells:    []model.Cell{},
		Symbols:  []model.Symbol{},
	}

	if err := r.pool.QueryRow(ctx, `SELECT now()`).Scan(&data.ServerTime); err != nil {
		return nil, err
	}

	rows, err := r.pool.Query(ctx, `
		SELECT `+profileCols+` FROM profiles
		WHERE user_id = $1 AND updated_at > $2`, userID, since)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		p, err := scanProfile(rows)
		if err != nil {
			return nil, err
		}
		data.Profiles = append(data.Profiles, *p)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	rows, err = r.pool.Query(ctx, `
		SELECT `+prefixCols("b", boardCols)+`
		FROM boards b
		JOIN profiles p ON p.id = b.profile_id
		WHERE p.user_id = $1 AND b.updated_at > $2`, userID, since)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		b, err := scanBoard(rows)
		if err != nil {
			return nil, err
		}
		data.Boards = append(data.Boards, *b)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	rows, err = r.pool.Query(ctx, `
		SELECT `+prefixCols("c", cellCols)+`
		FROM cells c
		JOIN boards b ON b.id = c.board_id
		JOIN profiles p ON p.id = b.profile_id
		WHERE p.user_id = $1 AND c.updated_at > $2`, userID, since)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		c, err := scanCell(rows)
		if err != nil {
			return nil, err
		}
		data.Cells = append(data.Cells, *c)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	rows, err = r.pool.Query(ctx, `
		SELECT `+symbolCols+` FROM symbols
		WHERE (owner_user_id IS NULL OR owner_user_id = $1) AND updated_at > $2`,
		userID, since)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		s, err := scanSymbol(rows)
		if err != nil {
			return nil, err
		}
		data.Symbols = append(data.Symbols, *s)
	}
	return data, rows.Err()
}

// SyncPush meng-upsert perubahan dari klien dalam satu transaksi.
// Kepemilikan diverifikasi per baris; konflik timestamp diselesaikan
// last-push-wins (server-authoritative updated_at).
func (r *Repo) SyncPush(ctx context.Context, userID uuid.UUID, data *SyncData) (time.Time, error) {
	var serverTime time.Time

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return serverTime, err
	}
	defer tx.Rollback(ctx)

	if err := tx.QueryRow(ctx, `SELECT now()`).Scan(&serverTime); err != nil {
		return serverTime, err
	}

	// Urutan mengikuti dependensi FK: profiles → symbols → boards → cells.
	for i := range data.Profiles {
		if err := pushProfile(ctx, tx, userID, &data.Profiles[i]); err != nil {
			return serverTime, fmt.Errorf("profile %s: %w", data.Profiles[i].ID, err)
		}
	}
	for i := range data.Symbols {
		if err := pushSymbol(ctx, tx, userID, &data.Symbols[i]); err != nil {
			return serverTime, fmt.Errorf("symbol %s: %w", data.Symbols[i].ID, err)
		}
	}
	for i := range data.Boards {
		if err := pushBoard(ctx, tx, userID, &data.Boards[i]); err != nil {
			return serverTime, fmt.Errorf("board %s: %w", data.Boards[i].ID, err)
		}
	}
	for i := range data.Cells {
		if err := pushCell(ctx, tx, userID, &data.Cells[i]); err != nil {
			return serverTime, fmt.Errorf("cell %s: %w", data.Cells[i].ID, err)
		}
	}

	return serverTime, tx.Commit(ctx)
}

func pushProfile(ctx context.Context, q querier, userID uuid.UUID, p *model.Profile) error {
	if len(p.Settings) == 0 {
		p.Settings = []byte(`{}`)
	}
	tag, err := q.Exec(ctx, `
		UPDATE profiles SET name = $3, settings = $4, deleted_at = $5
		WHERE id = $1 AND user_id = $2`,
		p.ID, userID, p.Name, p.Settings, p.DeletedAt)
	if err != nil {
		return err
	}
	if tag.RowsAffected() > 0 {
		return nil
	}
	_, err = q.Exec(ctx, `
		INSERT INTO profiles (id, user_id, name, settings, deleted_at)
		VALUES ($1, $2, $3, $4, $5)`,
		p.ID, userID, p.Name, p.Settings, p.DeletedAt)
	if isUniqueViolation(err, "profiles_pkey") {
		return ErrForbidden
	}
	return err
}

func pushSymbol(ctx context.Context, q querier, userID uuid.UUID, s *model.Symbol) error {
	if s.Keywords == nil {
		s.Keywords = []string{}
	}
	tag, err := q.Exec(ctx, `
		UPDATE symbols SET pack = $3, pack_ref = $4, label = $5, category = $6, keywords = $7,
			image_url = $8, deleted_at = $9
		WHERE id = $1 AND owner_user_id = $2`,
		s.ID, userID, s.Pack, s.PackRef, s.Label, s.Category, s.Keywords, s.ImageURL, s.DeletedAt)
	if err != nil {
		return err
	}
	if tag.RowsAffected() > 0 {
		return nil
	}
	_, err = q.Exec(ctx, `
		INSERT INTO symbols (id, owner_user_id, pack, pack_ref, label, category, keywords, image_url, deleted_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		s.ID, userID, s.Pack, s.PackRef, s.Label, s.Category, s.Keywords, s.ImageURL, s.DeletedAt)
	if isUniqueViolation(err, "symbols_pkey") {
		return ErrForbidden
	}
	return err
}

func pushBoard(ctx context.Context, q querier, userID uuid.UUID, b *model.Board) error {
	tag, err := q.Exec(ctx, `
		UPDATE boards SET profile_id = $2, name = $3, grid_rows = $4,
			grid_cols = $5, is_root = $6, deleted_at = $7
		FROM profiles pold, profiles pnew
		WHERE boards.id = $1
		  AND pold.id = boards.profile_id AND pold.user_id = $8
		  AND pnew.id = $2 AND pnew.user_id = $8`,
		b.ID, b.ProfileID, b.Name, b.GridRows, b.GridCols, b.IsRoot, b.DeletedAt, userID)
	if err != nil {
		return checkBoardPushErr(err)
	}
	if tag.RowsAffected() > 0 {
		return nil
	}
	tag, err = q.Exec(ctx, `
		INSERT INTO boards (id, profile_id, name, grid_rows, grid_cols, is_root, deleted_at)
		SELECT $1::uuid, $2::uuid, $3::text, $4::int, $5::int, $6::boolean, $7::timestamptz
		WHERE EXISTS (SELECT 1 FROM profiles WHERE id = $2 AND user_id = $8)`,
		b.ID, b.ProfileID, b.Name, b.GridRows, b.GridCols, b.IsRoot, b.DeletedAt, userID)
	if err != nil {
		return checkBoardPushErr(err)
	}
	if tag.RowsAffected() == 0 {
		return ErrForbidden
	}
	return nil
}

func checkBoardPushErr(err error) error {
	if isUniqueViolation(err, "boards_pkey") {
		return ErrForbidden
	}
	if isUniqueViolation(err, "boards_one_root_per_profile_uq") {
		return fmt.Errorf("%w: profile already has a root board", ErrConflict)
	}
	return err
}

func pushCell(ctx context.Context, q querier, userID uuid.UUID, c *model.Cell) error {
	tag, err := q.Exec(ctx, `
		UPDATE cells SET board_id = $2, row_index = $3, col_index = $4, label = $5,
			speak_text = $6, symbol_id = $7, background_color = $8,
			action_type = $9, target_board_id = $10, deleted_at = $11
		FROM boards bold, profiles pold, boards bnew, profiles pnew
		WHERE cells.id = $1
		  AND bold.id = cells.board_id AND pold.id = bold.profile_id AND pold.user_id = $12
		  AND bnew.id = $2 AND pnew.id = bnew.profile_id AND pnew.user_id = $12`,
		c.ID, c.BoardID, c.RowIndex, c.ColIndex, c.Label, c.SpeakText, c.SymbolID,
		c.BackgroundColor, c.ActionType, c.TargetBoardID, c.DeletedAt, userID)
	if err != nil {
		return checkCellPushErr(err)
	}
	if tag.RowsAffected() > 0 {
		return nil
	}
	tag, err = q.Exec(ctx, `
		INSERT INTO cells (id, board_id, row_index, col_index, label, speak_text,
			symbol_id, background_color, action_type, target_board_id, deleted_at)
		SELECT $1::uuid, $2::uuid, $3::int, $4::int, $5::text, $6::text,
			$7::uuid, $8::text, $9::text, $10::uuid, $11::timestamptz
		WHERE EXISTS (
			SELECT 1 FROM boards b JOIN profiles p ON p.id = b.profile_id
			WHERE b.id = $2 AND p.user_id = $12)`,
		c.ID, c.BoardID, c.RowIndex, c.ColIndex, c.Label, c.SpeakText, c.SymbolID,
		c.BackgroundColor, c.ActionType, c.TargetBoardID, c.DeletedAt, userID)
	if err != nil {
		return checkCellPushErr(err)
	}
	if tag.RowsAffected() == 0 {
		return ErrForbidden
	}
	return nil
}

func checkCellPushErr(err error) error {
	if isUniqueViolation(err, "cells_pkey") {
		return ErrForbidden
	}
	if isUniqueViolation(err, "cells_position_uq") {
		return fmt.Errorf("%w: duplicate cell position", ErrConflict)
	}
	return err
}
