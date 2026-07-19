package model

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID          uuid.UUID `json:"id"`
	Email       string    `json:"email"`
	DisplayName string    `json:"display_name"`
	AvatarURL   *string   `json:"avatar_url,omitempty"`
	IsVerified  bool      `json:"is_verified"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	PasswordHash *string `json:"-"`
	GoogleID     *string `json:"-"`
}

type Profile struct {
	ID        uuid.UUID       `json:"id"`
	UserID    uuid.UUID       `json:"user_id"`
	Name      string          `json:"name"`
	Settings  json.RawMessage `json:"settings"`
	CreatedAt time.Time       `json:"created_at"`
	UpdatedAt time.Time       `json:"updated_at"`
	DeletedAt *time.Time      `json:"deleted_at,omitempty"`
}

type Board struct {
	ID        uuid.UUID  `json:"id"`
	ProfileID uuid.UUID  `json:"profile_id"`
	Name      string     `json:"name"`
	GridRows  int        `json:"grid_rows"`
	GridCols  int        `json:"grid_cols"`
	IsRoot    bool       `json:"is_root"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty"`
	Cells     []Cell     `json:"cells,omitempty"`
}

const (
	CellActionSpeak    = "speak"
	CellActionNavigate = "navigate"
)

type Cell struct {
	ID              uuid.UUID  `json:"id"`
	BoardID         uuid.UUID  `json:"board_id"`
	RowIndex        int        `json:"row_index"`
	ColIndex        int        `json:"col_index"`
	Label           string     `json:"label"`
	SpeakText       *string    `json:"speak_text,omitempty"`
	SymbolID        *uuid.UUID `json:"symbol_id,omitempty"`
	BackgroundColor *string    `json:"background_color,omitempty"`
	ActionType      string     `json:"action_type"`
	TargetBoardID   *uuid.UUID `json:"target_board_id,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
	DeletedAt       *time.Time `json:"deleted_at,omitempty"`
}

// BoardShare adalah kode singkat untuk berbagi papan antar akun.
// Impor menyalin papan, jadi share aman dihapus/kedaluwarsa kapan pun.
type BoardShare struct {
	Code      string    `json:"code"`
	BoardID   uuid.UUID `json:"board_id"`
	CreatedBy uuid.UUID `json:"-"`
	CreatedAt time.Time `json:"created_at"`
	ExpiresAt time.Time `json:"expires_at"`
}

type Symbol struct {
	ID          uuid.UUID  `json:"id"`
	OwnerUserID *uuid.UUID `json:"owner_user_id,omitempty"`
	Pack        string     `json:"pack"`
	PackRef     *string    `json:"pack_ref,omitempty"`
	Label       string     `json:"label"`
	Category    *string    `json:"category,omitempty"`
	Keywords    []string   `json:"keywords"`
	ImageURL    *string    `json:"image_url,omitempty"`
	License     *string    `json:"license,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
	DeletedAt   *time.Time `json:"deleted_at,omitempty"`
}
