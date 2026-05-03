import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../models/video_model.dart';
import '../../../../services/api_service.dart';
import '../../../../services/ai_pipeline_service.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  double _difficulty = 1;
  bool _isLoading = false;
  String _statusMessage = '';

  // Local File support
  File? _selectedFile;
  final AiPipelineService _aiService = AiPipelineService();

  void _resetForm() {
    _urlController.clear();
    _tagsController.clear();
    setState(() {
      _difficulty = 1;
      _selectedFile = null;
      _statusMessage = '';
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate() && _selectedFile == null) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'İşlem başlatılıyor...';
    });

    String videoUrlToSave = _urlController.text.trim();
    String sourceType = 'youtube';

    // Eğer yerel dosya seçildiyse:
    if (_selectedFile != null) {
      sourceType = 'drive';
      setState(() {
        _statusMessage = 'AI: Ses ayrıştırılıyor ve transkript hazırlanıyor...';
      });

      // 1. AI ile kelime ve quiz çıkar
      final aiResult = await _aiService.processVideoAi(_selectedFile!);
      if (aiResult == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'AI işlemi başarısız oldu (API Key eksik olabilir). Sadece video yüklenecek.';
        });
        // İsterseniz burada retun edip durdurabilirsiniz.
      } else {
        setState(() {
          _statusMessage = "AI analizi tamamlandı!\nKelimeler: ${aiResult['words']?.length ?? 0}\nSoru Sayısı: ${aiResult['quiz']?.length ?? 0}";
        });
      }

      setState(() {
        _statusMessage = "Video Google Drive'a yükleniyor...";
      });

      // 2. Videoyu Go Backend üzerinden Drive'a yükle
      final driveUrl = await ApiService.uploadVideoToDrive(_selectedFile!.path);
      if (driveUrl == null) {
         setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Drive yüklemesi başarısız oldu.')));
        return;
      }
      
      videoUrlToSave = driveUrl;

      // TODO: Eğer Backend Firestore'da quiz'i de kaydedecekse, AddVideo api'sini güncelleyip
      // aiResult verisini (Kelimeler ve Quiz) backend'e payload olarak yollamamız gerekir.
      // Şimdilik sadece Videoyu (drive url ile) ekliyoruz.
    }

    setState(() {
      _statusMessage = "Video Firestore'a kaydediliyor...";
    });

    final newVideo = VideoModel(
      id: '',
      videoUrl: videoUrlToSave,
      difficultyLevel: _difficulty.toInt().toString(),
      grammarTopic: _tagsController.text,
      sourceType: sourceType,
    );
    
    final success = await ApiService.addVideo(newVideo);
    
    setState(() {
      _isLoading = false;
      _statusMessage = '';
    });
    
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Video başarıyla eklendi!')));
      _resetForm();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bir hata oluştu.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Video Ekle (AI Destekli)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seçenek 1: Yerel Video (Drive + AI)
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Seçenek: Yerel Video (Önerilen)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text("Cihazdan seçilen videolar otomatik olarak Drive'a yüklenir ve AI ile kelime/quiz analizinden geçer."),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.video_file),
                        label: Text(_selectedFile == null ? 'Video Seç (.mp4)' : "Değiştir (${_selectedFile!.path.split('/').last})"),
                        onPressed: _pickFile,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              const Center(child: Text('--- VEYA ---', style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 16),

              // Seçenek 2: YouTube URL
              TextFormField(
                controller: _urlController,
                enabled: _selectedFile == null,
                decoration: InputDecoration(
                  labelText: '2. Seçenek: YouTube Shorts URL',
                  hintText: 'Sadece yerel video seçmezseniz geçerlidir',
                  border: const OutlineInputBorder(),
                  fillColor: _selectedFile != null ? Colors.grey.shade200 : null,
                  filled: _selectedFile != null,
                ),
                validator: (value) {
                  if (_selectedFile == null && (value == null || value.isEmpty)) {
                    return 'Video seçin veya URL girin';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Zorluk Seviyesi:'),
                  Expanded(
                    child: Slider(
                      value: _difficulty,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _difficulty.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _difficulty = value;
                        });
                      },
                    ),
                  ),
                  Text(_difficulty.round().toString()),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Gramer Etiketleri (virgülle)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              
              if (_isLoading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _saveVideo,
                    child: const Text('İşlemi Başlat ve Kaydet', style: TextStyle(fontSize: 16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
