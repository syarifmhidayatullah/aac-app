package handler

import (
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
	"github.com/syarifhidayatullah/aac-app/backend/internal/middleware"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
)

type shareHandler struct {
	repo *repository.Repo
}

// create membuat kode berbagi untuk papan milik pemanggil.
func (h *shareHandler) create(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	boardID, ok := pathID(r, "boardID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid board id")
		return
	}
	share, err := h.repo.CreateBoardShare(r.Context(), uid, boardID)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusCreated, share)
}

// importBoard menyalin papan dari kode berbagi ke salah satu profile
// pemanggil.
func (h *shareHandler) importBoard(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())

	var req struct {
		Code      string    `json:"code"`
		ProfileID uuid.UUID `json:"profile_id"`
	}
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	req.Code = strings.ToUpper(strings.TrimSpace(req.Code))
	if req.Code == "" || req.ProfileID == uuid.Nil {
		httpx.Error(w, http.StatusBadRequest, "invalid_input", "code and profile_id are required")
		return
	}

	board, err := h.repo.ImportSharedBoard(r.Context(), uid, req.Code, req.ProfileID)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusCreated, board)
}
