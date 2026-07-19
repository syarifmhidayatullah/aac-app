package service

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"net/mail"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/syarifhidayatullah/aac-app/backend/internal/email"
	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrInvalidInput       = errors.New("invalid input")
	ErrGoogleDisabled     = errors.New("google login is not configured")
	ErrInvalidVerifyToken = errors.New("invalid or expired verification token")
	ErrAlreadyVerified    = errors.New("email already verified")
)

const verificationTokenTTL = 24 * time.Hour

type Auth struct {
	repo       *repository.Repo
	secret     []byte
	ttl        time.Duration
	google     GoogleVerifier // nil = login Google dinonaktifkan
	mailer     *email.Mailer  // nil = pengiriman email verifikasi di-skip
	appBaseURL string
}

func NewAuth(repo *repository.Repo, secret []byte, ttl time.Duration, google GoogleVerifier, mailer *email.Mailer, appBaseURL string) *Auth {
	return &Auth{repo: repo, secret: secret, ttl: ttl, google: google, mailer: mailer, appBaseURL: appBaseURL}
}

type AuthResult struct {
	Token string      `json:"token"`
	User  *model.User `json:"user"`
}

func (a *Auth) Register(ctx context.Context, email, password, displayName string) (*AuthResult, error) {
	email = normalizeEmail(email)
	if _, err := mail.ParseAddress(email); err != nil {
		return nil, fmt.Errorf("%w: invalid email address", ErrInvalidInput)
	}
	if len(password) < 8 {
		return nil, fmt.Errorf("%w: password must be at least 8 characters", ErrInvalidInput)
	}
	displayName = strings.TrimSpace(displayName)
	if displayName == "" {
		displayName, _, _ = strings.Cut(email, "@")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}
	hashStr := string(hash)

	user, err := a.repo.CreateUser(ctx, repository.NewUser{
		Email:        email,
		DisplayName:  displayName,
		PasswordHash: &hashStr,
		IsVerified:   false,
	})
	if err != nil {
		return nil, err
	}

	// Best-effort: gagal kirim email verifikasi tidak menggagalkan
	// registrasi (user masih bisa pakai app, cuma fitur akun ter-gate
	// oleh RequireVerified sampai dia verifikasi).
	if err := a.SendVerificationEmail(ctx, user); err != nil {
		slog.Warn("send verification email failed", "user_id", user.ID, "error", err)
	}

	return a.result(user)
}

// SendVerificationEmail membuat token verifikasi baru (berlaku 24 jam)
// dan mengirim link-nya ke email user. Dipakai saat register maupun
// resend.
func (a *Auth) SendVerificationEmail(ctx context.Context, user *model.User) error {
	if a.mailer == nil {
		slog.Warn("RESEND_API_KEY not set, skipping verification email", "user_id", user.ID)
		return nil
	}
	tok, err := generateRawToken()
	if err != nil {
		return err
	}
	if err := a.repo.SaveVerificationToken(ctx, user.ID, tok, time.Now().Add(verificationTokenTTL)); err != nil {
		return fmt.Errorf("save verification token: %w", err)
	}
	verifyURL := a.appBaseURL + "/api/v1/auth/verify-email?token=" + tok
	return a.mailer.SendVerification(user.Email, user.DisplayName, verifyURL)
}

// ResendVerification mengirim ulang email verifikasi untuk user yang
// sudah login tapi belum verifikasi.
func (a *Auth) ResendVerification(ctx context.Context, userID uuid.UUID) error {
	user, err := a.repo.GetUserByID(ctx, userID)
	if err != nil {
		return err
	}
	if user.IsVerified {
		return ErrAlreadyVerified
	}
	return a.SendVerificationEmail(ctx, user)
}

// VerifyEmail menandai user pemilik token sebagai terverifikasi.
// Token cuma bisa dipakai sekali (dihapus setelah berhasil).
func (a *Auth) VerifyEmail(ctx context.Context, token string) (*model.User, error) {
	userID, err := a.repo.FindVerificationToken(ctx, token)
	if errors.Is(err, repository.ErrNotFound) {
		return nil, ErrInvalidVerifyToken
	}
	if err != nil {
		return nil, err
	}
	if err := a.repo.MarkUserVerified(ctx, userID); err != nil {
		return nil, fmt.Errorf("mark verified: %w", err)
	}
	_ = a.repo.DeleteVerificationToken(ctx, token)
	return a.repo.GetUserByID(ctx, userID)
}

func generateRawToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

func (a *Auth) Login(ctx context.Context, email, password string) (*AuthResult, error) {
	user, err := a.repo.GetUserByEmail(ctx, normalizeEmail(email))
	if errors.Is(err, repository.ErrNotFound) {
		return nil, ErrInvalidCredentials
	}
	if err != nil {
		return nil, err
	}
	if user.PasswordHash == nil {
		// Akun Google-only: tidak punya password untuk dicocokkan.
		return nil, ErrInvalidCredentials
	}
	if bcrypt.CompareHashAndPassword([]byte(*user.PasswordHash), []byte(password)) != nil {
		return nil, ErrInvalidCredentials
	}
	return a.result(user)
}

// LoginWithGoogle memverifikasi ID token dari Google Sign-In di klien,
// lalu: pakai akun tertaut kalau ada; tautkan ke akun ber-email sama
// (hanya jika email terverifikasi); atau buat akun baru.
func (a *Auth) LoginWithGoogle(ctx context.Context, idToken string) (*AuthResult, error) {
	if a.google == nil {
		return nil, ErrGoogleDisabled
	}
	claims, err := a.google.Verify(ctx, idToken)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidCredentials, err)
	}

	user, err := a.repo.GetUserByGoogleID(ctx, claims.Subject)
	if err == nil {
		return a.result(user)
	}
	if !errors.Is(err, repository.ErrNotFound) {
		return nil, err
	}

	var picture *string
	if claims.Picture != "" {
		picture = &claims.Picture
	}

	if claims.Email != "" && claims.EmailVerified {
		existing, err := a.repo.GetUserByEmail(ctx, claims.Email)
		switch {
		case err == nil:
			linked, err := a.repo.LinkGoogleAccount(ctx, existing.ID, claims.Subject, picture)
			if err != nil {
				return nil, err
			}
			return a.result(linked)
		case !errors.Is(err, repository.ErrNotFound):
			return nil, err
		}
	}

	if claims.Email == "" || !claims.EmailVerified {
		return nil, fmt.Errorf("%w: google account has no verified email", ErrInvalidCredentials)
	}

	displayName := strings.TrimSpace(claims.Name)
	if displayName == "" {
		displayName, _, _ = strings.Cut(claims.Email, "@")
	}
	user, err = a.repo.CreateUser(ctx, repository.NewUser{
		Email:       claims.Email,
		DisplayName: displayName,
		GoogleID:    &claims.Subject,
		AvatarURL:   picture,
		IsVerified:  true, // Google sudah verifikasi email-nya
	})
	if err != nil {
		return nil, err
	}
	return a.result(user)
}

func (a *Auth) result(user *model.User) (*AuthResult, error) {
	token, err := a.issueToken(user.ID)
	if err != nil {
		return nil, err
	}
	return &AuthResult{Token: token, User: user}, nil
}

func (a *Auth) issueToken(userID uuid.UUID) (string, error) {
	now := time.Now()
	claims := jwt.RegisteredClaims{
		Subject:   userID.String(),
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(now.Add(a.ttl)),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(a.secret)
}

func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}
