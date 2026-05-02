package main

import (
	"log"

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

	// Sunucuyu 3000 portunda başlat
	log.Println("Sunucu 3000 portunda başlatılıyor...")
	if err := app.Listen(":3000"); err != nil {
		log.Fatalf("Sunucu başlatılırken hata oluştu: %v", err)
	}
}
