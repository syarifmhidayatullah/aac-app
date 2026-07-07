package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
)

const profileCols = `id, user_id, name, settings, created_at, updated_at, deleted_at`

func scanProfile(row pgx.Row) (*model.Profile, error) {
	var p model.Profile
	err := row.Scan(&p.ID, &p.UserID, &p.Name, &p.Settings,
		&p.CreatedAt, &p.UpdatedAt, &p.DeletedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *Repo) ListProfiles(ctx context.Context, userID uuid.UUID) ([]model.Profile, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT `+profileCols+` FROM profiles
		WHERE user_id = $1 AND deleted_at IS NULL
		ORDER BY created_at`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	profiles := []model.Profile{}
	for rows.Next() {
		p, err := scanProfile(rows)
		if err != nil {
			return nil, err
		}
		profiles = append(profiles, *p)
	}
	return profiles, rows.Err()
}

func (r *Repo) GetProfile(ctx context.Context, userID, id uuid.UUID) (*model.Profile, error) {
	return scanProfile(r.pool.QueryRow(ctx, `
		SELECT `+profileCols+` FROM profiles
		WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`, id, userID))
}

// CreateProfile membuat profile baru; kalau seed != nil, papan (beserta
// sel-selnya) ikut dibuat dalam satu transaksi.
func (r *Repo) CreateProfile(ctx context.Context, p *model.Profile, seed *model.Board) (*model.Profile, error) {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	if len(p.Settings) == 0 {
		p.Settings = json.RawMessage(`{}`)
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	created, err := scanProfile(tx.QueryRow(ctx, `
		INSERT INTO profiles (id, user_id, name, settings)
		VALUES ($1, $2, $3, $4)
		RETURNING `+profileCols,
		p.ID, p.UserID, p.Name, p.Settings))
	if err != nil {
		return nil, fmt.Errorf("insert profile: %w", err)
	}

	if seed != nil {
		seed.ProfileID = created.ID
		if _, err := insertBoard(ctx, tx, seed); err != nil {
			return nil, fmt.Errorf("insert seed board: %w", err)
		}
		for i := range seed.Cells {
			seed.Cells[i].BoardID = seed.ID
			if err := upsertCell(ctx, tx, &seed.Cells[i]); err != nil {
				return nil, fmt.Errorf("insert seed cell: %w", err)
			}
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return created, nil
}

func (r *Repo) UpdateProfile(ctx context.Context, userID, id uuid.UUID, name string, settings json.RawMessage) (*model.Profile, error) {
	return scanProfile(r.pool.QueryRow(ctx, `
		UPDATE profiles
		SET name = $3, settings = COALESCE($4, settings)
		WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
		RETURNING `+profileCols,
		id, userID, name, settings))
}

// SoftDeleteProfile menandai profile beserta seluruh papan dan selnya
// sebagai terhapus (tombstone untuk sync).
func (r *Repo) SoftDeleteProfile(ctx context.Context, userID, id uuid.UUID) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	tag, err := tx.Exec(ctx, `
		UPDATE profiles SET deleted_at = now()
		WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`, id, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	if _, err := tx.Exec(ctx, `
		UPDATE cells SET deleted_at = now()
		WHERE deleted_at IS NULL
		  AND board_id IN (SELECT id FROM boards WHERE profile_id = $1)`, id); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `
		UPDATE boards SET deleted_at = now()
		WHERE profile_id = $1 AND deleted_at IS NULL`, id); err != nil {
		return err
	}

	return tx.Commit(ctx)
}
