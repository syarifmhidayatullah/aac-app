package db_test

import (
	"testing"

	embeddedpostgres "github.com/fergusstrange/embedded-postgres"

	"github.com/syarifhidayatullah/aac-app/backend/internal/db"
)

// TestMigrate menjalankan seluruh migrasi terhadap Postgres 16 sungguhan
// (embedded, diunduh otomatis) — memastikan DDL valid sebelum deploy.
func TestMigrate(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping: downloads embedded postgres")
	}

	pg := embeddedpostgres.NewDatabase(embeddedpostgres.DefaultConfig().
		Version(embeddedpostgres.V16).
		Port(54329).
		RuntimePath(t.TempDir()))
	if err := pg.Start(); err != nil {
		t.Fatalf("start embedded postgres: %v", err)
	}
	t.Cleanup(func() {
		if err := pg.Stop(); err != nil {
			t.Errorf("stop embedded postgres: %v", err)
		}
	})

	url := "postgres://postgres:postgres@localhost:54329/postgres?sslmode=disable"

	if err := db.Migrate(url); err != nil {
		t.Fatalf("migrate up: %v", err)
	}

	// Dipanggil setiap startup server, jadi harus no-op saat sudah up to date.
	if err := db.Migrate(url); err != nil {
		t.Fatalf("migrate rerun (should be no-op): %v", err)
	}
}
