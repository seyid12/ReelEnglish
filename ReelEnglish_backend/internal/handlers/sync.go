package handlers

import (
	"github.com/gofiber/fiber/v2"

	"reelenglish/internal/models"
)

// SyncProgressHandler kullanıcının öğrenme verilerini alır (şimdilik log'a yazar)
func SyncProgressHandler(c *fiber.Ctx) error {
	var req models.SyncRequest

	// JSON body'sini struct'a parse et
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Geçersiz JSON formatı: " + err.Error(),
		})
	}

	// Basit doğrulama
	if req.UserID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "user_id gereklidir",
		})
	}

	// Başarılı yanıt (Firestore yazma ileriki geliştirme için bırakıldı)
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Progress synced successfully",
	})
}
