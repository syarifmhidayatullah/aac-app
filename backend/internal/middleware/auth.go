package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
)

type userIDKey struct{}

// Auth memvalidasi JWT Bearer dan menaruh user ID di context.
func Auth(secret []byte) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			raw, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
			if !ok || raw == "" {
				httpx.Error(w, http.StatusUnauthorized, "unauthorized", "missing bearer token")
				return
			}

			token, err := jwt.Parse(raw,
				func(t *jwt.Token) (any, error) { return secret, nil },
				jwt.WithValidMethods([]string{"HS256"}))
			if err != nil || !token.Valid {
				httpx.Error(w, http.StatusUnauthorized, "unauthorized", "invalid or expired token")
				return
			}
			sub, err := token.Claims.GetSubject()
			if err != nil {
				httpx.Error(w, http.StatusUnauthorized, "unauthorized", "invalid token subject")
				return
			}
			uid, err := uuid.Parse(sub)
			if err != nil {
				httpx.Error(w, http.StatusUnauthorized, "unauthorized", "invalid token subject")
				return
			}

			ctx := context.WithValue(r.Context(), userIDKey{}, uid)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func UserID(ctx context.Context) (uuid.UUID, bool) {
	uid, ok := ctx.Value(userIDKey{}).(uuid.UUID)
	return uid, ok
}

// RequireVerified menolak request dari user yang belum verifikasi
// email. Sengaja cek langsung ke DB tiap request (bukan baca klaim di
// JWT) karena TOKEN_TTL di app ini panjang (720h default) — kalau
// status verifikasi di-bake ke token saat login/register, token yang
// sudah beredar akan tetap bilang "belum verifikasi" walau user sudah
// klik link verifikasi di email selagi token itu masih dipakai.
func RequireVerified(repo *repository.Repo) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			uid, ok := UserID(r.Context())
			if !ok {
				httpx.Error(w, http.StatusUnauthorized, "unauthorized", "missing user")
				return
			}
			user, err := repo.GetUserByID(r.Context(), uid)
			if err != nil {
				httpx.Error(w, http.StatusUnauthorized, "unauthorized", "user not found")
				return
			}
			if !user.IsVerified {
				httpx.Error(w, http.StatusForbidden, "email_not_verified", "verify your email first")
				return
			}
			next.ServeHTTP(w, r.WithContext(r.Context()))
		})
	}
}
