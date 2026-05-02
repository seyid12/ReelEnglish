class VideoModel {
  final String id;
  final String videoUrl;
  final String grammarTopic;
  final String difficultyLevel;
  final String sourceType;

  VideoModel({
    required this.id,
    required this.videoUrl,
    required this.grammarTopic,
    required this.difficultyLevel,
    this.sourceType = 'firebase',
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    String parsedGrammar = json['grammarTopic'] ?? '';
    if (json['grammar_tags'] != null && json['grammar_tags'] is List) {
      parsedGrammar = (json['grammar_tags'] as List).join(', ');
    }

    String parsedDifficulty = json['difficultyLevel'] ?? '';
    if (json['difficulty'] != null) {
      parsedDifficulty = 'Seviye: ${json['difficulty']}/10';
    }

    return VideoModel(
      id: json['id']?.toString() ?? '',
      videoUrl: json['url'] ?? json['videoUrl'] ?? '',
      grammarTopic: parsedGrammar,
      difficultyLevel: parsedDifficulty,
      sourceType: json['source_type'] ?? 'firebase',
    );
  }
}
