import 'dart:convert';

/// 文章数据模型
/// 对应 PRD Section 3.2.5 Article 表
class Article {
  final String id;
  final String title;
  final String url;
  final String? content;
  final String? summaryOne;
  final List<String> summaryPoints;
  final String sourceName;
  final String? sourceUrl;
  final String? category;
  final int publishedAt;
  final int fetchedAt;
  final double scoreTotal;
  final double scoreCredibility;
  final double scoreDensity;
  final String scoreMode; // "local" | "llm"
  final bool isRead;
  final bool isFavorited;
  final bool isFulltext;
  final List<String> mergedArticleIds;
  final String? briefingId;
  final String? actionTag;

  const Article({
    required this.id,
    required this.title,
    required this.url,
    this.content,
    this.summaryOne,
    this.summaryPoints = const [],
    required this.sourceName,
    this.sourceUrl,
    this.category,
    required this.publishedAt,
    required this.fetchedAt,
    this.scoreTotal = 0,
    this.scoreCredibility = 0,
    this.scoreDensity = 0,
    this.scoreMode = 'local',
    this.isRead = false,
    this.isFavorited = false,
    this.isFulltext = true,
    this.mergedArticleIds = const [],
    this.briefingId,
    this.actionTag,
  });

  Article copyWith({
    bool? isRead,
    bool? isFavorited,
    double? scoreTotal,
    double? scoreCredibility,
    double? scoreDensity,
    String? scoreMode,
    String? summaryOne,
    List<String>? summaryPoints,
    String? briefingId,
    String? actionTag,
  }) {
    return Article(
      id: id,
      title: title,
      url: url,
      content: content,
      summaryOne: summaryOne ?? this.summaryOne,
      summaryPoints: summaryPoints ?? this.summaryPoints,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      category: category,
      publishedAt: publishedAt,
      fetchedAt: fetchedAt,
      scoreTotal: scoreTotal ?? this.scoreTotal,
      scoreCredibility: scoreCredibility ?? this.scoreCredibility,
      scoreDensity: scoreDensity ?? this.scoreDensity,
      scoreMode: scoreMode ?? this.scoreMode,
      isRead: isRead ?? this.isRead,
      isFavorited: isFavorited ?? this.isFavorited,
      isFulltext: isFulltext,
      mergedArticleIds: mergedArticleIds,
      briefingId: briefingId ?? this.briefingId,
      actionTag: actionTag ?? this.actionTag,
    );
  }

  /// 从 SQLite 行数据构造
  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      content: map['content'] as String?,
      summaryOne: map['summary_one'] as String?,
      summaryPoints: _parseJsonList(map['summary_points'] as String?),
      sourceName: (map['source_name'] as String?) ?? '',
      sourceUrl: map['source_url'] as String?,
      category: map['category'] as String?,
      publishedAt: map['published_at'] as int,
      fetchedAt: map['fetched_at'] as int,
      scoreTotal: (map['score_total'] as num?)?.toDouble() ?? 0,
      scoreCredibility: (map['score_credibility'] as num?)?.toDouble() ?? 0,
      scoreDensity: (map['score_density'] as num?)?.toDouble() ?? 0,
      scoreMode: map['score_mode'] as String? ?? 'local',
      isRead: (map['is_read'] as int?) == 1,
      isFavorited: (map['is_favorited'] as int?) == 1,
      isFulltext: (map['is_fulltext'] as int?) == 1,
      mergedArticleIds: _parseJsonList(map['merged_article_ids'] as String?),
      briefingId: map['briefing_id'] as String?,
      actionTag: map['action_tag'] as String?,
    );
  }

  /// 转为 SQLite 行数据
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'content': content,
      'summary_one': summaryOne,
      'summary_points': summaryPoints.isNotEmpty
          ? jsonEncode(summaryPoints)
          : null,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'category': category,
      'published_at': publishedAt,
      'fetched_at': fetchedAt,
      'score_total': scoreTotal,
      'score_credibility': scoreCredibility,
      'score_density': scoreDensity,
      'score_mode': scoreMode,
      'is_read': isRead ? 1 : 0,
      'is_favorited': isFavorited ? 1 : 0,
      'is_fulltext': isFulltext ? 1 : 0,
      'merged_article_ids': mergedArticleIds.isNotEmpty
          ? jsonEncode(mergedArticleIds)
          : null,
      'briefing_id': briefingId,
      'action_tag': actionTag,
    };
  }

  static List<String> _parseJsonList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    // 降级：处理非标准JSON格式（如 Dart toString 输出的 [a, b]）
    return json
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
  }
}
