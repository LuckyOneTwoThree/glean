/// LLM 配置模型
/// 对应 PRD Section 3.2.5 LLMConfig 表
class LLMConfig {
  final String provider;
  final String? apiKey;
  final String model;
  final String? baseUrl;
  final bool isConfigured;
  final int timeout;
  final int budgetTokens;

  const LLMConfig({
    this.provider = 'mimo',
    this.apiKey,
    this.model = 'mimo',
    this.baseUrl,
    this.isConfigured = false,
    this.timeout = 30,
    this.budgetTokens = 10000,
  });

  LLMConfig copyWith({
    String? provider,
    String? apiKey,
    String? model,
    String? baseUrl,
    bool? isConfigured,
    int? timeout,
    int? budgetTokens,
  }) {
    return LLMConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
      isConfigured: isConfigured ?? this.isConfigured,
      timeout: timeout ?? this.timeout,
      budgetTokens: budgetTokens ?? this.budgetTokens,
    );
  }

  factory LLMConfig.fromMap(Map<String, dynamic> map) {
    return LLMConfig(
      provider: (map['provider'] as String?) ?? 'mimo',
      apiKey: map['api_key'] as String?,
      model: (map['model'] as String?) ?? 'mimo',
      baseUrl: map['base_url'] as String?,
      isConfigured: (map['is_configured'] as int?) == 1,
      timeout: (map['timeout'] as int?) ?? 30,
      budgetTokens: (map['budget_tokens'] as int?) ?? 10000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 'default',
      'provider': provider,
      'api_key': apiKey,
      'model': model,
      'base_url': baseUrl,
      'is_configured': isConfigured ? 1 : 0,
      'timeout': timeout,
      'budget_tokens': budgetTokens,
    };
  }
}
