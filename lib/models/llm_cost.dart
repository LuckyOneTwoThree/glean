/// LLM 调用成本记录模型
/// 对应 llm_costs 表
class LLMCost {
  final String id;
  final String operation; // "score" | "summarize" | "insight"
  final String model;
  final int inputTokens;
  final int outputTokens;
  final int createdAt;

  const LLMCost({
    required this.id,
    required this.operation,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.createdAt,
  });

  int get totalTokens => inputTokens + outputTokens;

  factory LLMCost.fromMap(Map<String, dynamic> map) {
    return LLMCost(
      id: map['id'] as String,
      operation: map['operation'] as String,
      model: map['model'] as String,
      inputTokens: map['input_tokens'] as int,
      outputTokens: map['output_tokens'] as int,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation': operation,
      'model': model,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'created_at': createdAt,
    };
  }
}
