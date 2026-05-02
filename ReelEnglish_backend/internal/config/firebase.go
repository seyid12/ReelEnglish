package config

import (
	"context"
	"log"

	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
)

// FirebaseApp başlatılmış Firebase uygulamasını tutar
var FirebaseApp *firebase.App

// InitFirebase Firebase Admin SDK'yı başlatır
func InitFirebase() error {
	// Arka plan context'i
	ctx := context.Background()

	// serviceAccountKey.json dosyasını kullanarak kimlik doğrulaması yap
	opt := option.WithCredentialsFile("serviceAccountKey.json")
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		return err
	}

	FirebaseApp = app
	log.Println("Firebase Admin SDK başarıyla başlatıldı.")
	return nil
}
