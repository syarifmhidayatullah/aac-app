package config

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"time"
)

type Config struct {
	Port            string
	DatabaseURL     string
	JWTSecret       []byte
	TokenTTL        time.Duration
	GoogleClientIDs []string
	UploadDir       string
	AllowedOrigins  []string
}

// Load membaca konfigurasi dari env (plus ./.env kalau ada, tanpa
// menimpa env yang sudah di-set) dan gagal cepat kalau ada yang wajib
// tapi kosong.
func Load() (*Config, error) {
	loadDotEnv()

	cfg := &Config{
		Port:        getenv("PORT", "8080"),
		DatabaseURL: os.Getenv("DATABASE_URL"),
		UploadDir:   getenv("UPLOAD_DIR", "./uploads"),
	}
	if cfg.DatabaseURL == "" {
		return nil, errors.New("DATABASE_URL is required")
	}

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return nil, errors.New("JWT_SECRET is required")
	}
	cfg.JWTSecret = []byte(secret)

	ttl, err := time.ParseDuration(getenv("TOKEN_TTL", "720h"))
	if err != nil {
		return nil, fmt.Errorf("invalid TOKEN_TTL: %w", err)
	}
	cfg.TokenTTL = ttl

	cfg.GoogleClientIDs = splitCSV(os.Getenv("GOOGLE_CLIENT_IDS"))
	cfg.AllowedOrigins = splitCSV(getenv("ALLOWED_ORIGINS", "*"))
	return cfg, nil
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func splitCSV(s string) []string {
	var out []string
	for _, p := range strings.Split(s, ",") {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}

func loadDotEnv() {
	data, err := os.ReadFile(".env")
	if err != nil {
		return
	}
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, val, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		key = strings.TrimSpace(key)
		if os.Getenv(key) == "" {
			os.Setenv(key, strings.TrimSpace(val))
		}
	}
}
