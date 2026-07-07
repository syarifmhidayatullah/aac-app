package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
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
