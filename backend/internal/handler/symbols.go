package handler

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
	"github.com/syarifhidayatullah/aac-app/backend/internal/middleware"
	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
)

type symbolHandler struct {
	repo *repository.Repo
}

func (h *symbolHandler) list(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	q := r.URL.Query()

	limit, _ := strconv.Atoi(q.Get("limit"))
	if limit <= 0 {
		limit = 50
	}
	if limit > 200 {
		limit = 200
	}
	offset, _ := strconv.Atoi(q.Get("offset"))
	if offset < 0 {
		offset = 0
	}

	symbols, err := h.repo.SearchSymbols(r.Context(), uid,
		strings.TrimSpace(q.Get("q")), strings.TrimSpace(q.Get("pack")), limit, offset)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, symbols)
}

// create menyimpan simbol custom milik user (gambarnya di-upload dulu
// lewat POST /uploads, lalu image_url-nya dipakai di sini).
func (h *symbolHandler) create(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	var req struct {
		Label    string   `json:"label"`
		Keywords []string `json:"keywords"`
		ImageURL string   `json:"image_url"`
	}
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	req.Label = strings.TrimSpace(req.Label)
	if req.Label == "" {
		httpx.Error(w, http.StatusBadRequest, "invalid_input", "label is required")
		return
	}
	if req.ImageURL == "" {
		httpx.Error(w, http.StatusBadRequest, "invalid_input", "image_url is required")
		return
	}

	keywords := make([]string, 0, len(req.Keywords))
	for _, kw := range req.Keywords {
		if kw = strings.ToLower(strings.TrimSpace(kw)); kw != "" {
			keywords = append(keywords, kw)
		}
	}

	symbol := &model.Symbol{
		OwnerUserID: &uid,
		Pack:        "custom",
		Label:       req.Label,
		Keywords:    keywords,
		ImageURL:    &req.ImageURL,
	}
	created, err := h.repo.CreateSymbol(r.Context(), symbol)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusCreated, created)
}

func (h *symbolHandler) delete(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	id, ok := pathID(r, "symbolID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid symbol id")
		return
	}
	if err := h.repo.SoftDeleteSymbol(r.Context(), uid, id); err != nil {
		writeServiceError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
