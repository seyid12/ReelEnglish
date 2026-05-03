package models

// Quiz temsil eder
type Quiz struct {
	ID                   string   `json:"id" firestore:"id"`
	VideoID              string   `json:"video_id" firestore:"video_id"`
	Question             string   `json:"question" firestore:"question"`
	Options              []string `json:"options" firestore:"options"`
	CorrectAnswerIndex   int      `json:"correct_answer_index" firestore:"correct_answer_index"`
	Explanation          string   `json:"explanation" firestore:"explanation"`
	DifficultyLevel      string   `json:"difficulty_level" firestore:"difficulty_level"`
	GrammarTopic         string   `json:"grammar_topic" firestore:"grammar_topic"`
}

// QuizSubmission quiz cevabını temsil eder
type QuizSubmission struct {
	QuizID                string `json:"quiz_id"`
	SelectedAnswerIndex   int    `json:"selected_answer_index"`
	UserID                string `json:"user_id"`
	IsCorrect             bool   `json:"is_correct"`
	XPEarned              int    `json:"xp_earned"`
}
