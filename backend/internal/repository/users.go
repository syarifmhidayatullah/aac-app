package repository

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
)

const userCols = `id, email, display_name, avatar_url, is_verified, password_hash, google_id, created_at, updated_at`

func scanUser(row pgx.Row) (*model.User, error) {
	var u model.User
	err := row.Scan(&u.ID, &u.Email, &u.DisplayName, &u.AvatarURL, &u.IsVerified,
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
	IsVerified   bool
}

func (r *Repo) CreateUser(ctx context.Context, nu NewUser) (*model.User, error) {
	u, err := scanUser(r.pool.QueryRow(ctx, `
		INSERT INTO users (email, display_name, password_hash, google_id, avatar_url, is_verified)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING `+userCols,
		nu.Email, nu.DisplayName, nu.PasswordHash, nu.GoogleID, nu.AvatarURL, nu.IsVerified))
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
// dengan akun Google (avatar hanya diisi kalau belum ada). Google
// sudah verifikasi email-nya sendiri, jadi akun ikut ditandai
// terverifikasi.
func (r *Repo) LinkGoogleAccount(ctx context.Context, userID uuid.UUID, googleID string, avatarURL *string) (*model.User, error) {
	return scanUser(r.pool.QueryRow(ctx, `
		UPDATE users
		SET google_id = $2, avatar_url = COALESCE(avatar_url, $3), is_verified = true
		WHERE id = $1
		RETURNING `+userCols,
		userID, googleID, avatarURL))
}

// SaveVerificationToken menyimpan token verifikasi email baru untuk
// user. Token lama (kalau ada, dari resend sebelumnya) dibiarkan
// sampai expired sendiri — masing-masing token valid sekali pakai.
func (r *Repo) SaveVerificationToken(ctx context.Context, userID uuid.UUID, token string, expiresAt time.Time) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO email_verifications (token, user_id, expires_at)
		VALUES ($1, $2, $3)
		ON CONFLICT (token) DO NOTHING`,
		token, userID, expiresAt)
	return err
}

// FindVerificationToken mengembalikan user ID pemilik token, kalau
// token valid dan belum expired.
func (r *Repo) FindVerificationToken(ctx context.Context, token string) (uuid.UUID, error) {
	var userID uuid.UUID
	err := r.pool.QueryRow(ctx, `
		SELECT user_id FROM email_verifications
		WHERE token = $1 AND expires_at > now()`, token).Scan(&userID)
	if errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, ErrNotFound
	}
	return userID, err
}

func (r *Repo) DeleteVerificationToken(ctx context.Context, token string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM email_verifications WHERE token = $1`, token)
	return err
}

func (r *Repo) MarkUserVerified(ctx context.Context, userID uuid.UUID) error {
	_, err := r.pool.Exec(ctx, `UPDATE users SET is_verified = true WHERE id = $1`, userID)
	return err
}
