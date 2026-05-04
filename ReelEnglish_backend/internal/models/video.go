package models

// Word yapay zekanın videodan çıkardığı kelimeyi temsil eder
type Word struct {
	Word            string `json:"word" firestore:"word"`
	Translation     string `json:"translation" firestore:"translation"`
	ExampleSentence string `json:"example_sentence" firestore:"example_sentence"`
}

// Video uygulama içindeki video modelini temsil eder
type Video struct {
	ID          string   `json:"id" firestore:"id,omitempty"`
	URL         string   `json:"url" firestore:"url"`
	Difficulty  int      `json:"difficulty" firestore:"difficulty"`     // 1-10 arası
	GrammarTags []string `json:"grammar_tags" firestore:"grammar_tags"` // Örn: ["Present Continuous"]
	AvatarType  string   `json:"avatar_type" firestore:"avatar_type"`   // '3D_Anim' veya '2D_Human'
	SourceType  string   `json:"source_type" firestore:"source_type"`   // 'youtube' veya 'ftp'
	Words       []Word   `json:"words" firestore:"words,omitempty"`     // AI'ın çıkardığı kelimeler
}
