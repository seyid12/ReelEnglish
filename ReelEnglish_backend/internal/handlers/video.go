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
		URL        string   `json:"url"`
		Difficulty int      `json:"difficulty"`
		GrammarTags []string `json:"grammar_tags"`
		SourceType string   `json:"source_type"`
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
	}

	// Veritabanına ekle
	if err := repository.AddVideo(c.Context(), video); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Video eklenirken hata oluştu",
			"details": err.Error(),
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "Video başarıyla eklendi",
		"video":   video,
	})
}

// UploadVideoToDriveHandler POST /api/videos/upload - Video dosyasını Drive'a yükler
func UploadVideoToDriveHandler(c *fiber.Ctx) error {
	// Multipart form'dan 'video' anahtarını al
	fileHeader, err := c.FormFile("video")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Video dosyası bulunamadı",
		})
	}

	// Servisi çağırıp Drive'a yükle
	publicUrl, err := services.UploadToDrive(fileHeader)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Drive yükleme hatası",
			"details": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Video Drive'a başarıyla yüklendi",
		"url":     publicUrl,
	})
}

