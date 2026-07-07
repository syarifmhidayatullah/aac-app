package handler

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
	"github.com/syarifhidayatullah/aac-app/backend/internal/middleware"
	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
	"github.com/syarifhidayatullah/aac-app/backend/internal/service"
)

type profileHandler struct {
	repo *repository.Repo
}

type profileInput struct {
	Name     string          `json:"name"`
	Settings json.RawMessage `json:"settings"`
}

func (in *profileInput) validate() (string, bool) {
	in.Name = strings.TrimSpace(in.Name)
	if in.Name == "" {
		return "name is required", false
	}
	return "", true
}

func pathID(r *http.Request, param string) (uuid.UUID, bool) {
	id, err := uuid.Parse(chi.URLParam(r, param))
	return id, err == nil
}

func (h *profileHandler) list(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	profiles, err := h.repo.ListProfiles(r.Context(), uid)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, profiles)
}

// create membuat profile baru sekaligus papan komunikasi awal
// Bahasa Indonesia sebagai papan root-nya.
func (h *profileHandler) create(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	var req profileInput
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	if msg, ok := req.validate(); !ok {
		httpx.Error(w, http.StatusBadRequest, "invalid_input", msg)
		return
	}

	profile := &model.Profile{UserID: uid, Name: req.Name, Settings: req.Settings}
	profile.ID = uuid.New()
	created, err := h.repo.CreateProfile(r.Context(), profile, service.DefaultBoard(profile.ID))
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusCreated, created)
}

func (h *profileHandler) update(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	id, ok := pathID(r, "profileID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid profile id")
		return
	}
	var req profileInput
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	if msg, ok := req.validate(); !ok {
		httpx.Error(w, http.StatusBadRequest, "invalid_input", msg)
		return
	}
	updated, err := h.repo.UpdateProfile(r.Context(), uid, id, req.Name, req.Settings)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, updated)
}

func (h *profileHandler) delete(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	id, ok := pathID(r, "profileID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid profile id")
		return
	}
	if err := h.repo.SoftDeleteProfile(r.Context(), uid, id); err != nil {
		writeServiceError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
