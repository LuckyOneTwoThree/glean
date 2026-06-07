/// 评分记录模型
/// 对应 PRD Section 3.2.5 Score 表
class Score {
  final String id;
  final String articleId;
  final String mode; // "local" | "llm"
  final double credibility;
  final double density;
  final double total;
  final String? rawResponse;
  final String? actionTag;
  final int scoredAt;

  const Score({
    required this.id,
    required this.articleId,
    required this.mode,
    this.credibility = 0,
    this.density = 0,
    this.total = 0,
    this.rawResponse,
    this.actionTag,
    required this.scoredAt,
  });

  factory Score.fromMap(Map<String, dynamic> map) {
    return Score(
      id: map['id'] as String,
      articleId: map['article_id'] as String,
      mode: map['mode'] as String,
      credibility: (map['credibility'] as num?)?.toDouble() ?? 0,
      density: (map['density'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      rawResponse: map['raw_response'] as String?,
      actionTag: map['action_tag'] as String?,
      scoredAt: map['scored_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'article_id': articleId,
      'mode': mode,
      'credibility': credibility,
      'density': density,
      'total': total,
      'raw_response': rawResponse,
      'action_tag': actionTag,
      'scored_at': scoredAt,
    };
  }
}
