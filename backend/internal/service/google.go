package service

import (
	"context"
	"fmt"
	"slices"
	"strings"

	"google.golang.org/api/idtoken"
)

type GoogleClaims struct {
	Subject       string
	Email         string
	EmailVerified bool
	Name          string
	Picture       string
}

// GoogleVerifier memverifikasi ID token Google. Interface supaya bisa
// di-stub di test tanpa memanggil Google.
type GoogleVerifier interface {
	Verify(ctx context.Context, idToken string) (*GoogleClaims, error)
}

type googleVerifier struct {
	allowedAudiences []string
}

// NewGoogleVerifier menerima daftar OAuth client ID yang sah sebagai
// audience (client ID web/iOS/Android bisa berbeda-beda).
func NewGoogleVerifier(clientIDs []string) GoogleVerifier {
	return &googleVerifier{allowedAudiences: clientIDs}
}

func (g *googleVerifier) Verify(ctx context.Context, token string) (*GoogleClaims, error) {
	// Validasi tanda tangan, expiry, dan issuer; audience dicek manual
	// karena kita menerima lebih dari satu client ID.
	payload, err := idtoken.Validate(ctx, token, "")
	if err != nil {
		return nil, fmt.Errorf("validate google id token: %w", err)
	}
	if !slices.Contains(g.allowedAudiences, payload.Audience) {
		return nil, fmt.Errorf("google token audience %q is not allowed", payload.Audience)
	}

	gc := &GoogleClaims{Subject: payload.Subject}
	if v, ok := payload.Claims["email"].(string); ok {
		gc.Email = strings.ToLower(v)
	}
	switch v := payload.Claims["email_verified"].(type) {
	case bool:
		gc.EmailVerified = v
	case string:
		gc.EmailVerified = v == "true"
	}
	if v, ok := payload.Claims["name"].(string); ok {
		gc.Name = v
	}
	if v, ok := payload.Claims["picture"].(string); ok {
		gc.Picture = v
	}
	return gc, nil
}
