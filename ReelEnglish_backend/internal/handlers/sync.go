package handlers

import (
	"github.com/gofiber/fiber/v2"

	"reelenglish/internal/models"
	"reelenglish/internal/repository"
)

// SyncProgressHandler kullanıcının öğrenme verilerini kaydeder
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

	// Repository üzerinden Firestore'a kaydet
	// Fiber'in Context'i genelde context.Background yerine request context içerir. c.Context() kullanabiliriz.
	if err := repository.UpdateUserProgress(c.Context(), req); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Veriler senkronize edilemedi: " + err.Error(),
		})
	}

	// Başarılı yanıt
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Progress synced successfully",
	})
}
