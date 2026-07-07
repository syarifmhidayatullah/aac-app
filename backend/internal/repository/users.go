package repository

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
)

const userCols = `id, email, display_name, avatar_url, password_hash, google_id, created_at, updated_at`

func scanUser(row pgx.Row) (*model.User, error) {
	var u model.User
	err := row.Scan(&u.ID, &u.Email, &u.DisplayName, &u.AvatarURL,
		&u.PasswordHash, &u.GoogleID, &u.CreatedAt, &u.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}

type NewUser struct {
	Email        string
	DisplayName  string
	PasswordHash *string
	GoogleID     *string
	AvatarURL    *string
}

func (r *Repo) CreateUser(ctx context.Context, nu NewUser) (*model.User, error) {
	u, err := scanUser(r.pool.QueryRow(ctx, `
		INSERT INTO users (email, display_name, password_hash, google_id, avatar_url)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING `+userCols,
		nu.Email, nu.DisplayName, nu.PasswordHash, nu.GoogleID, nu.AvatarURL))
	if isUniqueViolation(err, "users_email_key") {
		return nil, ErrEmailTaken
	}
	return u, err
}

func (r *Repo) GetUserByID(ctx context.Context, id uuid.UUID) (*model.User, error) {
	return scanUser(r.pool.QueryRow(ctx,
		`SELECT `+userCols+` FROM users WHERE id = $1`, id))
}

func (r *Repo) GetUserByEmail(ctx context.Context, email string) (*model.User, error) {
	return scanUser(r.pool.QueryRow(ctx,
		`SELECT `+userCols+` FROM users WHERE email = $1`, email))
}

func (r *Repo) GetUserByGoogleID(ctx context.Context, googleID string) (*model.User, error) {
	return scanUser(r.pool.QueryRow(ctx,
		`SELECT `+userCols+` FROM users WHERE google_id = $1`, googleID))
}

// LinkGoogleAccount menghubungkan akun email/password yang sudah ada
// dengan akun Google (avatar hanya diisi kalau belum ada).
func (r *Repo) LinkGoogleAccount(ctx context.Context, userID uuid.UUID, googleID string, avatarURL *string) (*model.User, error) {
	return scanUser(r.pool.QueryRow(ctx, `
		UPDATE users
		SET google_id = $2, avatar_url = COALESCE(avatar_url, $3)
		WHERE id = $1
		RETURNING `+userCols,
		userID, googleID, avatarURL))
}
