package services

import (
	"context"
	"fmt"
	"mime/multipart"
	"os"
	"path/filepath"

	"google.golang.org/api/drive/v3"
	"google.golang.org/api/option"
)

// UploadToDrive belirtilen MP4 dosyasını Google Drive'a yükler ve public stream URL'sini döner.
func UploadToDrive(fileHeader *multipart.FileHeader) (string, error) {
	// 1. Dosyayı geçici olarak diske kaydet
	file, err := fileHeader.Open()
	if err != nil {
		return "", fmt.Errorf("dosya açılamadı: %v", err)
	}
	defer file.Close()

	// 2. Drive Servisini başlat (Kimlik Doğrulama)
	// TODO: Canlıya çıkarken "credentials.json" dosyasının yolu ENV'den alınmalı.
	credentialsPath := "credentials.json" 
	if _, err := os.Stat(credentialsPath); os.IsNotExist(err) {
		return "", fmt.Errorf("Google Drive API için credentials.json bulunamadı. Lütfen ekleyin")
	}

	ctx := context.Background()
	driveService, err := drive.NewService(ctx, option.WithCredentialsFile(credentialsPath))
	if err != nil {
		return "", fmt.Errorf("drive servisi başlatılamadı: %v", err)
	}

	// 3. Drive'a yüklenecek dosyanın metadata ayarları
	f := &drive.File{
		Name:     filepath.Base(fileHeader.Filename),
		MimeType: "video/mp4",
		// Opsiyonel: Belli bir klasöre yüklemek isterseniz klasör ID'sini verebilirsiniz
		// Parents: []string{"FOLDER_ID_HERE"},
	}

	// 4. Yükleme İşlemi
	res, err := driveService.Files.Create(f).Media(file).Do()
	if err != nil {
		return "", fmt.Errorf("dosya drive'a yüklenemedi: %v", err)
	}

	// 5. Herkesin okuyabilmesi (Public Read) için izin ayarla
	permission := &drive.Permission{
		Type: "anyone",
		Role: "reader",
	}
	_, err = driveService.Permissions.Create(res.Id, permission).Do()
	if err != nil {
		return "", fmt.Errorf("dosya izni ayarlanamadı: %v", err)
	}

	// 6. Dosyanın Stream (İndirme) linkini oluştur
	// Bu link sayesinde video doğrudan mobil uygulamada oynatılabilir
	publicUrl := fmt.Sprintf("https://drive.google.com/uc?export=download&id=%s", res.Id)

	return publicUrl, nil
}
