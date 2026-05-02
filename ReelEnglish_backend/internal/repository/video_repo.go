package repository

import (
	"context"
	"fmt"

	"reelenglish/internal/config"
	"reelenglish/internal/models"

	"google.golang.org/api/iterator"
)

// GetFeedVideos retrieves up to 5 videos from the "videos" collection in Firestore
func GetFeedVideos(ctx context.Context) ([]models.Video, error) {
	if config.FirebaseApp == nil {
		return nil, fmt.Errorf("firebase app başlatılmamış")
	}

	client, err := config.FirebaseApp.Firestore(ctx)
	if err != nil {
		return nil, fmt.Errorf("firestore client alınamadı: %v", err)
	}
	defer client.Close()

	// "videos" koleksiyonundan ilk 5 videoyu çek
	iter := client.Collection("videos").Limit(5).Documents(ctx)
	var videos []models.Video

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("doküman okunurken hata oluştu: %v", err)
		}

		var video models.Video
		if err := doc.DataTo(&video); err != nil {
			// Dönüştürme hatası olursa bu dokümanı atla
			continue
		}

		// Firestore doküman ID'sini modele ata (eğer veritabanında 'id' alanı yoksa)
		if video.ID == "" {
			video.ID = doc.Ref.ID
		}

		videos = append(videos, video)
	}

	return videos, nil
}
