package service

import (
	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
)

// Warna latar sel mengikuti konvensi Fitzgerald key (pengelompokan
// jenis kata dengan warna) — membantu pengguna AAC menemukan kata.
const (
	colorPronoun    = "#FFE082" // kuning: kata ganti orang
	colorVerb       = "#A5D6A7" // hijau: kata kerja
	colorDescriptor = "#90CAF9" // biru: kata sifat/keterangan
	colorSocial     = "#F8BBD0" // pink: kata sosial
	colorNoun       = "#FFCC80" // oranye: kata benda
	colorNegation   = "#EF9A9A" // merah: negasi/penolakan
)

// DefaultBoard membangun papan komunikasi awal Bahasa Indonesia
// (kosakata inti) untuk profile baru.
func DefaultBoard(profileID uuid.UUID) *model.Board {
	type item struct {
		label string
		color string
	}
	grid := [][]item{
		{{"Aku", colorPronoun}, {"Kamu", colorPronoun}, {"Mau", colorVerb}, {"Tidak mau", colorNegation}, {"Suka", colorVerb}, {"Tidak suka", colorNegation}},
		{{"Makan", colorVerb}, {"Minum", colorVerb}, {"Main", colorVerb}, {"Tidur", colorVerb}, {"Toilet", colorNoun}, {"Tolong", colorSocial}},
		{{"Lagi", colorDescriptor}, {"Sudah", colorDescriptor}, {"Ya", colorSocial}, {"Tidak", colorNegation}, {"Sakit", colorDescriptor}, {"Capek", colorDescriptor}},
		{{"Senang", colorDescriptor}, {"Sedih", colorDescriptor}, {"Marah", colorDescriptor}, {"Takut", colorDescriptor}, {"Halo", colorSocial}, {"Terima kasih", colorSocial}},
	}

	board := &model.Board{
		ID:        uuid.New(),
		ProfileID: profileID,
		Name:      "Papan Utama",
		GridRows:  len(grid),
		GridCols:  len(grid[0]),
		IsRoot:    true,
	}
	for r, row := range grid {
		for c, it := range row {
			color := it.color
			board.Cells = append(board.Cells, model.Cell{
				ID:              uuid.New(),
				BoardID:         board.ID,
				RowIndex:        r,
				ColIndex:        c,
				Label:           it.label,
				BackgroundColor: &color,
				ActionType:      model.CellActionSpeak,
			})
		}
	}
	return board
}
