package services

import (
	"fmt"
	"mime/multipart"
	"path/filepath"
	"time"

	"github.com/jlaffaye/ftp"
)

// UploadToFTP belirtilen dosyayı FTP sunucusuna yükler ve public HTTP URL'sini döner.
func UploadToFTP(fileHeader *multipart.FileHeader) (string, error) {
	// 1. Dosyayı aç
	file, err := fileHeader.Open()
	if err != nil {
		return "", fmt.Errorf("dosya açılamadı: %v", err)
	}
	defer file.Close()

	// 2. FTP Ayarları
	// TODO: Canlı ortamda bu bilgileri OS.Getenv() ile .env'den alın
	ftpHost := "2.59.119.221"
	ftpPort := "21"
	ftpUser := "depo"
	ftpPass := "Acid1234!."
	baseUrl := "https://depom.anadolusagliksen.com"

	if ftpHost == "" {
		return "", fmt.Errorf("FTP Host ayarlanmamış. Lütfen ftp_service.go dosyasını güncelleyin")
	}

	// 3. FTP'ye Bağlan
	c, err := ftp.Dial(fmt.Sprintf("%s:%s", ftpHost, ftpPort), ftp.DialWithTimeout(5*time.Second))
	if err != nil {
		return "", fmt.Errorf("ftp bağlantı hatası: %v", err)
	}
	defer c.Quit()

	// 4. Giriş Yap
	err = c.Login(ftpUser, ftpPass)
	if err != nil {
		return "", fmt.Errorf("ftp giriş hatası: %v", err)
	}

	// 5. Dosya adını benzersiz yap (çakışmaları önlemek için timestamp ekle)
	fileName := fmt.Sprintf("%d_%s", time.Now().Unix(), filepath.Base(fileHeader.Filename))

	// Opsiyonel: Belli bir klasörün içine yüklemek isterseniz alt klasöre geçin:
	// err = c.ChangeDir("videolar_klasoru")
	// if err != nil { ... }

	// 6. Dosyayı sunucuya yaz
	err = c.Stor(fileName, file)
	if err != nil {
		return "", fmt.Errorf("ftp dosya yükleme hatası: %v", err)
	}

	// 7. Yüklenen videonun oynatılabilir HTTP linkini oluştur
	publicUrl := fmt.Sprintf("%s/%s", baseUrl, fileName)

	return publicUrl, nil
}
