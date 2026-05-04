package handlers

import (
	"reelenglish/internal/repository"

	"github.com/gofiber/fiber/v2"
)

// RegisterUserHandler POST /api/users/register
// Flutter'da Firebase Auth ile kayıt olduktan sonra çağrılır.
// Firestore'a kullanıcı belgesini (rol: "user") oluşturur.
func RegisterUserHandler(c *fiber.Ctx) error {
	var req struct {
		UID   string `json:"uid"`
		Email string `json:"email"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "İstek ayrıştırılamadı",
		})
	}

	if req.UID == "" || req.Email == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "uid ve email gerekli",
		})
	}

	if err := repository.CreateUser(c.Context(), req.UID, req.Email); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Kullanıcı oluşturulamadı",
			"details": err.Error(),
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "Kullanıcı başarıyla oluşturuldu",
	})
}

// GetMeHandler GET /api/users/me
// JWT token'dan UID alıp Firestore'dan kullanıcı bilgisini (rol dahil) döner.
func GetMeHandler(c *fiber.Ctx) error {
	// UID, FirebaseAuth middleware tarafından context'e eklenir
	uid, ok := c.Locals("uid").(string)
	if !ok || uid == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Kimlik doğrulanamadı",
		})
	}

	user, err := repository.GetUser(c.Context(), uid)
	if err != nil {
		// Kullanıcı belgesi yoksa (eski kullanıcılar için) varsayılan döndür
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"uid":   uid,
			"role":  "user",
			"email": "",
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"uid":   user.UID,
		"role":  user.Role,
		"email": user.Email,
	})
}

// DeleteUserHandler DELETE /api/users/me
// Firestore'dan kullanıcı belgesini siler. Firebase Auth silme işlemi Flutter'da yapılır.
func DeleteUserHandler(c *fiber.Ctx) error {
	uid, ok := c.Locals("uid").(string)
	if !ok || uid == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Kimlik doğrulanamadı",
		})
	}

	if err := repository.DeleteUser(c.Context(), uid); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "Kullanıcı silinemedi",
			"details": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Kullanıcı belgesi silindi",
	})
}
