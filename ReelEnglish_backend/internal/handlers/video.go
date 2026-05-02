package handlers

import (
	"reelenglish/internal/models"
	"reelenglish/internal/repository"

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
