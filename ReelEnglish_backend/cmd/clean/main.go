package main

import (
	"context"
	"log"

	"reelenglish/internal/config"

	"google.golang.org/api/iterator"
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

	// 2. "videos" koleksiyonundaki tüm dokümanları bul
	iter := client.Collection("videos").Documents(ctx)
	batch := client.Batch()
	count := 0

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Fatalf("❌ Doküman okunurken hata oluştu: %v", err)
		}

		// Dokümanı silinecekler listesine (batch) ekle
		batch.Delete(doc.Ref)
		count++
	}

	// 3. Silme işlemini uygula
	if count > 0 {
		_, err := batch.Commit(ctx)
		if err != nil {
			log.Fatalf("❌ Silme işlemi (Batch Commit) başarısız oldu: %v", err)
		}
	}

	log.Printf("🧹 Başarılı! 'videos' koleksiyonundaki toplam %d adet video tamamen temizlendi.\n", count)
}
