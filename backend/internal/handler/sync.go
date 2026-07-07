package handler

import (
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
	"github.com/syarifhidayatullah/aac-app/backend/internal/middleware"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
)

const maxSyncItems = 10000

type syncHandler struct {
	repo *repository.Repo
}

// pull mengembalikan semua perubahan (termasuk tombstone) sejak `since`.
// Klien menyimpan server_time dari respons sebagai `since` berikutnya.
func (h *syncHandler) pull(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())

	var since time.Time
	if s := r.URL.Query().Get("since"); s != "" {
		t, err := time.Parse(time.RFC3339Nano, s)
		if err != nil {
			httpx.Error(w, http.StatusBadRequest, "bad_request", "since must be an RFC3339 timestamp")
			return
		}
		since = t
	}

	data, err := h.repo.SyncPull(r.Context(), uid, since)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, data)
}

func (h *syncHandler) push(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())

	var data repository.SyncData
	if err := httpx.Decode(w, r, &data, 5<<20); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}

	total := len(data.Profiles) + len(data.Boards) + len(data.Cells) + len(data.Symbols)
	if total == 0 {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "nothing to push")
		return
	}
	if total > maxSyncItems {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "too many items in one push")
		return
	}
	// ID wajib dari klien: id-lah yang membuat push idempoten.
	for _, p := range data.Profiles {
		if p.ID == uuid.Nil {
			httpx.Error(w, http.StatusBadRequest, "invalid_input", "every profile needs an id")
			return
		}
	}
	for _, b := range data.Boards {
		if b.ID == uuid.Nil || b.ProfileID == uuid.Nil {
			httpx.Error(w, http.StatusBadRequest, "invalid_input", "every board needs an id and profile_id")
			return
		}
	}
	for _, c := range data.Cells {
		if c.ID == uuid.Nil || c.BoardID == uuid.Nil {
			httpx.Error(w, http.StatusBadRequest, "invalid_input", "every cell needs an id and board_id")
			return
		}
	}
	for _, s := range data.Symbols {
		if s.ID == uuid.Nil {
			httpx.Error(w, http.StatusBadRequest, "invalid_input", "every symbol needs an id")
			return
		}
	}

	serverTime, err := h.repo.SyncPush(r.Context(), uid, &data)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, map[string]any{"server_time": serverTime})
}
