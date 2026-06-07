import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../utils/html_utils.dart';
import 'database_service.dart';

/// LLM API 调用服务
/// 对应 PRD 接口 LLMService
/// 支持：评分+摘要合并Prompt、成本记录、预算检查、超时配置
class LLMService {
  final DatabaseService _db;
  final Dio _dio = Dio();

  LLMService(this._db);

  /// 获取当前 LLM 配置
  Future<LLMConfig> getConfig() async {
    final maps = await _db.query('llm_config', where: 'id = ?', whereArgs: ['default']);
    if (maps.isEmpty) return const LLMConfig();
    return LLMConfig.fromMap(maps.first);
  }

  /// 保存 LLM 配置
  Future<void> saveConfig(LLMConfig config) async {
    final existing = await _db.query('llm_config', where: 'id = ?', whereArgs: ['default']);
    if (existing.isEmpty) {
      await _db.insert('llm_config', config.toMap());
    } else {
      await _db.update('llm_config', config.toMap(), where: 'id = ?', whereArgs: ['default']);
    }
  }

  /// 测试连通性
  Future<ConnectionTestResult> testConnection(LLMConfig config) async {
    final startTime = DateTime.now();
    try {
      final baseUrl = config.baseUrl ?? _getDefaultBaseUrl(config.provider);
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          sendTimeout: Duration(seconds: config.timeout),
          receiveTimeout: Duration(seconds: config.timeout),
        ),
        data: {
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'max_tokens': 5,
        },
      );

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      return ConnectionTestResult(
        success: response.statusCode == 200,
        latency: latency,
      );
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        latency: DateTime.now().difference(startTime).inMilliseconds,
        errorMessage: e.toString(),
      );
    }
  }

  /// 检查是否超预算
  Future<bool> isOverBudget() async {
    final config = await getConfig();
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1)
        .millisecondsSinceEpoch;
    final costs = await _db.query(
      'llm_costs',
      where: 'created_at >= ?',
      whereArgs: [monthStart],
    );
    final totalTokens = costs.fold<int>(0, (sum, c) =>
        sum + (c['input_tokens'] as int? ?? 0) + (c['output_tokens'] as int? ?? 0));
    return totalTokens >= config.budgetTokens;
  }

  /// 获取本月成本统计
  Future<MonthlyCostStats> getMonthlyCostStats() async {
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1)
        .millisecondsSinceEpoch;
    final costs = await _db.query(
      'llm_costs',
      where: 'created_at >= ?',
      whereArgs: [monthStart],
    );

    int totalInput = 0;
    int totalOutput = 0;
    final byOperation = <String, int>{};

    for (final c in costs) {
      final input = c['input_tokens'] as int? ?? 0;
      final output = c['output_tokens'] as int? ?? 0;
      totalInput += input;
      totalOutput += output;
      final op = c['operation'] as String? ?? 'unknown';
      byOperation[op] = (byOperation[op] ?? 0) + input + output;
    }

    final config = await getConfig();
    return MonthlyCostStats(
      totalInputTokens: totalInput,
      totalOutputTokens: totalOutput,
      budgetTokens: config.budgetTokens,
      byOperation: byOperation,
    );
  }

  /// 合并评分+摘要+行动建议的 Prompt（对齐 PRD 8.4）
  Future<ScoreAndSummaryResult> scoreAndSummarize(Article article) async {
    final config = await getConfig();
    final baseUrl = config.baseUrl ?? _getDefaultBaseUrl(config.provider);

    // 清洗 HTML，避免浪费 token
    final cleanContent = _stripHtml(article.content);
    final contentPreview = cleanContent.isNotEmpty
        ? cleanContent.substring(0, min(cleanContent.length, 2000))
        : '无全文';
    final cleanSummary = _stripHtml(article.summaryOne);

    final prompt = '''你是一个资讯质量评估和摘要生成专家。

请对以下资讯完成三项任务：

【资讯标题】${article.title}
【资讯来源】${article.sourceName}
【资讯摘要】${cleanSummary.isNotEmpty ? cleanSummary : "无"}
【资讯正文】$contentPreview

任务 1：质量评分
从以下两个维度评分（0-10 整数）：
- 来源可信度：该来源在行业内的权威性和可靠性
- 信息密度：内容的信息量、深度、是否有数据支撑

任务 2：摘要生成
- 一句话摘要（不超过 80 字，概括核心信息）
- 三个要点（每个不超过 50 字）

任务 3：行动建议（仅当综合评分 ≥ 7 时）
- 行动标签：立即关注 / 深入阅读 / 观望等待 / 了解即可
- 一句话理由

严格按以下 JSON 格式返回：
{
  "score": {
    "source_credibility": 8,
    "information_density": 7,
    "overall": 7.5,
    "reason": "评分理由"
  },
  "summary": {
    "one_line": "一句话摘要",
    "bullets": ["要点1", "要点2", "要点3"]
  },
  "action": {
    "tag": "深入阅读",
    "reason": "行动理由"
  }
}''';

    final startTime = DateTime.now();
    final response = await _dio.post(
      '$baseUrl/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        sendTimeout: Duration(seconds: config.timeout),
        receiveTimeout: Duration(seconds: config.timeout),
      ),
      data: {
        'model': config.model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.1,
        'response_format': {'type': 'json_object'},
      },
    );

    // 记录成本
    await _recordCost(
      operation: 'score_and_summary',
      responseData: response.data,
    );

    // 解析 JSON 响应
    final choices = response.data['choices'] as List<dynamic>?;
    final message = choices?[0]['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('LLM 返回内容为空');
    }
    final json = jsonDecode(content) as Map<String, dynamic>;

    final scoreJson = json['score'] as Map<String, dynamic>? ?? {};
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final actionJson = json['action'] as Map<String, dynamic>? ?? {};

    return ScoreAndSummaryResult(
      credibility: (scoreJson['source_credibility'] ?? scoreJson['credibility'] ?? 5).toDouble(),
      density: (scoreJson['information_density'] ?? scoreJson['density'] ?? 5).toDouble(),
      total: (scoreJson['overall'] ?? scoreJson['total'] ?? 5).toDouble(),
      scoreReason: scoreJson['reason'] as String?,
      oneLine: summaryJson['one_line'] as String? ?? summaryJson['oneLine'] as String? ?? '',
      bullets: (summaryJson['bullets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      actionTag: actionJson['tag'] as String?,
      actionReason: actionJson['reason'] as String?,
      rawResponse: content,
      latencyMs: DateTime.now().difference(startTime).inMilliseconds,
    );
  }

  /// 批量评分+摘要（每批最多5条）
  Future<List<ScoreAndSummaryResult>> batchScoreAndSummarize(
    List<Article> articles,
  ) async {
    final results = <ScoreAndSummaryResult>[];
    for (var i = 0; i < articles.length; i += 5) {
      final batch = articles.sublist(i, min(i + 5, articles.length));
      final batchResults = await Future.wait(
        batch.map((a) => scoreAndSummarize(a).catchError((e) => ScoreAndSummaryResult.fallback(a))),
      );
      results.addAll(batchResults);
    }
    return results;
  }

  /// 调用 LLM 评分（单独评分，保留向后兼容）
  Future<Map<String, dynamic>> scoreArticle(Article article) async {
    try {
      final result = await scoreAndSummarize(article);
      return {
        'credibility': result.credibility,
        'density': result.density,
        'total': result.total,
        'reason': result.scoreReason,
        'action_tag': result.actionTag,
        'raw': result.rawResponse,
      };
    } catch (e) {
      return {
        'credibility': 5.0,
        'density': 5.0,
        'total': 5.0,
        'raw': e.toString(),
      };
    }
  }

  /// 调用 LLM 生成摘要（单独摘要，保留向后兼容）
  Future<SummaryResult> summarize(Article article) async {
    try {
      final result = await scoreAndSummarize(article);
      return SummaryResult(
        oneLine: result.oneLine,
        points: result.bullets,
      );
    } catch (e) {
      return SummaryResult(
        oneLine: article.summaryOne ?? '',
        points: article.summaryPoints,
      );
    }
  }

  /// 记录 LLM 调用成本
  Future<void> _recordCost({
    required String operation,
    required Map<String, dynamic> responseData,
  }) async {
    final usage = responseData['usage'] as Map<String, dynamic>?;
    if (usage == null) return;

    final config = await getConfig();
    final inputTokens = usage['prompt_tokens'] as int? ?? 0;
    final outputTokens = usage['completion_tokens'] as int? ?? 0;

    await _db.insert('llm_costs', {
      'id': 'c${DateTime.now().millisecondsSinceEpoch}_${operation.hashCode.abs()}',
      'operation': operation,
      'model': config.model,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  String _getDefaultBaseUrl(String provider) {
    switch (provider) {
      case 'openai':
        return 'https://api.openai.com/v1';
      case 'deepseek':
        return 'https://api.deepseek.com/v1';
      case 'mimo':
      default:
        return 'https://token-plan-cn.xiaomimimo.com/v1';
    }
  }

  /// 剥离 HTML 标签，清理为纯文本
  static String _stripHtml(String? html) {
    return HtmlUtils.stripHtml(html);
  }
}

class ConnectionTestResult {
  final bool success;
  final int latency;
  final String? errorMessage;

  const ConnectionTestResult({
    required this.success,
    required this.latency,
    this.errorMessage,
  });
}

class SummaryResult {
  final String oneLine;
  final List<String> points;

  const SummaryResult({required this.oneLine, required this.points});
}

/// 合并评分+摘要+行动建议的结果
class ScoreAndSummaryResult {
  final double credibility;
  final double density;
  final double total;
  final String? scoreReason;
  final String oneLine;
  final List<String> bullets;
  final String? actionTag;
  final String? actionReason;
  final String? rawResponse;
  final int latencyMs;

  const ScoreAndSummaryResult({
    required this.credibility,
    required this.density,
    required this.total,
    this.scoreReason,
    required this.oneLine,
    required this.bullets,
    this.actionTag,
    this.actionReason,
    this.rawResponse,
    this.latencyMs = 0,
  });

  /// LLM 调用失败时的降级结果
  factory ScoreAndSummaryResult.fallback(Article article) {
    return ScoreAndSummaryResult(
      credibility: 5.0,
      density: 5.0,
      total: 5.0,
      oneLine: article.summaryOne ?? article.title,
      bullets: article.summaryPoints.isNotEmpty ? article.summaryPoints : ['暂无要点'],
    );
  }
}

/// 月度成本统计
class MonthlyCostStats {
  final int totalInputTokens;
  final int totalOutputTokens;
  final int budgetTokens;
  final Map<String, int> byOperation;

  const MonthlyCostStats({
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.budgetTokens,
    required this.byOperation,
  });

  int get totalTokens => totalInputTokens + totalOutputTokens;
  double get usageRatio => budgetTokens > 0 ? totalTokens / budgetTokens : 0;
  bool get isOverBudget => totalTokens >= budgetTokens;
}
