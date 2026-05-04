package models

// User Firestore'daki kullanıcı belgesini temsil eder
type User struct {
	UID   string `json:"uid" firestore:"uid,omitempty"`
	Email string `json:"email" firestore:"email"`
	Role  string `json:"role" firestore:"role"` // "admin" veya "user"
}
