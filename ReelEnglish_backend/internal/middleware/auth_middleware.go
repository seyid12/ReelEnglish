package middleware

import (
	"context"
	"strings"

	"github.com/gofiber/fiber/v2"
	"reelenglish/internal/config"
)

// FirebaseAuth Firebase ID Token doğrulaması yapan middleware'dir.
// Authorization header'ından 'Bearer <token>' formatındaki token'ı alır ve doğrular.
// Geçersiz veya eksik token'da 401 Unauthorized hatası döner.
func FirebaseAuth() fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Authorization header'ını al
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Authorization header eksik",
			})
		}

		// 'Bearer ' kısmını kaldır
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Geçersiz Authorization header formatı. 'Bearer <token>' şeklinde olmalı.",
			})
		}

		token := parts[1]

		// Firebase Admin SDK ile token'ı doğrula
		authClient, err := config.FirebaseApp.Auth(context.Background())
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Firebase Auth istemcisi oluşturulamadı",
			})
		}

		claims, err := authClient.VerifyIDToken(context.Background(), token)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Token doğrulaması başarısız: " + err.Error(),
			})
		}

		// Token geçerli, kullanıcı UID'sini context'e ekle
		c.Locals("uid", claims.UID)
		c.Locals("claims", claims)

		// İşleme devam et
		return c.Next()
	}
}
