package config

import (
	"context"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
)

// FirebaseApp başlatılmış Firebase uygulamasını tutar
var FirebaseApp *firebase.App

// InitFirebase Firebase Admin SDK'yı başlatır.
// Render.com gibi ortamlarda FIREBASE_CREDENTIALS_JSON ortam değişkeninden okur.
// Lokal geliştirmede serviceAccountKey.json dosyasını kullanır.
func InitFirebase() error {
	ctx := context.Background()

	var opt option.ClientOption

	// 1. Önce ortam değişkenini kontrol et (Render.com için)
	credJSON := os.Getenv("FIREBASE_CREDENTIALS_JSON")
	if credJSON != "" {
		log.Println("Firebase: FIREBASE_CREDENTIALS_JSON ortam değişkeninden kimlik doğrulanıyor...")
		opt = option.WithCredentialsJSON([]byte(credJSON))
	} else {
		// 2. Ortam değişkeni yoksa lokal dosyayı kullan (geliştirme için)
		log.Println("Firebase: serviceAccountKey.json dosyasından kimlik doğrulanıyor...")
		opt = option.WithCredentialsFile("serviceAccountKey.json")
	}

	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		return err
	}

	FirebaseApp = app
	log.Println("Firebase Admin SDK başarıyla başlatıldı.")
	return nil
}
