/// 简报模型
/// 对应 PRD Section 3.2.5 Briefing 表
class Briefing {
  final String id;
  final String date;
  final int articleCount;
  final String? configSnapshot;
  final int generatedAt;
  final String triggerType; // "scheduled" | "manual"
  final String status; // "generating" | "completed" | "failed"
  final String? aiInsight;
  final int totalFetched;
  final int domesticCount;
  final int internationalCount;
  final String? categoriesJson;

  const Briefing({
    required this.id,
    required this.date,
    required this.articleCount,
    this.configSnapshot,
    required this.generatedAt,
    required this.triggerType,
    required this.status,
    this.aiInsight,
    this.totalFetched = 0,
    this.domesticCount = 0,
    this.internationalCount = 0,
    this.categoriesJson,
  });

  Briefing copyWith({
    int? articleCount,
    String? status,
    String? aiInsight,
    int? totalFetched,
    int? domesticCount,
    int? internationalCount,
    String? categoriesJson,
  }) {
    return Briefing(
      id: id,
      date: date,
      articleCount: articleCount ?? this.articleCount,
      configSnapshot: configSnapshot,
      generatedAt: generatedAt,
      triggerType: triggerType,
      status: status ?? this.status,
      aiInsight: aiInsight ?? this.aiInsight,
      totalFetched: totalFetched ?? this.totalFetched,
      domesticCount: domesticCount ?? this.domesticCount,
      internationalCount: internationalCount ?? this.internationalCount,
      categoriesJson: categoriesJson ?? this.categoriesJson,
    );
  }

  factory Briefing.fromMap(Map<String, dynamic> map) {
    return Briefing(
      id: map['id'] as String,
      date: map['date'] as String,
      articleCount: (map['article_count'] as int?) ?? 0,
      configSnapshot: map['config_snapshot'] as String?,
      generatedAt: map['generated_at'] as int,
      triggerType: map['trigger_type'] as String,
      status: map['status'] as String,
      aiInsight: map['ai_insight'] as String?,
      totalFetched: (map['total_fetched'] as int?) ?? 0,
      domesticCount: (map['domestic_count'] as int?) ?? 0,
      internationalCount: (map['international_count'] as int?) ?? 0,
      categoriesJson: map['categories_json'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'article_count': articleCount,
      'config_snapshot': configSnapshot,
      'generated_at': generatedAt,
      'trigger_type': triggerType,
      'status': status,
      'ai_insight': aiInsight,
      'total_fetched': totalFetched,
      'domestic_count': domesticCount,
      'international_count': internationalCount,
      'categories_json': categoriesJson,
    };
  }
}
