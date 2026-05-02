package main

import (
	"context"
	"log"

	"reelenglish/internal/config"
	"reelenglish/internal/models"
)

func main() {
	// 1. Firebase yapılandırmasını başlat
	config.InitFirebase()
	if config.FirebaseApp == nil {
		log.Fatalf("❌ Firebase başlatılamadı.")
	}

	ctx := context.Background()
	client, err := config.FirebaseApp.Firestore(ctx)
	if err != nil {
		log.Fatalf("❌ Firestore'a bağlanılamadı: %v", err)
	}
	defer client.Close()

	// 2. Tohumlanacak (Seed) çalışan video verilerini hazırla
	seedVideos := []models.Video{
		{
			URL:         "https://youtube.com/shorts/80-9LbaABlQ", // Çalıştığı onaylanan yeni YouTube linki
			Difficulty:  4,
			GrammarTags: []string{"Vocabulary", "Daily Routine", "Phrasal Verbs"},
			AvatarType:  "2D_Human",
			SourceType:  "youtube",
		},
		{
			URL:         "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
			Difficulty:  6,
			GrammarTags: []string{"Past Continuous", "Storytelling"},
			AvatarType:  "3D_Anim",
			SourceType:  "firebase",
		},
		{
			URL:         "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
			Difficulty:  8,
			GrammarTags: []string{"Conditionals Type 2"},
			AvatarType:  "3D_Anim",
			SourceType:  "firebase",
		},
	}

	// 3. Videoları tek tek veritabanına ekle
	collection := client.Collection("videos")
	for _, video := range seedVideos {
		// Koleksiyona yeni doküman ekle (ID otomatik oluşturulur)
		_, _, err := collection.Add(ctx, video)
		if err != nil {
			log.Fatalf("❌ Video eklenirken hata oluştu: %v", err)
		}
	}

	log.Println("✅ Veritabanı çalışan yeni linklerle başarıyla tohumlandı!")
}
