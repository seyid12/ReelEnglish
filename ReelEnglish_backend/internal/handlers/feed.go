package handlers

import (
	"github.com/gofiber/fiber/v2"

	"reelenglish/internal/repository"
)

// GetFeedHandler Firestore'daki gerçek video verilerini döndüren GET endpoint'i
func GetFeedHandler(c *fiber.Ctx) error {
	// Repository katmanından verileri çek
	videos, err := repository.GetFeedVideos(c.Context())
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Videolar getirilirken sunucu hatası oluştu",
			"details": err.Error(),
		})
	}

	// Eğer veritabanında video yoksa 404 dön
	if len(videos) == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Veritabanında hiç video bulunamadı",
		})
	}

	// Başarılıysa JSON olarak dön
	return c.JSON(videos)
}
