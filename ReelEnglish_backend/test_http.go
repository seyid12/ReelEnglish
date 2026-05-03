package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/jlaffaye/ftp"
)

func main() {
	ftpHost := "2.59.119.221"
	ftpPort := "21"
	ftpUser := "depo"
	ftpPass := "Acid1234!."
	baseUrl := "https://depom.anadolusagliksen.com/depom.anadolusagliksen.com"

	c, err := ftp.Dial(fmt.Sprintf("%s:%s", ftpHost, ftpPort), ftp.DialWithTimeout(10*time.Second))
	if err != nil {
		fmt.Printf("FTP Dial error: %v\n", err)
		return
	}
	defer c.Quit()

	err = c.Login(ftpUser, ftpPass)
	if err != nil {
		fmt.Printf("FTP Login error: %v\n", err)
		return
	}

	// Klasöre geçiş yapmayı dene
	err = c.ChangeDir("depom.anadolusagliksen.com")
	if err != nil {
		fmt.Printf("UYARI: depom.anadolusagliksen.com klasörüne geçilemedi: %v\n", err)
		// Belki de kök dizin web alanıdır? Yine de kök dizini listeleyelim.
	} else {
		fmt.Println("BAŞARILI: depom.anadolusagliksen.com klasörüne geçildi.")
	}

	entries, err := c.List(".")
	if err != nil {
		fmt.Printf("FTP List error: %v\n", err)
		return
	}

	for _, entry := range entries {
		if entry.Type == ftp.EntryTypeFile {
			fmt.Printf("Found file on FTP: %s\n", entry.Name)
			url := fmt.Sprintf("%s/%s", baseUrl, entry.Name)
			fmt.Printf("Testing HTTP link: %s\n", url)

			resp, err := http.Get(url)
			if err != nil {
				fmt.Printf("HTTP GET error: %v\n", err)
			} else {
				fmt.Printf("HTTP Status: %s\n", resp.Status)
				resp.Body.Close()
			}
			return
		}
	}
	fmt.Println("Done.")
}
