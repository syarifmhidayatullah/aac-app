package handler

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/syarifhidayatullah/aac-app/backend/internal/httpx"
	"github.com/syarifhidayatullah/aac-app/backend/internal/middleware"
	"github.com/syarifhidayatullah/aac-app/backend/internal/model"
	"github.com/syarifhidayatullah/aac-app/backend/internal/repository"
)

type boardHandler struct {
	repo *repository.Repo
}

type cellInput struct {
	ID              *uuid.UUID `json:"id"`
	RowIndex        int        `json:"row_index"`
	ColIndex        int        `json:"col_index"`
	Label           string     `json:"label"`
	SpeakText       *string    `json:"speak_text"`
	SymbolID        *uuid.UUID `json:"symbol_id"`
	BackgroundColor *string    `json:"background_color"`
	ActionType      string     `json:"action_type"`
	TargetBoardID   *uuid.UUID `json:"target_board_id"`
}

type boardInput struct {
	Name     string      `json:"name"`
	GridRows int         `json:"grid_rows"`
	GridCols int         `json:"grid_cols"`
	IsRoot   bool        `json:"is_root"`
	Cells    []cellInput `json:"cells"`
}

func (in *boardInput) validate() error {
	in.Name = strings.TrimSpace(in.Name)
	if in.Name == "" {
		return fmt.Errorf("name is required")
	}
	if in.GridRows == 0 {
		in.GridRows = 4
	}
	if in.GridCols == 0 {
		in.GridCols = 6
	}
	if in.GridRows < 1 || in.GridRows > 12 || in.GridCols < 1 || in.GridCols > 12 {
		return fmt.Errorf("grid size must be between 1x1 and 12x12")
	}
	return nil
}

func toCells(inputs []cellInput, gridRows, gridCols int) ([]model.Cell, error) {
	seen := map[[2]int]bool{}
	cells := make([]model.Cell, 0, len(inputs))
	for i, in := range inputs {
		in.Label = strings.TrimSpace(in.Label)
		if in.Label == "" {
			return nil, fmt.Errorf("cells[%d]: label is required", i)
		}
		if in.ActionType == "" {
			in.ActionType = model.CellActionSpeak
		}
		if in.ActionType != model.CellActionSpeak && in.ActionType != model.CellActionNavigate {
			return nil, fmt.Errorf("cells[%d]: action_type must be %q or %q", i, model.CellActionSpeak, model.CellActionNavigate)
		}
		if in.ActionType == model.CellActionNavigate && in.TargetBoardID == nil {
			return nil, fmt.Errorf("cells[%d]: navigate action requires target_board_id", i)
		}
		if in.RowIndex < 0 || in.RowIndex >= gridRows || in.ColIndex < 0 || in.ColIndex >= gridCols {
			return nil, fmt.Errorf("cells[%d]: position (%d,%d) is outside the %dx%d grid", i, in.RowIndex, in.ColIndex, gridRows, gridCols)
		}
		pos := [2]int{in.RowIndex, in.ColIndex}
		if seen[pos] {
			return nil, fmt.Errorf("cells[%d]: duplicate position (%d,%d)", i, in.RowIndex, in.ColIndex)
		}
		seen[pos] = true

		c := model.Cell{
			RowIndex:        in.RowIndex,
			ColIndex:        in.ColIndex,
			Label:           in.Label,
			SpeakText:       in.SpeakText,
			SymbolID:        in.SymbolID,
			BackgroundColor: in.BackgroundColor,
			ActionType:      in.ActionType,
			TargetBoardID:   in.TargetBoardID,
		}
		if in.ID != nil {
			c.ID = *in.ID
		}
		cells = append(cells, c)
	}
	return cells, nil
}

func (h *boardHandler) list(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	profileID, ok := pathID(r, "profileID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid profile id")
		return
	}
	boards, err := h.repo.ListBoards(r.Context(), uid, profileID)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, boards)
}

func (h *boardHandler) create(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	profileID, ok := pathID(r, "profileID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid profile id")
		return
	}
	var req boardInput
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	if err := req.validate(); err != nil {
		httpx.Error(w, http.StatusBadRequest, "invalid_input", err.Error())
		return
	}
	cells, err := toCells(req.Cells, req.GridRows, req.GridCols)
	if err != nil {
		httpx.Error(w, http.StatusBadRequest, "invalid_input", err.Error())
		return
	}

	board := &model.Board{
		ProfileID: profileID,
		Name:      req.Name,
		GridRows:  req.GridRows,
		GridCols:  req.GridCols,
		IsRoot:    req.IsRoot,
		Cells:     cells,
	}
	created, err := h.repo.CreateBoard(r.Context(), uid, board)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusCreated, created)
}

func (h *boardHandler) get(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	id, ok := pathID(r, "boardID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid board id")
		return
	}
	board, err := h.repo.GetBoard(r.Context(), uid, id)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, board)
}

func (h *boardHandler) update(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	id, ok := pathID(r, "boardID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid board id")
		return
	}
	var req boardInput
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	if err := req.validate(); err != nil {
		httpx.Error(w, http.StatusBadRequest, "invalid_input", err.Error())
		return
	}
	updated, err := h.repo.UpdateBoard(r.Context(), uid, id, req.Name, req.GridRows, req.GridCols)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, updated)
}

// replaceCells menyimpan seluruh grid sekaligus — cocok dengan pola
// "simpan" di editor papan.
func (h *boardHandler) replaceCells(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	id, ok := pathID(r, "boardID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid board id")
		return
	}

	board, err := h.repo.GetBoard(r.Context(), uid, id)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	var req struct {
		Cells []cellInput `json:"cells"`
	}
	if err := httpx.Decode(w, r, &req, 0); err != nil {
		httpx.Error(w, http.StatusBadRequest, "bad_request", err.Error())
		return
	}
	cells, err := toCells(req.Cells, board.GridRows, board.GridCols)
	if err != nil {
		httpx.Error(w, http.StatusBadRequest, "invalid_input", err.Error())
		return
	}

	saved, err := h.repo.ReplaceCells(r.Context(), uid, id, cells)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	httpx.JSON(w, http.StatusOK, map[string]any{"cells": saved})
}

func (h *boardHandler) delete(w http.ResponseWriter, r *http.Request) {
	uid, _ := middleware.UserID(r.Context())
	id, ok := pathID(r, "boardID")
	if !ok {
		httpx.Error(w, http.StatusBadRequest, "bad_request", "invalid board id")
		return
	}
	if err := h.repo.SoftDeleteBoard(r.Context(), uid, id); err != nil {
		writeServiceError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
