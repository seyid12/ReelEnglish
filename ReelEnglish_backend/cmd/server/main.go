package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"

	"reelenglish/internal/config"
	"reelenglish/internal/handlers"
)

func main() {
	// Firebase Admin SDK'yı başlat
	if err := config.InitFirebase(); err != nil {
		log.Fatalf("Firebase başlatılamadı: %v", err)
	}

	// Yeni bir Fiber uygulaması oluştur
	app := fiber.New()

	// Route'ları ayarla
	app.Get("/feed", handlers.GetFeedHandler)
	app.Post("/sync-progress", handlers.SyncProgressHandler)

	// PORT ortam değişkenini oku (Render.com bunu otomatik sağlar)
	// Lokal geliştirme için varsayılan olarak 3000 kullan
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	log.Printf("Sunucu :%s portunda başlatılıyor...", port)
	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Sunucu başlatılırken hata oluştu: %v", err)
	}
}
