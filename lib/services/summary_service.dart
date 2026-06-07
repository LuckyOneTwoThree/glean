import 'dart:convert';
import 'dart:math';
import '../models/models.dart';
import '../utils/html_utils.dart';
import 'database_service.dart';
import 'llm_service.dart';

/// 摘要生成服务
/// 对应 PRD 接口 SummaryService
/// 支持预算超限自动降级
class SummaryService {
  final DatabaseService _db;
  final LLMService _llmService;

  SummaryService(this._db, this._llmService);

  /// 生成摘要
  /// mode: "economy" | "quality" | "hybrid"
  Future<void> summarize(String articleId, String mode) async {
    final maps = await _db.query(
      'articles',
      where: 'id = ?',
      whereArgs: [articleId],
    );
    if (maps.isEmpty) return;
    final article = Article.fromMap(maps.first);

    // 预算超限自动降级到本地模式
    String effectiveMode = mode;
    if (mode == 'quality' || mode == 'hybrid') {
      final overBudget = await _llmService.isOverBudget();
      if (overBudget) {
        effectiveMode = 'economy';
      }
    }

    String? summaryOne;
    List<String> summaryPoints;

    if (effectiveMode == 'economy') {
      // 省钱模式：本地抽取式摘要
      summaryOne = _extractOneLine(article);
      summaryPoints = _extractPointsTextRank(article);
    } else {
      // quality 和 hybrid 模式：LLM 生成式摘要
      try {
        final result = await _llmService.summarize(article);
        summaryOne = result.oneLine;
        summaryPoints = result.points;
      } catch (e) {
        // LLM 失败降级到本地
        summaryOne = _extractOneLine(article);
        summaryPoints = _extractPointsTextRank(article);
      }
    }

    // 更新文章摘要
    await _db.update(
      'articles',
      {
        'summary_one': summaryOne,
        'summary_points': jsonEncode(summaryPoints),
      },
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }

  /// 抽取一句话摘要（取 meta description 或首句）
  String _extractOneLine(Article article) {
    final summary = _cleanText(article.summaryOne);
    if (summary.isNotEmpty) {
      return summary.length <= 60 ? summary : '${summary.substring(0, 57)}...';
    }
    final content = _cleanText(article.content);
    if (content.isEmpty) return article.title;
    final firstSentence = content.split(RegExp(r'[。！？.!?\n]')).first;
    if (firstSentence.length <= 60) return firstSentence;
    return '${firstSentence.substring(0, 57)}...';
  }

  /// TextRank 算法抽取三要点
  /// 基于句子间相似度构建图，迭代计算句子权重，取 Top-3
  /// 注意：此方法仅在 economy 模式或 LLM 降级时调用，已有要点可直接复用
  List<String> _extractPointsTextRank(Article article) {
    if (article.summaryPoints.isNotEmpty) return article.summaryPoints;
    final content = _cleanText(article.content);
    if (content.isEmpty) return ['暂无要点'];

    // 1. 分句：按中英文标点分句，过滤过短句子
    final sentences = content
        .split(RegExp(r'[。！？；.!?;\n]'))
        .map((s) => s.trim())
        .where((s) => s.length > 8)
        .toList();

    if (sentences.isEmpty) return ['暂无要点'];
    if (sentences.length <= 3) {
      return sentences.map((s) => s.length > 50 ? '${s.substring(0, 47)}...' : s).take(3).toList();
    }

    // 2. 对每个句子分词（中文2-gram + 英文单词）
    final tokenized = sentences.map(_tokenize).toList();

    // 3. 构建句子相似度矩阵
    final n = sentences.length;
    final scores = List<double>.filled(n, 1.0);
    final graph = List.generate(n, (_) => List<double>.filled(n, 0.0));

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final sim = _sentenceSimilarity(tokenized[i], tokenized[j]);
        graph[i][j] = sim;
        graph[j][i] = sim;
      }
    }

    // 4. TextRank 迭代（最多30轮，收敛阈值0.0001）
    final d = 0.85; // 阻尼系数
    for (int iter = 0; iter < 30; iter++) {
      double maxDiff = 0;
      final newScores = List<double>.filled(n, 0.0);

      for (int i = 0; i < n; i++) {
        double sum = 0;
        for (int j = 0; j < n; j++) {
          if (i == j) continue;
          final outWeight = graph[j].reduce((a, b) => a + b);
          if (outWeight > 0) {
            sum += graph[j][i] / outWeight * scores[j];
          }
        }
        newScores[i] = (1 - d) + d * sum;
        maxDiff = max(maxDiff, (newScores[i] - scores[i]).abs());
      }

      for (int i = 0; i < n; i++) {
        scores[i] = newScores[i];
      }
      if (maxDiff < 0.0001) break;
    }

    // 5. 按分数排序取 Top-3，再按原文顺序排列
    final indexed = List.generate(n, (i) => MapEntry(i, scores[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));
    final topIndices = indexed.take(3).map((e) => e.key).toList()..sort();

    return topIndices.map((i) {
      var s = sentences[i];
      if (s.length > 50) s = '${s.substring(0, 47)}...';
      return s;
    }).toList();
  }

  /// 句子分词：中文2-gram + 英文单词
  Set<String> _tokenize(String text) {
    final tokens = <String>{};
    final englishWords = RegExp(r'[a-zA-Z]+');
    for (final match in englishWords.allMatches(text)) {
      tokens.add(match.group(0)!.toLowerCase());
    }

    // 中文2-gram
    final chineseChars = RegExp(r'[\u4e00-\u9fff]');
    final chars = chineseChars.allMatches(text).map((m) => m.group(0)!).toList();
    for (int i = 0; i < chars.length - 1; i++) {
      tokens.add('${chars[i]}${chars[i + 1]}');
    }

    return tokens;
  }

  /// 句子相似度（基于词重叠的 Jaccard 系数）
  double _sentenceSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union > 0 ? intersection / union : 0.0;
  }

  /// 清洗文本：剥离 HTML 标签、解码实体、压缩空白
  /// 防止数据库中已有未清洗的历史数据
  String _cleanText(String? text) {
    return HtmlUtils.stripHtml(text);
  }
}
