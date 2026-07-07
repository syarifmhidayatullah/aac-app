package handler

import (
	"net/http"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
	"github.com/syarifhidayatullah/aac-app/backend/internal/middleware"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
	"github.com/syarifhidayatullah/aac-app/backend/internal/service"
)

type authHandler struct {
	auth *service.Auth
	repo *repository.Repo
}

func (h *authHandler) register(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email       string `json:"email"`
		Password    string `json:"password"`
		DisplayName string `json:"display_name"`
	}
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	res, err := h.auth.Register(r.Context(), req.Email, req.Password, req.DisplayName)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusCreated, res)
}

func (h *authHandler) login(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	res, err := h.auth.Login(r.Context(), req.Email, req.Password)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, res)
}

func (h *authHandler) google(w http.ResponseWriter, r *http.Request) {
	var req struct {
		IDToken string `json:"id_token"`
	}
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	if req.IDToken == "" {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "id_token is required")
		return
	}
	res, err := h.auth.LoginWithGoogle(r.Context(), req.IDToken)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, res)
}

func (h *authHandler) me(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	user, err := h.repo.GetUserByID(r.Context(), uid)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, user)
}
