package handler_test

import (
	"bytes"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	embeddedpostgres "github.com/fergusstrange/embedded-postgres"
	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/db"
	"github.com/syarifhidayatullah/aac-app/backend/internal/handler"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
	"github.com/syarifhidayatullah/aac-app/backend/internal/service"
)

// TestAPI menguji alur utama end-to-end terhadap Postgres 16 sungguhan:
// register → login → profile (papan seed) → edit grid → upload → sync.
func TestAPI(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping: downloads embedded postgres")
	}

	pg := embeddedpostgres.NewDatabase(embeddedpostgres.DefaultConfig().
		Version(embeddedpostgres.V16).
		Port(54330).
		RuntimePath(t.TempDir()))
	if err := pg.Start(); err != nil {
		t.Fatalf("start embedded postgres: %v", err)
	}
	t.Cleanup(func() {
		if err := pg.Stop(); err != nil {
			t.Errorf("stop embedded postgres: %v", err)
		}
	})

	url := "postgres://postgres:postgres@localhost:54330/postgres?sslmode=disable"
	if err := db.Migrate(url); err != nil {
		t.Fatalf("migrate: %v", err)
	}
	pool, err := db.Connect(t.Context(), url)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	t.Cleanup(pool.Close)

	repo := repository.New(pool)
	secret := []byte("test-secret")
	auth := service.NewAuth(repo, secret, time.Hour, nil)
	ts := httptest.NewServer(handler.NewRouter(handler.Deps{
		Repo:           repo,
		Auth:           auth,
		JWTSecret:      secret,
		UploadDir:      t.TempDir(),
		AllowedOrigins: []string{"*"},
	}))
	t.Cleanup(ts.Close)

	call := func(method, path, token string, body any) (int, any) {
		t.Helper()
		var reader io.Reader
		if body != nil {
			b, err := json.Marshal(body)
			if err != nil {
				t.Fatalf("marshal body: %v", err)
			}
			reader = bytes.NewReader(b)
		}
		req, err := http.NewRequest(method, ts.URL+path, reader)
		if err != nil {
			t.Fatalf("new request: %v", err)
		}
		if body != nil {
			req.Header.Set("Content-Type", "application/json")
		}
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
		res, err := ts.Client().Do(req)
		if err != nil {
			t.Fatalf("%s %s: %v", method, path, err)
		}
		defer res.Body.Close()
		raw, _ := io.ReadAll(res.Body)
		var decoded any
		if len(raw) > 0 {
			if err := json.Unmarshal(raw, &decoded); err != nil {
				t.Fatalf("%s %s: invalid JSON response %q", method, path, raw)
			}
		}
		return res.StatusCode, decoded
	}
	mustStatus := func(got int, want int, what string) {
		t.Helper()
		if got != want {
			t.Fatalf("%s: status %d, want %d", what, got, want)
		}
	}
	obj := func(v any) map[string]any {
		t.Helper()
		m, ok := v.(map[string]any)
		if !ok {
			t.Fatalf("expected JSON object, got %T", v)
		}
		return m
	}

	// --- Auth ---
	status, res := call("POST", "/api/v1/auth/register", "", map[string]any{
		"email": "budi@example.com", "password": "rahasia123", "display_name": "Budi",
	})
	mustStatus(status, http.StatusCreated, "register")
	token := obj(res)["token"].(string)

	status, _ = call("POST", "/api/v1/auth/register", "", map[string]any{
		"email": "budi@example.com", "password": "rahasia123",
	})
	mustStatus(status, http.StatusConflict, "duplicate register")

	status, _ = call("POST", "/api/v1/auth/login", "", map[string]any{
		"email": "budi@example.com", "password": "salah-total",
	})
	mustStatus(status, http.StatusUnauthorized, "login with wrong password")

	status, _ = call("POST", "/api/v1/auth/login", "", map[string]any{
		"email": "Budi@Example.com", "password": "rahasia123",
	})
	mustStatus(status, http.StatusOK, "login (case-insensitive email)")

	status, _ = call("GET", "/api/v1/me", "", nil)
	mustStatus(status, http.StatusUnauthorized, "me without token")

	status, res = call("GET", "/api/v1/me", token, nil)
	mustStatus(status, http.StatusOK, "me")
	if got := obj(res)["email"]; got != "budi@example.com" {
		t.Fatalf("me email = %v", got)
	}

	status, _ = call("POST", "/api/v1/auth/google", "", map[string]any{"id_token": "x"})
	mustStatus(status, http.StatusNotImplemented, "google login when not configured")

	// --- Profile + papan seed ---
	status, res = call("POST", "/api/v1/profiles", token, map[string]any{"name": "Ani"})
	mustStatus(status, http.StatusCreated, "create profile")
	profileID := obj(res)["id"].(string)

	status, res = call("GET", "/api/v1/profiles/"+profileID+"/boards", token, nil)
	mustStatus(status, http.StatusOK, "list boards")
	boards := res.([]any)
	if len(boards) != 1 {
		t.Fatalf("boards = %d, want 1 (seeded root)", len(boards))
	}
	root := obj(boards[0])
	if root["is_root"] != true {
		t.Fatal("seeded board is not root")
	}
	boardID := root["id"].(string)

	status, res = call("GET", "/api/v1/boards/"+boardID, token, nil)
	mustStatus(status, http.StatusOK, "get board")
	if cells := obj(res)["cells"].([]any); len(cells) != 24 {
		t.Fatalf("seeded cells = %d, want 24", len(cells))
	}

	// --- Edit grid ---
	status, _ = call("PUT", "/api/v1/boards/"+boardID+"/cells", token, map[string]any{
		"cells": []map[string]any{
			{"row_index": 0, "col_index": 0, "label": "Pergi", "action_type": "navigate"},
		},
	})
	mustStatus(status, http.StatusBadRequest, "navigate cell without target")

	status, res = call("PUT", "/api/v1/boards/"+boardID+"/cells", token, map[string]any{
		"cells": []map[string]any{
			{"row_index": 0, "col_index": 0, "label": "Halo", "speak_text": "Halo semua"},
			{"row_index": 0, "col_index": 1, "label": "Dadah"},
		},
	})
	mustStatus(status, http.StatusOK, "replace cells")
	if cells := obj(res)["cells"].([]any); len(cells) != 2 {
		t.Fatalf("cells after replace = %d, want 2", len(cells))
	}

	// --- Akses lintas akun ditolak ---
	status, res = call("POST", "/api/v1/auth/register", "", map[string]any{
		"email": "intruder@example.com", "password": "rahasia123",
	})
	mustStatus(status, http.StatusCreated, "register second user")
	intruderToken := obj(res)["token"].(string)

	status, _ = call("GET", "/api/v1/boards/"+boardID, intruderToken, nil)
	mustStatus(status, http.StatusNotFound, "other user's board must be hidden")

	// --- Upload gambar ---
	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf)
	fw, err := mw.CreateFormFile("file", "foto.png")
	if err != nil {
		t.Fatal(err)
	}
	// PNG minimal yang valid secara magic bytes.
	fw.Write([]byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 'I', 'H', 'D', 'R'})
	mw.Close()
	req, _ := http.NewRequest("POST", ts.URL+"/api/v1/uploads", &buf)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+token)
	upRes, err := ts.Client().Do(req)
	if err != nil {
		t.Fatal(err)
	}
	upBody, _ := io.ReadAll(upRes.Body)
	upRes.Body.Close()
	mustStatus(upRes.StatusCode, http.StatusCreated, "upload image")
	var up struct {
		URL string `json:"url"`
	}
	json.Unmarshal(upBody, &up)

	fileRes, err := ts.Client().Get(ts.URL + up.URL)
	if err != nil {
		t.Fatal(err)
	}
	fileRes.Body.Close()
	mustStatus(fileRes.StatusCode, http.StatusOK, "fetch uploaded image")

	// --- Sync ---
	status, res = call("GET", "/api/v1/sync", token, nil)
	mustStatus(status, http.StatusOK, "sync pull")
	pull := obj(res)
	if n := len(pull["profiles"].([]any)); n != 1 {
		t.Fatalf("sync profiles = %d, want 1", n)
	}
	// 24 sel seed jadi tombstone + 2 sel baru.
	if n := len(pull["cells"].([]any)); n != 26 {
		t.Fatalf("sync cells = %d, want 26 (incl. tombstones)", n)
	}
	if pull["server_time"] == nil {
		t.Fatal("sync pull has no server_time")
	}

	newBoardID := uuid.NewString()
	status, _ = call("POST", "/api/v1/sync", token, map[string]any{
		"boards": []map[string]any{{
			"id": newBoardID, "profile_id": profileID, "name": "Makanan",
			"grid_rows": 3, "grid_cols": 4,
		}},
	})
	mustStatus(status, http.StatusOK, "sync push new board")

	status, _ = call("GET", "/api/v1/boards/"+newBoardID, token, nil)
	mustStatus(status, http.StatusOK, "board created via sync push")

	// Push ke profile orang lain harus ditolak.
	status, _ = call("POST", "/api/v1/sync", intruderToken, map[string]any{
		"boards": []map[string]any{{
			"id": uuid.NewString(), "profile_id": profileID, "name": "Hack",
			"grid_rows": 3, "grid_cols": 4,
		}},
	})
	mustStatus(status, http.StatusForbidden, "sync push into other user's profile")
}
