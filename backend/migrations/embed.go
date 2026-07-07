// Package migrations embeds the SQL migration files so the server binary
// can run them at startup (Railway deploy = migrations applied).
package migrations

import "embed"

//go:embed *.sql
var FS embed.FS
