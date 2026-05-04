package repository

import (
	"context"
	"fmt"

	"reelenglish/internal/config"
	"reelenglish/internal/models"
)

// CreateUser Firestore'a yeni kullanıcı belgesi ekler (role: "user")
func CreateUser(ctx context.Context, uid string, email string) error {
	if config.FirebaseApp == nil {
		return fmt.Errorf("firebase app başlatılmamış")
	}

	client, err := config.FirebaseApp.Firestore(ctx)
	if err != nil {
		return fmt.Errorf("firestore client alınamadı: %v", err)
	}
	defer client.Close()

	_, err = client.Collection("users").Doc(uid).Set(ctx, map[string]interface{}{
		"uid":   uid,
		"email": email,
		"role":  "user",
	})
	if err != nil {
		return fmt.Errorf("kullanıcı oluşturulurken hata: %v", err)
	}
	return nil
}

// GetUser Firestore'dan kullanıcı belgesini getirir
func GetUser(ctx context.Context, uid string) (*models.User, error) {
	if config.FirebaseApp == nil {
		return nil, fmt.Errorf("firebase app başlatılmamış")
	}

	client, err := config.FirebaseApp.Firestore(ctx)
	if err != nil {
		return nil, fmt.Errorf("firestore client alınamadı: %v", err)
	}
	defer client.Close()

	doc, err := client.Collection("users").Doc(uid).Get(ctx)
	if err != nil {
		return nil, fmt.Errorf("kullanıcı bulunamadı: %v", err)
	}

	var user models.User
	if err := doc.DataTo(&user); err != nil {
		return nil, fmt.Errorf("kullanıcı verisi okunamadı: %v", err)
	}
	user.UID = doc.Ref.ID
	return &user, nil
}

// DeleteUser Firestore'dan kullanıcı belgesini siler
func DeleteUser(ctx context.Context, uid string) error {
	if config.FirebaseApp == nil {
		return fmt.Errorf("firebase app başlatılmamış")
	}

	client, err := config.FirebaseApp.Firestore(ctx)
	if err != nil {
		return fmt.Errorf("firestore client alınamadı: %v", err)
	}
	defer client.Close()

	_, err = client.Collection("users").Doc(uid).Delete(ctx)
	if err != nil {
		return fmt.Errorf("kullanıcı silinirken hata: %v", err)
	}
	return nil
}
