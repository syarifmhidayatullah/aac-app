package handler

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"

	appmw "github.com/syarifhidayatullah/aac-app/backend/internal/middleware"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
	"github.com/syarifhidayatullah/aac-app/backend/internal/service"
)

type Deps struct {
	Repo           *repository.Repo
	Auth           *service.Auth
	JWTSecret      []byte
	UploadDir      string
	AllowedOrigins []string
}

func NewRouter(d Deps) http.Handler {
	ah := &authHandler{auth: d.Auth, repo: d.Repo}
	ph := &profileHandler{repo: d.Repo}
	bh := &boardHandler{repo: d.Repo}
	sh := &symbolHandler{repo: d.Repo}
	uh := &uploadHandler{dir: d.UploadDir}
	yh := &syncHandler{repo: d.Repo}

	r := chi.NewRouter()
	r.Use(chimw.RequestID)
	r.Use(chimw.Logger)
	r.Use(chimw.Recoverer)
	r.Use(chimw.Timeout(30 * time.Second))
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins: d.AllowedOrigins,
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders: []string{"Authorization", "Content-Type"},
		MaxAge:         300,
	}))

	r.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

	// Nama file upload adalah UUID acak, jadi aman dilayani tanpa auth
	// (dibutuhkan <img src> langsung dari app).
	r.Get("/uploads/{name}", uh.serve)

	r.Route("/api/v1", func(r chi.Router) {
		r.Post("/auth/register", ah.register)
		r.Post("/auth/login", ah.login)
		r.Post("/auth/google", ah.google)

		r.Group(func(r chi.Router) {
			r.Use(appmw.Auth(d.JWTSecret))

			r.Get("/me", ah.me)

			r.Get("/profiles", ph.list)
			r.Post("/profiles", ph.create)
			r.Put("/profiles/{profileID}", ph.update)
			r.Delete("/profiles/{profileID}", ph.delete)

			r.Get("/profiles/{profileID}/boards", bh.list)
			r.Post("/profiles/{profileID}/boards", bh.create)
			r.Get("/boards/{boardID}", bh.get)
			r.Put("/boards/{boardID}", bh.update)
			r.Put("/boards/{boardID}/cells", bh.replaceCells)
			r.Delete("/boards/{boardID}", bh.delete)

			r.Get("/symbols", sh.list)
			r.Post("/symbols", sh.create)
			r.Delete("/symbols/{symbolID}", sh.delete)

			r.Post("/uploads", uh.upload)

			r.Get("/sync", yh.pull)
			r.Post("/sync", yh.push)
		})
	})

	return r
}
