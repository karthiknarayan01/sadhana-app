/// Mirrors the backend's SearchResult (sadhana-backend/app/schemas.py) —
/// every language variant a matched document has, so the client can switch
/// display language locally without a second request.
class ShlokaResult {
  const ShlokaResult({
    required this.id,
    required this.category,
    required this.languagesAvailable,
    required this.name,
    required this.content,
    required this.meaning,
    required this.nameHighlight,
    required this.contentHighlight,
    required this.score,
  });

  factory ShlokaResult.fromJson(Map<String, dynamic> json) {
    final highlight = json['highlight'] as Map<String, dynamic>? ?? const {};
    return ShlokaResult(
      id: json['id'] as String,
      category: json['category'] as String,
      languagesAvailable: List<String>.from(
        json['languages_available'] as List,
      ),
      name: Map<String, String>.from(json['name'] as Map),
      content: Map<String, String>.from(json['content'] as Map),
      meaning: Map<String, String>.from(json['meaning'] as Map? ?? const {}),
      nameHighlight: List<String>.from(highlight['name'] as List? ?? const []),
      contentHighlight: List<String>.from(
        highlight['content'] as List? ?? const [],
      ),
      score: (json['score'] as num).toDouble(),
    );
  }

  final String id;
  final String category;
  final List<String> languagesAvailable;
  final Map<String, String> name;
  final Map<String, String> content;
  final Map<String, String> meaning;
  final List<String> nameHighlight;
  final List<String> contentHighlight;
  final double score;

  /// `english` is guaranteed by the backend's ingestion schema — every other
  /// language falls back to it when the preferred one isn't available for
  /// this particular entry.
  String nameIn(String language) => name[language] ?? name['english']!;
  String contentIn(String language) => content[language] ?? content['english']!;
  String? meaningIn(String language) => meaning[language] ?? meaning['english'];
}
