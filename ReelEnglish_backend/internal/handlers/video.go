package handlers

import (
	"reelenglish/internal/models"
	"reelenglish/internal/repository"
	"reelenglish/internal/services"

	"github.com/gofiber/fiber/v2"
)

// AddVideoHandler POST /api/videos - Yeni video ekler
func AddVideoHandler(c *fiber.Ctx) error {
	var req struct {
		URL         string        `json:"url"`
		Difficulty  int           `json:"difficulty"`
		GrammarTags []string      `json:"grammar_tags"`
		SourceType  string        `json:"source_type"`
		Words       []models.Word `json:"words"`
		Quiz        []struct {
			Question string   `json:"question"`
			Options  []string `json:"options"`
			Answer   string   `json:"answer"`
		} `json:"quiz"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "İstek ayrıştırılamadı",
		})
	}

	// Validasyon
	if req.URL == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "URL gerekli",
		})
	}
	if req.Difficulty < 1 || req.Difficulty > 10 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Zorluk seviyesi 1-10 arasında olmalı",
		})
	}

	// Video modeli oluştur
	video := &models.Video{
		URL:         req.URL,
		Difficulty:  req.Difficulty,
		GrammarTags: req.GrammarTags,
		SourceType:  req.SourceType,
		Words:       req.Words,
	}

	// Veritabanına ekle
	if err := repository.AddVideo(c.Context(), video); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Video eklenirken hata oluştu",
			"details": err.Error(),
		})
	}

	// Quizzes ekle
	if len(req.Quiz) > 0 {
		for _, q := range req.Quiz {
			// Doğru cevabın index'ini bul
			correctIndex := 0
			for i, opt := range q.Options {
				if opt == q.Answer {
					correctIndex = i
					break
				}
			}

			quizModel := &models.Quiz{
				VideoID:            video.ID,
				Question:           q.Question,
				Options:            q.Options,
				CorrectAnswerIndex: correctIndex,
			}

			// Hata olsa bile devam et, en azından bir kısmı eklenebilir
			_ = repository.AddQuiz(c.Context(), quizModel)
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "Video başarıyla eklendi",
		"video":   video,
	})
}

// UploadVideoToFTPHandler POST /api/videos/upload - Video dosyasını FTP'ye yükler
func UploadVideoToFTPHandler(c *fiber.Ctx) error {
	// Multipart form'dan 'video' anahtarını al
	fileHeader, err := c.FormFile("video")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Video dosyası bulunamadı",
		})
	}

	// Servisi çağırıp FTP'ye yükle
	publicUrl, err := services.UploadToFTP(fileHeader)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "FTP yükleme hatası",
			"details": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Video FTP'ye başarıyla yüklendi",
		"url":     publicUrl,
	})
}

