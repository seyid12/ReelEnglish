package handlers

import (
	"context"
	"log"

	"strconv"

	"cloud.google.com/go/firestore"
	"github.com/gofiber/fiber/v2"
	"google.golang.org/api/iterator"
	"reelenglish/internal/config"
	"reelenglish/internal/models"
)

// GetQuizzesHandler belirli bir video için soruları getirir
func GetQuizzesHandler(c *fiber.Ctx) error {
	videoID := c.Query("video_id")
	if videoID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "video_id parametresi gerekli",
		})
	}

	ctx := context.Background()
	client, err := config.FirebaseApp.Firestore(ctx)
	if err != nil {
		log.Printf("Firestore istemcisi oluşturulamadı: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Firestore hatası",
		})
	}
	defer client.Close()

	// Belirtilen video_id'ye ait soruları sorgula
	query := client.Collection("quizzes").Where("video_id", "==", videoID)
	iter := query.Documents(ctx)
	defer iter.Stop()

	var quizzes []models.Quiz

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Printf("Sorgulama hatası: %v", err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "Sorgulama hatası",
			})
		}

		var quiz models.Quiz
		if err := doc.DataTo(&quiz); err != nil {
			log.Printf("Deserialization hatası: %v", err)
			continue
		}

		quizzes = append(quizzes, quiz)
	}

	if len(quizzes) == 0 {
		quizzes = []models.Quiz{}
	}

	return c.JSON(quizzes)
}

// SubmitQuizHandler quiz cevabını doğrular ve XP kazandırır
func SubmitQuizHandler(c *fiber.Ctx) error {
	var submission models.QuizSubmission

	if err := c.BodyParser(&submission); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "İstek gövdesi geçersiz",
		})
	}

	ctx := context.Background()
	client, err := config.FirebaseApp.Firestore(ctx)
	if err != nil {
		log.Printf("Firestore istemcisi oluşturulamadı: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Firestore hatası",
		})
	}
	defer client.Close()

	// Quiz'i Firestore'dan al
	doc, err := client.Collection("quizzes").Doc(submission.QuizID).Get(ctx)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Quiz bulunamadı",
		})
	}

	var quiz models.Quiz
	if err := doc.DataTo(&quiz); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Quiz ayrıştırılamadı",
		})
	}

	// Cevabı doğrula
	isCorrect := submission.SelectedAnswerIndex == quiz.CorrectAnswerIndex
	xpEarned := 0

	if isCorrect {
		xpEarned = 100
	}

	// Submission'ı kaydet
	submission.IsCorrect = isCorrect
	submission.XPEarned = xpEarned

	// User stats'i güncelle (XP ekle)
	if isCorrect {
		userRef := client.Collection("users").Doc(submission.UserID)
		_, err := userRef.Update(ctx, []firestore.Update{
			{
				Path:  "total_xp",
				Value: firestore.Increment(int64(xpEarned)),
			},
			{
				Path:  "quiz_attempts",
				Value: firestore.Increment(1),
			},
			{
				Path:  "quiz_correct",
				Value: firestore.Increment(1),
			},
		})
		if err != nil {
			log.Printf("User stats güncellenemedi: %v", err)
		}
	} else {
		userRef := client.Collection("users").Doc(submission.UserID)
		_, err := userRef.Update(ctx, []firestore.Update{
			{
				Path:  "quiz_attempts",
				Value: firestore.Increment(1),
			},
		})
		if err != nil {
			log.Printf("User stats güncellenemedi: %v", err)
		}
	}

	return c.JSON(submission)
}

// GetQuizStatsHandler kullanıcının quiz istatistiklerini getirir
func GetQuizStatsHandler(c *fiber.Ctx) error {
	userID := c.Query("user_id")
	if userID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "user_id parametresi gerekli",
		})
	}

	ctx := context.Background()
	client, err := config.FirebaseApp.Firestore(ctx)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Firestore hatası",
		})
	}
	defer client.Close()

	doc, err := client.Collection("users").Doc(userID).Get(ctx)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Kullanıcı bulunamadı",
		})
	}

	data := doc.Data()

	stats := fiber.Map{
		"user_id":       userID,
		"total_xp":      data["total_xp"],
		"quiz_attempts": data["quiz_attempts"],
		"quiz_correct":  data["quiz_correct"],
		"accuracy":      "0%",
	}

	if attempts, ok := data["quiz_attempts"].(int64); ok && attempts > 0 {
		if correct, ok := data["quiz_correct"].(int64); ok {
			accuracy := float64(correct) / float64(attempts) * 100
			stats["accuracy"] = strconv.FormatFloat(accuracy, 'f', 1, 64) + "%"
		}
	}

	return c.JSON(stats)
}
