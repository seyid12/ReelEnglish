package repository

import (
	"context"
	"fmt"

	"cloud.google.com/go/firestore"
	"reelenglish/internal/config"
	"reelenglish/internal/models"
)

// UpdateUserProgress updates or creates user progress in Firestore
func UpdateUserProgress(ctx context.Context, req models.SyncRequest) error {
	if config.FirebaseApp == nil {
		return fmt.Errorf("firebase app başlatılmamış")
	}

	client, err := config.FirebaseApp.Firestore(ctx)
	if err != nil {
		return fmt.Errorf("firestore client alınamadı: %v", err)
	}
	defer client.Close()

	docRef := client.Collection("users").Doc(req.UserID)

	// Firestore'a güncellenecek veya yazılacak verileri hazırla
	updates := map[string]interface{}{
		"focus_score":      req.FocusScore,
		"session_duration": req.SessionDuration,
	}

	// Dizileri ArrayUnion ile mevcut diziye ekle (eğer dizi varsa öğe eklenir, yoksa yeni dizi oluşur)
	if len(req.LearnedWords) > 0 {
		updates["learned_words"] = firestore.ArrayUnion(toInterfaceSlice(req.LearnedWords)...)
	}
	if len(req.StruggledGrammar) > 0 {
		updates["struggled_grammar"] = firestore.ArrayUnion(toInterfaceSlice(req.StruggledGrammar)...)
	}

	// Set komutu ve firestore.MergeAll kullanarak, doküman yoksa oluşturulmasını, varsa üzerine yazılmadan sadece ilgili alanların güncellenmesini sağlıyoruz.
	_, err = docRef.Set(ctx, updates, firestore.MergeAll)
	if err != nil {
		return fmt.Errorf("kullanıcı verisi güncellenemedi: %v", err)
	}

	return nil
}

// toInterfaceSlice string dizisini firestore.ArrayUnion için interface dizisine çevirir
func toInterfaceSlice(strSlice []string) []interface{} {
	interfaceSlice := make([]interface{}, len(strSlice))
	for i, v := range strSlice {
		interfaceSlice[i] = v
	}
	return interfaceSlice
}
