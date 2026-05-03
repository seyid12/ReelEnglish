package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"

	"reelenglish/internal/config"
	"reelenglish/internal/handlers"
	"reelenglish/internal/middleware"
)

func main() {
	// Firebase Admin SDK'yı başlat
	if err := config.InitFirebase(); err != nil {
		log.Fatalf("Firebase başlatılamadı: %v", err)
	}

	// Yeni bir Fiber uygulaması oluştur
	app := fiber.New()

	// Route'ları ayarla
	// GET /feed - Herkese açık (Middleware yok)
	app.Get("/feed", handlers.GetFeedHandler)
	
	// POST /sync-progress - Herkese açık (Middleware yok)
	app.Post("/sync-progress", handlers.SyncProgressHandler)
	
	// GET /api/quizzes - Herkese açık, quiz soruları getir
	app.Get("/api/quizzes", handlers.GetQuizzesHandler)
	
	// POST /api/quiz-submit - Herkese açık, quiz cevabını doğrula
	app.Post("/api/quiz-submit", handlers.SubmitQuizHandler)
	
	// GET /api/quiz-stats - Kullanıcı istatistikleri
	app.Get("/api/quiz-stats", handlers.GetQuizStatsHandler)
	
	// POST /api/videos - Sadece kimlik doğrulanmış (Admin) kullanıcılar (Middleware var)
	app.Post("/api/videos", middleware.FirebaseAuth(), handlers.AddVideoHandler)

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
