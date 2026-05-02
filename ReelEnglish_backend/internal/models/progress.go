package models

// SyncRequest represents the data sent from the client to sync progress
type SyncRequest struct {
	UserID           string   `json:"user_id"`
	FocusScore       float64  `json:"focus_score"`      // NPU'dan gelen 0-100 arası anlık skor
	SessionDuration  int      `json:"session_duration"` // saniye cinsinden
	LearnedWords     []string `json:"learned_words"`
	StruggledGrammar []string `json:"struggled_grammar"`
}
