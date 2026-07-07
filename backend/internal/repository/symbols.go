package repository

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
)

const symbolCols = `id, owner_user_id, pack, pack_ref, label, keywords, image_url, license,
	created_at, updated_at, deleted_at`

func scanSymbol(row pgx.Row) (*model.Symbol, error) {
	var s model.Symbol
	err := row.Scan(&s.ID, &s.OwnerUserID, &s.Pack, &s.PackRef, &s.Label,
		&s.Keywords, &s.ImageURL, &s.License, &s.CreatedAt, &s.UpdatedAt, &s.DeletedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// SearchSymbols mencari di pustaka bawaan (owner NULL) + simbol custom
// milik user; q dicocokkan ke label dan keywords.
func (r *Repo) SearchSymbols(ctx context.Context, userID uuid.UUID, q, pack string, limit, offset int) ([]model.Symbol, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT `+symbolCols+` FROM symbols
		WHERE deleted_at IS NULL
		  AND (owner_user_id IS NULL OR owner_user_id = $1)
		  AND ($2 = '' OR pack = $2)
		  AND ($3 = '' OR label ILIKE '%' || $3 || '%'
		       OR EXISTS (SELECT 1 FROM unnest(keywords) kw WHERE kw ILIKE '%' || $3 || '%'))
		ORDER BY label
		LIMIT $4 OFFSET $5`,
		userID, pack, q, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	symbols := []model.Symbol{}
	for rows.Next() {
		s, err := scanSymbol(rows)
		if err != nil {
			return nil, err
		}
		symbols = append(symbols, *s)
	}
	return symbols, rows.Err()
}

func (r *Repo) CreateSymbol(ctx context.Context, s *model.Symbol) (*model.Symbol, error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	if s.Keywords == nil {
		s.Keywords = []string{}
	}
	return scanSymbol(r.pool.QueryRow(ctx, `
		INSERT INTO symbols (id, owner_user_id, pack, pack_ref, label, keywords, image_url, license)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING `+symbolCols,
		s.ID, s.OwnerUserID, s.Pack, s.PackRef, s.Label, s.Keywords, s.ImageURL, s.License))
}

func (r *Repo) SoftDeleteSymbol(ctx context.Context, userID, id uuid.UUID) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE symbols SET deleted_at = now()
		WHERE id = $1 AND owner_user_id = $2 AND deleted_at IS NULL`, id, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}
