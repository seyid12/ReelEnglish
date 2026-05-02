import 'package:flutter/material.dart';
import '../../../../models/video_model.dart';
import '../../../../services/api_service.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({Key? key}) : super(key: key);

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  double _difficulty = 1;
  bool _isLoading = false;

  void _resetForm() {
    _urlController.clear();
    _tagsController.clear();
    setState(() {
      _difficulty = 1;
    });
  }

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    final newVideo = VideoModel(
      id: '',
      videoUrl: _urlController.text.trim(),
      difficultyLevel: _difficulty.toInt().toString(),
      grammarTopic: _tagsController.text,
      sourceType: 'youtube',
    );
    final success = await ApiService.addVideo(newVideo);
    setState(() { _isLoading = false; });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video başarıyla eklendi!')),
      );
      _resetForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu.')), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Video Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'YouTube Shorts URL'),
                validator: (value) => value == null || value.isEmpty ? 'URL gerekli' : null,
              ),
              const SizedBox(height: 16),
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
                        setState(() { _difficulty = value; });
                      },
                    ),
                  ),
                  Text(_difficulty.round().toString()),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Gramer Etiketleri (virgülle)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVideo,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
