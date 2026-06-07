import 'dart:convert';

/// 用户配置模型
/// 对应 PRD Section 3.2.5 UserConfig 表
class UserConfig {
  final List<String> categories;
  final int dailyCount;
  final double domesticRatio;
  final String pushTime;
  final String aiMode; // "economy" | "quality" | "hybrid"
  final int retentionDays;
  final int fetchInterval;
  final bool wifiOnly;
  final bool onboardingDone;

  const UserConfig({
    this.categories = const [],
    this.dailyCount = 10,
    this.domesticRatio = 0.5,
    this.pushTime = '08:00',
    this.aiMode = 'hybrid',
    this.retentionDays = 30,
    this.fetchInterval = 2,
    this.wifiOnly = false,
    this.onboardingDone = false,
  });

  UserConfig copyWith({
    List<String>? categories,
    int? dailyCount,
    double? domesticRatio,
    String? pushTime,
    String? aiMode,
    int? retentionDays,
    int? fetchInterval,
    bool? wifiOnly,
    bool? onboardingDone,
  }) {
    return UserConfig(
      categories: categories ?? this.categories,
      dailyCount: dailyCount ?? this.dailyCount,
      domesticRatio: domesticRatio ?? this.domesticRatio,
      pushTime: pushTime ?? this.pushTime,
      aiMode: aiMode ?? this.aiMode,
      retentionDays: retentionDays ?? this.retentionDays,
      fetchInterval: fetchInterval ?? this.fetchInterval,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  factory UserConfig.fromMap(Map<String, dynamic> map) {
    return UserConfig(
      categories: _parseJsonList(map['categories'] as String?),
      dailyCount: (map['daily_count'] as int?) ?? 10,
      domesticRatio: _normalizeRatio((map['domestic_ratio'] as num?)?.toDouble() ?? 0.5),
      pushTime: (map['push_time'] as String?) ?? '08:00',
      aiMode: _normalizeAiMode((map['ai_mode'] as String?) ?? 'hybrid'),
      retentionDays: (map['retention_days'] as int?) ?? 30,
      fetchInterval: (map['fetch_interval'] as int?) ?? 2,
      wifiOnly: (map['wifi_only'] as int?) == 1,
      onboardingDone: (map['onboarding_done'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 'default',
      'categories': jsonEncode(categories),
      'daily_count': dailyCount,
      'domestic_ratio': domesticRatio,
      'push_time': pushTime,
      'ai_mode': aiMode,
      'retention_days': retentionDays,
      'fetch_interval': fetchInterval,
      'wifi_only': wifiOnly ? 1 : 0,
      'onboarding_done': onboardingDone ? 1 : 0,
    };
  }

  static List<String> _parseJsonList(String? json) {
    if (json == null || json.isEmpty) return [];
    return json
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
  }

  /// 归一化比例值到 0-1 范围（兼容旧数据存了0-100的情况）
  static double _normalizeRatio(double value) {
    if (value > 1.0) return value / 100.0;
    return value;
  }

  /// 归一化 AI 模式值（兼容旧数据存了 local/llm 的情况）
  static String _normalizeAiMode(String value) {
    switch (value) {
      case 'local':
        return 'economy';
      case 'llm':
        return 'quality';
      default:
        return value; // economy / quality / hybrid
    }
  }
}
