/// 数据源模型
/// 对应 PRD Section 3.2.5 Feed 表
class Feed {
  final String id;
  final String name;
  final String url;
  final String type; // "rss" | "atom" | "api"
  final String? category;
  final bool isEnabled;
  final bool isPreset;
  final double credibilityWeight;
  final int? lastFetchedAt;
  final int fetchErrorCount;
  final bool isDomestic;
  final double credibility; // 0-10
  final String status; // 'active' | 'error' | 'disabled'

  const Feed({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.category,
    this.isEnabled = true,
    this.isPreset = false,
    this.credibilityWeight = 3.0,
    this.lastFetchedAt,
    this.fetchErrorCount = 0,
    this.isDomestic = true,
    this.credibility = 5.0,
    this.status = 'active',
  });

  Feed copyWith({
    bool? isEnabled,
    int? lastFetchedAt,
    int? fetchErrorCount,
    double? credibilityWeight,
    bool? isDomestic,
    double? credibility,
    String? status,
  }) {
    return Feed(
      id: id,
      name: name,
      url: url,
      type: type,
      category: category,
      isEnabled: isEnabled ?? this.isEnabled,
      isPreset: isPreset,
      credibilityWeight: credibilityWeight ?? this.credibilityWeight,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      fetchErrorCount: fetchErrorCount ?? this.fetchErrorCount,
      isDomestic: isDomestic ?? this.isDomestic,
      credibility: credibility ?? this.credibility,
      status: status ?? this.status,
    );
  }

  factory Feed.fromMap(Map<String, dynamic> map) {
    return Feed(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
      category: map['category'] as String?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      isPreset: (map['is_preset'] as int?) == 1,
      credibilityWeight:
          (map['credibility_weight'] as num?)?.toDouble() ?? 3.0,
      lastFetchedAt: map['last_fetched_at'] as int?,
      fetchErrorCount: (map['fetch_error_count'] as int?) ?? 0,
      isDomestic: (map['is_domestic'] as int?) != 0,
      credibility: (map['credibility'] as num?)?.toDouble() ?? 5.0,
      status: (map['status'] as String?) ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'category': category,
      'is_enabled': isEnabled ? 1 : 0,
      'is_preset': isPreset ? 1 : 0,
      'credibility_weight': credibilityWeight,
      'last_fetched_at': lastFetchedAt,
      'fetch_error_count': fetchErrorCount,
      'is_domestic': isDomestic ? 1 : 0,
      'credibility': credibility,
      'status': status,
    };
  }
}
