package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/syarifhidayatullah/aac-app/backend/internal/config"
	"github.com/syarifhidayatullah/aac-app/backend/internal/db"
	"github.com/syarifhidayatullah/aac-app/backend/internal/handler"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
	"github.com/syarifhidayatullah/aac-app/backend/internal/service"
)

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	log.Println("running database migrations...")
	if err := db.Migrate(cfg.DatabaseURL); err != nil {
		return err
	}
	log.Println("database schema up to date")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	pool, err := db.Connect(ctx, cfg.DatabaseURL, cfg.DBMaxConns)
	if err != nil {
		return err
	}
	defer pool.Close()

	repo := repository.New(pool)

	var google service.GoogleVerifier
	if len(cfg.GoogleClientIDs) > 0 {
		google = service.NewGoogleVerifier(cfg.GoogleClientIDs)
	} else {
		log.Println("GOOGLE_CLIENT_IDS not set; google login disabled")
	}
	auth := service.NewAuth(repo, cfg.JWTSecret, cfg.TokenTTL, google)

	srv := &http.Server{
		Addr: ":" + cfg.Port,
		Handler: handler.NewRouter(handler.Deps{
			Repo:           repo,
			Auth:           auth,
			JWTSecret:      cfg.JWTSecret,
			UploadDir:      cfg.UploadDir,
			AllowedOrigins: cfg.AllowedOrigins,
		}),
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	errCh := make(chan error, 1)
	go func() {
		log.Printf("server listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
	}()

	select {
	case err := <-errCh:
		return err
	case <-ctx.Done():
		log.Println("shutting down...")
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		return srv.Shutdown(shutdownCtx)
	}
}
