package handler

import (
	"errors"
	"log"
	"net/http"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
	"github.com/syarifhidayatullah/aac-app/backend/internal/service"
)

// writeServiceError memetakan error domain ke status HTTP.
func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrInvalidInput):
		httpx.Error(w, http.StatusBadRequest, "invalid_input", err.Error())
	case errors.Is(err, service.ErrInvalidCredentials):
		httpx.Error(w, http.StatusUnauthorized, "invalid_credentials", "invalid credentials")
	case errors.Is(err, service.ErrGoogleDisabled):
		httpx.Error(w, http.StatusNotImplemented, "google_disabled", "google login is not configured on this server")
	case errors.Is(err, repository.ErrEmailTaken):
		httpx.Error(w, http.StatusConflict, "email_taken", "email already registered")
	case errors.Is(err, repository.ErrNotFound):
		httpx.Error(w, http.StatusNotFound, "not_found", "resource not found")
	case errors.Is(err, repository.ErrForbidden):
		httpx.Error(w, http.StatusForbidden, "forbidden", "you do not own this resource")
	case errors.Is(err, repository.ErrConflict):
		httpx.Error(w, http.StatusConflict, "conflict", err.Error())
	default:
		log.Printf("internal error: %v", err)
		httpx.Error(w, http.StatusInternalServerError, "internal", "internal server error")
	}
}
