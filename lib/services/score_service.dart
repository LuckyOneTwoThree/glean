import 'dart:convert';
import '../models/models.dart';
import 'briefing_service.dart';
import 'database_service.dart';
import 'llm_service.dart';

/// 评分服务
/// 对应 PRD 接口 ScoreService
/// 支持本地规则引擎和 LLM 两种模式，预算超限自动降级
class ScoreService {
  final DatabaseService _db;
  final LLMService _llmService;

  ScoreService(this._db, this._llmService);

  /// 对文章进行评分
  Future<Score> scoreArticle(String articleId, String mode) async {
    final maps = await _db.query(
      'articles',
      where: 'id = ?',
      whereArgs: [articleId],
    );
    if (maps.isEmpty) throw Exception('文章不存在: $articleId');
    final article = Article.fromMap(maps.first);

    // 预算超限自动降级到本地模式
    String effectiveMode = mode;
    if (mode == 'quality') {
      final overBudget = await _llmService.isOverBudget();
      if (overBudget) {
        effectiveMode = 'economy';
      }
    }

    Score score;
    if (effectiveMode == 'quality') {
      score = await _scoreWithLLM(article);
    } else {
      // economy 和 hybrid 模式：本地规则评分
      score = await _scoreWithRules(article);
    }

    // mode 映射：aiMode(economy/quality/hybrid) → 评分模式(local/llm)
    final scoreModeForDb = effectiveMode == 'quality' ? 'llm' : 'local';

    // 保存评分记录
    try {
      await _db.insert('scores', score.toMap());
    } catch (_) {
      // 评分记录插入失败（如 ID 重复），不影响主流程
    }

    // 更新文章评分
    await _db.update(
      'articles',
      {
        'score_total': score.total,
        'score_credibility': score.credibility,
        'score_density': score.density,
        'score_mode': scoreModeForDb,
      },
      where: 'id = ?',
      whereArgs: [articleId],
    );

    return score;
  }

  /// 本地规则引擎评分
  /// 来源可信度(0-10)×0.5 + 信息密度(0-10)×0.5 = 总分0-10
  Future<Score> _scoreWithRules(Article article) async {
    // 来源可信度：从 Feed 表查询
    double credibility = 5.0; // 默认值
    try {
      final feedMaps = await _db.query(
        'feeds',
        where: 'url = ?',
        whereArgs: [article.sourceUrl],
      );
      if (feedMaps.isNotEmpty) {
        credibility = (feedMaps.first['credibility'] as num?)?.toDouble() ?? 5.0;
      }
    } catch (_) {}

    // 信息密度：基于规则打分（0-10）
    double density = 0;
    final content = article.content ?? article.summaryOne ?? '';
    if (content.length > 500) density += 2;
    if (content.length > 1500) density += 2;
    if (RegExp(r'\d+').hasMatch(content)) density += 1;
    if (RegExp(r'https?://').hasMatch(content)) density += 1;
    if (RegExp(r'<img|!\[').hasMatch(content)) density += 1;
    if (article.title.length > 10 && !RegExp(r'^(今日|本周|最新|重要)').hasMatch(article.title)) density += 1;

    // 命中关注领域 +2：从用户配置的关注领域关键词匹配
    if (await _matchesUserCategory(article)) density += 2;

    density = density.clamp(0, 10).toDouble();

    final total = credibility * 0.5 + density * 0.5;

    return Score(
      id: 's${DateTime.now().millisecondsSinceEpoch}_${article.id.hashCode.abs()}',
      articleId: article.id,
      mode: 'local',
      credibility: credibility,
      density: density,
      total: total,
      scoredAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 检查文章是否命中用户关注的领域
  Future<bool> _matchesUserCategory(Article article) async {
    try {
      final configMaps = await _db.query('user_config');
      if (configMaps.isEmpty) return false;
      final config = configMaps.first;
      final categoriesRaw = config['categories'];
      if (categoriesRaw == null) return false;

      // 解析用户关注的领域列表
      List<String> userCategories;
      if (categoriesRaw is String) {
        try {
          userCategories = List<String>.from(jsonDecode(categoriesRaw));
        } catch (_) {
          return false;
        }
      } else {
        return false;
      }
      if (userCategories.isEmpty) return false;

      // 先检查文章的 category 是否直接匹配
      if (article.category != null && userCategories.contains(article.category)) {
        return true;
      }

      // 用标题+内容匹配关注领域的关键词
      final text = '${article.title} ${article.content ?? ''}';
      for (final cat in userCategories) {
        final keywords = BriefingService.categoryKeywords[cat];
        if (keywords != null) {
          for (final keyword in keywords) {
            if (text.contains(keyword)) return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// LLM 评分
  Future<Score> _scoreWithLLM(Article article) async {
    try {
      final result = await _llmService.scoreArticle(article);
      return Score(
        id: 's${DateTime.now().millisecondsSinceEpoch}_${article.id.hashCode.abs()}',
        articleId: article.id,
        mode: 'llm',
        credibility: result['credibility'] as double,
        density: result['density'] as double,
        total: result['total'] as double,
        rawResponse: result['raw'] as String?,
        scoredAt: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // LLM 失败降级为本地模式
      return _scoreWithRules(article);
    }
  }
}
