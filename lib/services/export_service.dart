import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import 'database_service.dart';

/// 数据导出服务
/// 对应 PRD 接口 ExportService
/// 全量导出为 ZIP 压缩包，单篇/简报导出支持分享
/// Markdown 导出对齐 PRD 格式（含评分徽章、分类分组、时间格式化）
class ExportService {
  final DatabaseService _db;

  ExportService(this._db);

  /// 评分徽章映射
  static String _scoreBadge(double score) {
    if (score >= 9.0) return '★★★';
    if (score >= 7.0) return '★★☆';
    if (score >= 5.0) return '★☆☆';
    return '☆☆☆';
  }

  /// 格式化时间戳
  static String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '未知时间';
    return DateFormat('yyyy-MM-dd HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }

  /// 导出单篇文章
  Future<String> exportArticle(String articleId, String format) async {
    final maps = await _db.query(
      'articles',
      where: 'id = ?',
      whereArgs: [articleId],
    );
    if (maps.isEmpty) throw Exception('文章不存在');
    final article = Article.fromMap(maps.first);

    final content = format == 'json'
        ? _articleToJson(article)
        : _articleToMarkdown(article);

    return _saveFile(content, 'article-$articleId', format);
  }

  /// 导出简报
  Future<String> exportBriefing(String briefingId, String format) async {
    final briefingMaps = await _db.query(
      'briefings',
      where: 'id = ?',
      whereArgs: [briefingId],
    );
    if (briefingMaps.isEmpty) throw Exception('简报不存在');
    final briefing = Briefing.fromMap(briefingMaps.first);

    final articleMaps = await _db.query(
      'articles',
      where: 'briefing_id = ?',
      whereArgs: [briefingId],
      orderBy: 'score_total DESC',
    );
    final articles = articleMaps.map((m) => Article.fromMap(m)).toList();

    final content = format == 'json'
        ? _briefingToJson(briefing, articles)
        : _briefingToMarkdown(briefing, articles);

    return _saveFile(content, 'briefing-${briefing.date}', format);
  }

  /// 全量导出为 ZIP 压缩包
  Future<String> exportAll(String format) async {
    final articles = await _db.query('articles', orderBy: 'score_total DESC');
    final briefings = await _db.query('briefings', orderBy: 'date DESC');
    final feeds = await _db.query('feeds');
    final scores = await _db.query('scores', orderBy: 'scored_at DESC');
    final logs = await _db.query('execution_logs');

    final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final zipFilename = 'glean-backup-$timestamp';

    final archive = Archive();

    // 1. 导出元信息
    final meta = JsonEncoder.withIndent('  ').convert({
      'app': '拾光 / Glean',
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'format': format,
      'stats': {
        'articles': articles.length,
        'briefings': briefings.length,
        'feeds': feeds.length,
        'scores': scores.length,
        'logs': logs.length,
      },
    });
    archive.addFile(ArchiveFile.string('meta.json', meta));

    // 2. 文章
    if (format == 'json') {
      final content = JsonEncoder.withIndent('  ').convert(articles);
      archive.addFile(ArchiveFile.string('articles.json', content));
    } else {
      final content = _articlesToMarkdown(
        articles.map((m) => Article.fromMap(m)).toList(),
        title: '拾光 / Glean 文章导出',
      );
      archive.addFile(ArchiveFile.string('articles.md', content));
    }

    // 3. 简报
    final briefingsJson = JsonEncoder.withIndent('  ').convert(briefings);
    archive.addFile(ArchiveFile.string('briefings.json', briefingsJson));

    // 4. 数据源
    final feedsJson = JsonEncoder.withIndent('  ').convert(feeds);
    archive.addFile(ArchiveFile.string('feeds.json', feedsJson));

    // 5. 评分记录
    final scoresJson = JsonEncoder.withIndent('  ').convert(scores);
    archive.addFile(ArchiveFile.string('scores.json', scoresJson));

    // 6. 执行日志
    final logsJson = JsonEncoder.withIndent('  ').convert(logs);
    archive.addFile(ArchiveFile.string('execution_logs.json', logsJson));

    // 编码为 ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('ZIP 编码失败');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$zipFilename.zip');
    await file.writeAsBytes(Uint8List.fromList(zipData));
    return file.path;
  }

  /// 分享单篇文章
  Future<void> shareArticle(String articleId, String format) async {
    final filePath = await exportArticle(articleId, format);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '拾光 - 文章分享',
    );
  }

  /// 分享简报
  Future<void> shareBriefing(String briefingId, String format) async {
    final filePath = await exportBriefing(briefingId, format);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '拾光 - 简报分享',
    );
  }

  /// 分享全量导出
  Future<void> shareAll(String format) async {
    final filePath = await exportAll(format);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '拾光 - 数据备份',
    );
  }

  // ==================== 格式化方法 ====================

  String _articleToJson(Article article) {
    return JsonEncoder.withIndent('  ').convert({
      'id': article.id,
      'title': article.title,
      'link': article.url,
      'source': article.sourceName,
      'published_at': _formatTimestamp(article.publishedAt),
      'summary_one_line': article.summaryOne,
      'summary_bullets': article.summaryPoints,
      'score': {
        'overall': article.scoreTotal,
        'credibility': article.scoreCredibility,
        'density': article.scoreDensity,
        'badge': _scoreBadge(article.scoreTotal),
      },
      'category': article.category,
      'content': article.content,
      'exported_at': DateTime.now().toIso8601String(),
    });
  }

  String _articleToMarkdown(Article article) {
    final buffer = StringBuffer();
    buffer.writeln('# ${article.title}');
    buffer.writeln();
    buffer.writeln('> ${_scoreBadge(article.scoreTotal)} ${article.scoreTotal.toStringAsFixed(1)} | 来源: ${article.sourceName} | ${_formatTimestamp(article.publishedAt)}');
    if (article.category != null) {
      buffer.writeln('> 分类: ${article.category}');
    }
    buffer.writeln();
    if (article.summaryOne != null && article.summaryOne!.isNotEmpty) {
      buffer.writeln('**${article.summaryOne}**');
      buffer.writeln();
    }
    if (article.summaryPoints.isNotEmpty) {
      for (final point in article.summaryPoints) {
        buffer.writeln('- $point');
      }
      buffer.writeln();
    }
    buffer.writeln('[阅读原文](${article.url})');
    return buffer.toString();
  }

  /// 多篇文章转 Markdown（按分类分组）
  String _articlesToMarkdown(List<Article> articles, {String? title}) {
    final buffer = StringBuffer();

    if (title != null) {
      buffer.writeln('# $title');
      buffer.writeln();
      buffer.writeln('> 导出时间: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      buffer.writeln('> 文章总数: ${articles.length}');
      buffer.writeln();
    }

    // 按分类分组
    final grouped = <String, List<Article>>{};
    for (final article in articles) {
      final category = article.category ?? '未分类';
      grouped.putIfAbsent(category, () => []).add(article);
    }

    for (final entry in grouped.entries) {
      buffer.writeln('## ${entry.key}');
      buffer.writeln();

      for (final article in entry.value) {
        buffer.writeln('### ${article.title}');
        buffer.writeln();
        buffer.writeln('> ${_scoreBadge(article.scoreTotal)} ${article.scoreTotal.toStringAsFixed(1)} | ${article.sourceName} | ${_formatTimestamp(article.publishedAt)}');
        buffer.writeln();
        if (article.summaryOne != null && article.summaryOne!.isNotEmpty) {
          buffer.writeln('${article.summaryOne}');
          buffer.writeln();
        }
        if (article.summaryPoints.isNotEmpty) {
          for (final point in article.summaryPoints) {
            buffer.writeln('- $point');
          }
          buffer.writeln();
        }
        buffer.writeln('[阅读原文](${article.url})');
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _briefingToJson(Briefing briefing, List<Article> articles) {
    return JsonEncoder.withIndent('  ').convert({
      'briefing': {
        'id': briefing.id,
        'date': briefing.date,
        'article_count': briefing.articleCount,
        'ai_insight': briefing.aiInsight,
        'total_fetched': briefing.totalFetched,
        'domestic_count': briefing.domesticCount,
        'international_count': briefing.internationalCount,
      },
      'articles': articles.map((a) => {
        'title': a.title,
        'link': a.url,
        'source': a.sourceName,
        'score': {
          'overall': a.scoreTotal,
          'badge': _scoreBadge(a.scoreTotal),
        },
        'summary_one_line': a.summaryOne,
        'summary_bullets': a.summaryPoints,
        'category': a.category,
      }).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    });
  }

  String _briefingToMarkdown(Briefing briefing, List<Article> articles) {
    final buffer = StringBuffer();
    buffer.writeln('# 拾光日报 · ${briefing.date}');
    buffer.writeln();
    buffer.writeln('> 今日精选 ${articles.length} 条 | 采集 ${briefing.totalFetched} 条 | 国内 ${briefing.domesticCount} / 国际 ${briefing.internationalCount}');
    buffer.writeln();

    if (briefing.aiInsight != null && briefing.aiInsight!.isNotEmpty) {
      buffer.writeln('## AI Insight');
      buffer.writeln();
      buffer.writeln('> ${briefing.aiInsight}');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    // 按分类分组
    final grouped = <String, List<Article>>{};
    for (final article in articles) {
      final category = article.category ?? '未分类';
      grouped.putIfAbsent(category, () => []).add(article);
    }

    for (final entry in grouped.entries) {
      buffer.writeln('## ${entry.key}');
      buffer.writeln();

      for (final article in entry.value) {
        buffer.writeln('### ${article.title}');
        buffer.writeln();
        buffer.writeln('> ${_scoreBadge(article.scoreTotal)} ${article.scoreTotal.toStringAsFixed(1)} | ${article.sourceName} | ${_formatTimestamp(article.publishedAt)}');
        buffer.writeln();
        if (article.summaryOne != null && article.summaryOne!.isNotEmpty) {
          buffer.writeln('${article.summaryOne}');
          buffer.writeln();
        }
        if (article.summaryPoints.isNotEmpty) {
          for (final point in article.summaryPoints) {
            buffer.writeln('- $point');
          }
          buffer.writeln();
        }
        buffer.writeln('[阅读原文](${article.url})');
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  // ==================== 文件保存 ====================

  Future<String> _saveFile(String content, String filename, String format) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = format == 'json' ? 'json' : 'md';
    final file = File('${dir.path}/$filename.$ext');
    await file.writeAsString(content);
    return file.path;
  }
}
