package handler

import (
	"errors"
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

// verifyEmail dibuka lewat link di email (browser), bukan dari dalam
// app — jadi balasnya HTML statis sederhana, bukan JSON.
func (h *authHandler) verifyEmail(w http.ResponseWriter, r *http.Request) {
	token := r.URL.Query().Get("token")
	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	if token == "" {
		w.WriteHeader(http.StatusBadRequest)
		writeVerifyPage(w, false, "Link verifikasi tidak lengkap.")
		return
	}

	_, err := h.auth.VerifyEmail(r.Context(), token)
	if errors.Is(err, service.ErrInvalidVerifyToken) {
		w.WriteHeader(http.StatusBadRequest)
		writeVerifyPage(w, false, "Link verifikasi sudah tidak berlaku. Minta link baru dari aplikasi.")
		return
	}
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		writeVerifyPage(w, false, "Terjadi kesalahan, coba lagi nanti.")
		return
	}
	writeVerifyPage(w, true, "Email kamu berhasil diverifikasi. Kembali ke aplikasi AAC untuk lanjut.")
}

func writeVerifyPage(w http.ResponseWriter, ok bool, message string) {
	color := "#dc2626"
	title := "Verifikasi Gagal"
	if ok {
		color = "#16a34a"
		title = "Email Terverifikasi"
	}
	w.Write([]byte(`<!DOCTYPE html>
<html><body style="font-family:Helvetica,Arial,sans-serif;background:#f1f5f9;padding:40px 16px;margin:0;display:flex;justify-content:center">
  <div style="max-width:420px;text-align:center;background:#fff;border-radius:16px;padding:40px;box-shadow:0 1px 3px rgba(0,0,0,0.1)">
    <h1 style="color:` + color + `;font-size:20px;margin:0 0 12px">` + title + `</h1>
    <p style="color:#334155;font-size:14px;line-height:1.5">` + message + `</p>
  </div>
</body></html>`)) //nolint:errcheck
}

// resendVerification dipanggil dari dalam app (butuh login) buat
// minta email verifikasi baru dikirim ulang.
func (h *authHandler) resendVerification(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	err := h.auth.ResendVerification(r.Context(), uid)
	if errors.Is(err, service.ErrAlreadyVerified) {
		httpx.Error(w, http.StatusConflict, "already_verified", "email already verified")
		return
	}
	if err != nil {
		writeServiceError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
