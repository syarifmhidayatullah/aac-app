package config

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Port            string
	DatabaseURL     string
	DBMaxConns      int32
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

	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		return nil, errors.New("DB_HOST is required")
	}

	cfg := &Config{
		Port:        getenv("PORT", "8080"),
		DatabaseURL: buildDSN(dbHost),
		DBMaxConns:  getenvInt32("DB_MAX_CONNS", 5),
		UploadDir:   getenv("UPLOAD_DIR", "./uploads"),
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

// buildDSN merakit DATABASE_URL (format postgres:// URL, dibutuhkan
// golang-migrate) dari komponen DB_* terpisah.
func buildDSN(host string) string {
	port := getenv("DB_PORT", "5432")
	user := getenv("DB_USER", "postgres")
	password := os.Getenv("DB_PASSWORD")
	name := getenv("DB_NAME", "postgres")
	sslmode := getenv("DB_SSLMODE", "require")

	u := &url.URL{
		Scheme: "postgres",
		User:   url.UserPassword(user, password),
		Host:   net.JoinHostPort(host, port),
		Path:   "/" + name,
	}
	q := u.Query()
	q.Set("sslmode", sslmode)
	u.RawQuery = q.Encode()
	return u.String()
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func getenvInt32(key string, def int32) int32 {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	n, err := strconv.ParseInt(v, 10, 32)
	if err != nil {
		return def
	}
	return int32(n)
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
