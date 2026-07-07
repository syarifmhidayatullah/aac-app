package handler

import (
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
)

const maxUploadBytes = 10 << 20 // 10 MB

var allowedImageTypes = map[string]string{
	"image/png":  ".png",
	"image/jpeg": ".jpg",
	"image/webp": ".webp",
	"image/gif":  ".gif",
}

type uploadHandler struct {
	dir string
}

// upload menerima multipart field "file" (gambar), menyimpannya dengan
// nama UUID, dan mengembalikan URL publiknya.
func (h *uploadHandler) upload(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, maxUploadBytes)
	if err := r.ParseMultipartForm(maxUploadBytes); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid multipart form or file too large (max 10 MB)")
		return
	}
	file, _, err := r.FormFile("file")
	if err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", `multipart field "file" is required`)
		return
	}
	defer file.Close()

	// Deteksi tipe dari isi file, bukan dari ekstensi/header klien.
	head := make([]byte, 512)
	n, err := io.ReadFull(file, head)
	if err != nil && err != io.ErrUnexpectedEOF {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "could not read file")
		return
	}
	head = head[:n]
	contentType := http.DetectContentType(head)
	ext, ok := allowedImageTypes[contentType]
	if !ok {
		httpx.Error(w, http.StatusUnsupportedMediaType, "unsupported_type",
			"only PNG, JPEG, WebP, or GIF images are allowed")
		return
	}

	if err := os.MkdirAll(h.dir, 0o755); err != nil {
		writeServiceError(w, err)
		return
	}
	name := uuid.New().String() + ext
	dst, err := os.Create(filepath.Join(h.dir, name))
	if err != nil {
		writeServiceError(w, err)
		return
	}
	defer dst.Close()

	if _, err := dst.Write(head); err != nil {
		writeServiceError(w, err)
		return
	}
	if _, err := io.Copy(dst, file); err != nil {
		writeServiceError(w, err)
		return
	}

	httpx.JSON(w, http.StatusCreated, map[string]string{"url": "/uploads/" + name})
}

// serve melayani file upload. Publik tapi nama file UUID (tak bisa
// ditebak); path traversal ditolak.
func (h *uploadHandler) serve(w http.ResponseWriter, r *http.Request) {
	name := chi.URLParam(r, "name")
	if name == "" || strings.Contains(name, "..") || strings.ContainsAny(name, `/\`) {
		http.NotFound(w, r)
		return
	}
	http.ServeFile(w, r, filepath.Join(h.dir, name))
}
