class AiInsightItem {
  final String id;
  final String title;
  final String insightType;
  final String severity;
  final Map<String, dynamic> content;
  final DateTime createdAt;

  AiInsightItem({
    required this.id,
    required this.title,
    required this.insightType,
    required this.severity,
    required this.content,
    required this.createdAt,
  });

  factory AiInsightItem.fromJson(Map<String, dynamic> json) {
    return AiInsightItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      insightType: json['insight_type'] ?? 'general',
      severity: json['severity'] ?? 'medium',
      content: json['content'] is Map<String, dynamic> ? json['content'] : {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
