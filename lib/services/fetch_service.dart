import 'dart:math';

import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../models/models.dart';
import '../utils/html_utils.dart';
import 'database_service.dart';
import 'feed_service.dart';

/// 采集服务
/// 对应 PRD 接口 FetchService
/// 含执行日志记录
class FetchService {
  final DatabaseService _db;
  final FeedService _feedService;
  final Dio _dio;

  FetchService(this._db, this._feedService)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'User-Agent': 'Glean/1.0 (RSS Reader)',
          },
        ));

  /// 执行采集（分批并发，每批5个源）
  Future<FetchResult> runFetch() async {
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    final feeds = await _feedService.getEnabledFeeds();
    int fetched = 0;
    int deduped = 0;
    int inserted = 0;
    int errors = 0;

    // 分批并发，每批5个
    for (var i = 0; i < feeds.length; i += 5) {
      final batch = feeds.sublist(i, min(i + 5, feeds.length));
      final batchResults = await Future.wait(
        batch.map((feed) => _fetchFromFeedSafe(feed)),
      );

      for (var j = 0; j < batch.length; j++) {
        final feed = batch[j];
        final articles = batchResults[j];

        if (articles.isEmpty && feed.fetchErrorCount > 0) {
          errors++;
        }

        fetched += articles.length;

        for (final article in articles) {
          final isDup = await _checkDuplicate(
            article.title,
            article.url,
            sourceUrl: article.sourceUrl,
            sourceCredibility: feed.credibility,
          );
          if (isDup) {
            deduped++;
          } else {
            try {
              await _db.insert('articles', article.toMap());
              inserted++;
            } catch (e) {
              // 插入失败（如 UNIQUE 约束冲突），视为去重
              deduped++;
            }
          }
        }

        await _feedService.updateLastFetched(feed.id);
      }
    }

    // 记录采集执行日志
    final completedAt = DateTime.now().millisecondsSinceEpoch;
    await _logExecution(
      taskType: 'fetch',
      status: errors == feeds.length ? 'error' : 'success',
      startedAt: startedAt,
      completedAt: completedAt,
      label: '采集 ${feeds.length} 个源，获取 ${fetched} 条，新增 ${inserted} 条，去重 ${deduped} 条',
      errorMessage: errors > 0 ? '$errors 个源采集失败' : null,
    );

    return FetchResult(fetched: fetched, deduped: deduped, inserted: inserted);
  }

  /// 带重试的采集（最多3次）
  Future<List<Article>> _fetchFromFeedSafe(Feed feed, {int retryCount = 0}) async {
    try {
      return await _fetchFromFeed(feed);
    } catch (e) {
      if (retryCount < 2) {
        // 重试间隔：5分钟、15分钟（PRD 4.1: 5/15/30 分钟递增）
        await Future.delayed(Duration(minutes: [5, 15][retryCount]));
        return _fetchFromFeedSafe(feed, retryCount: retryCount + 1);
      }
      // 3次失败，更新错误计数
      final newErrorCount = feed.fetchErrorCount + 1;
      await _feedService.updateLastFetched(feed.id, errorCount: newErrorCount);
      // 连续3次失败标记error
      if (newErrorCount >= 3) {
        await _feedService.updateStatus(feed.id, 'error');
      }
      return [];
    }
  }

  /// 从 Feed 拉取文章（RSS 2.0 / Atom 1.0 解析）
  Future<List<Article>> _fetchFromFeed(Feed feed) async {
    final response = await _dio.get<String>(
      feed.url,
      options: Options(responseType: ResponseType.plain),
    );
    if (response.data == null || response.data!.isEmpty) return [];

    // 检查返回内容是否为 XML（排除 HTML 响应）
    final data = response.data!.trim();
    if (!data.startsWith('<?xml') && !data.startsWith('<rss') && !data.startsWith('<feed')) {
      // 返回的不是 RSS/Atom XML，可能是 HTML 页面（URL 已失效）
      return [];
    }

    final items = _parseRssXml(data);
    final now = DateTime.now().millisecondsSinceEpoch;

    return items
        .map((item) {
          // content 优先用 content:encoded，为空则用 description
          final rawContent = (item.content?.isNotEmpty == true) ? item.content! : item.description;
          final cleanContent = _stripHtml(rawContent);
          // summaryOne 取 description 的首句，截断60字符
          final cleanDesc = _stripHtml(item.description);
          String? summaryOne;
          if (cleanDesc.isNotEmpty) {
            final firstSentence = cleanDesc.split(RegExp(r'[。！？.!?\n]')).first;
            summaryOne = firstSentence.length <= 60 ? firstSentence : '${firstSentence.substring(0, 57)}...';
          }
          return Article(
            id: 'a${now}_${item.link.hashCode.abs()}',
            title: _stripHtml(item.title),
            url: item.link,
            content: cleanContent,
            summaryOne: summaryOne,
            sourceName: feed.name,
            sourceUrl: feed.url,
            category: feed.category,
            publishedAt: item.pubDate ?? now,
            fetchedAt: now,
            scoreCredibility: feed.credibility / 2,
          );
        })
        .where((a) => a.url.isNotEmpty)
        .toList();
  }

  /// 剥离 HTML 标签，清理为纯文本
  /// 处理：HTML标签 → 换行 → 实体解码 → 空白压缩
  static String _stripHtml(String? html) {
    return HtmlUtils.stripHtml(html);
  }

  /// 解析 RSS XML（支持 RSS 2.0 和 Atom 1.0）
  List<_RssItem> _parseRssXml(String xmlStr) {
    final document = XmlDocument.parse(xmlStr);
    final items = <_RssItem>[];

    // RSS 2.0: <rss><channel><item>
    final rssItems = document.findAllElements('item');
    if (rssItems.isNotEmpty) {
      for (final item in rssItems) {
        final contentEncoded = _getElementText(item, 'content:encoded');
        final desc = _getElementText(item, 'description');
        items.add(_RssItem(
          title: _getElementText(item, 'title'),
          link: _getElementText(item, 'link'),
          description: desc,
          content: contentEncoded.isNotEmpty ? contentEncoded : (desc.isNotEmpty ? desc : null),
          pubDate: _parseDate(_getElementText(item, 'pubDate')),
          author: _getElementText(item, 'dc:creator') ??
              _getElementText(item, 'author'),
        ));
      }
      return items;
    }

    // Atom 1.0: <feed><entry>
    final atomEntries = document.findAllElements('entry');
    if (atomEntries.isNotEmpty) {
      for (final entry in atomEntries) {
        final linkElements = entry.findElements('link');
        String link = '';
        if (linkElements.isNotEmpty) {
          final altLink = linkElements.firstWhere(
            (el) => el.getAttribute('rel') == 'alternate',
            orElse: () => linkElements.first,
          );
          link = altLink.getAttribute('href') ?? '';
        }
        final atomSummary = _getElementText(entry, 'summary');
        final atomContent = _getElementText(entry, 'content');
        items.add(_RssItem(
          title: _getElementText(entry, 'title'),
          link: link,
          description: atomSummary,
          content: atomContent.isNotEmpty ? atomContent : (atomSummary.isNotEmpty ? atomSummary : null),
          pubDate: _parseDate(
            _getElementText(entry, 'published') ??
                _getElementText(entry, 'updated'),
          ),
          author: _getElementText(entry, 'author/name'),
        ));
      }
      return items;
    }

    // RDF (RSS 1.0): <rdf:RDF><item>
    // RDF 的 item 元素可能带命名空间，用 local name 匹配
    for (final element in document.rootElement.children) {
      if (element is XmlElement && element.name.local == 'item') {
        final desc = _getElementText(element, 'description');
        items.add(_RssItem(
          title: _getElementText(element, 'title'),
          link: _getElementText(element, 'link'),
          description: desc,
          content: desc.isNotEmpty ? desc : null,
          pubDate: _parseDate(
            _getElementText(element, 'dc:date') ??
                _getElementText(element, 'date'),
          ),
          author: _getElementText(element, 'dc:creator'),
        ));
      }
    }

    return items;
  }

  /// 获取 XML 元素文本内容
  String _getElementText(XmlElement parent, String tagName) {
    // 处理命名空间前缀（如 content:encoded）
    if (tagName.contains(':')) {
      final parts = tagName.split(':');
      final localName = parts[1];
      // 尝试带命名空间和不带命名空间两种方式
      for (final child in parent.children) {
        if (child is XmlElement) {
          final name = child.name;
          if (name.local == localName) {
            return child.innerText.trim();
          }
        }
      }
    }

    final elements = parent.findElements(tagName);
    if (elements.isEmpty) return '';
    return elements.first.innerText.trim();
  }

  /// 解析日期字符串为毫秒时间戳
  int? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr)?.millisecondsSinceEpoch;
  }

  /// 去重检查
  /// 对应 PRD 接口 DedupService.checkDuplicate
  Future<bool> _checkDuplicate(String title, String url, {String? sourceUrl, double? sourceCredibility}) async {
    // URL 精确匹配
    final urlMatch = await _db.query(
      'articles',
      where: 'url = ?',
      whereArgs: [url],
    );
    if (urlMatch.isNotEmpty) return true;

    // 标题相似度检查（词级Jaccard + 编辑距离，综合公式，阈值0.75）
    // 只比较最近7天的文章，最多500条
    final weekAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final recentArticles = await _db.query(
      'articles',
      where: 'fetched_at >= ?',
      whereArgs: [weekAgo],
      orderBy: 'fetched_at DESC',
      limit: 500,
    );
    for (final map in recentArticles) {
      final existingTitle = map['title'] as String;
      final jaccard = _wordJaccardSimilarity(title, existingTitle);
      final editSim = _editDistanceSimilarity(title, existingTitle);
      final combined = 0.6 * jaccard + 0.4 * editSim;
      if (combined >= 0.75) {
        // 发现相似文章，比较来源可信度
        // 如果新文章来源可信度更高，删除旧文章让新文章入库
        if (sourceCredibility != null && sourceUrl != null) {
          final existingSourceUrl = map['source_url'] as String? ?? '';
          double existingCred = 5.0;
          if (existingSourceUrl.isNotEmpty) {
            final feedMaps = await _db.query('feeds', where: 'url = ?', whereArgs: [existingSourceUrl]);
            existingCred = (feedMaps.isNotEmpty ? (feedMaps.first['credibility'] as num?)?.toDouble() : null) ?? 5.0;
          }
          if (sourceCredibility > existingCred) {
            // 新来源可信度更高，删除旧文章
            await _db.delete('articles', where: 'id = ?', whereArgs: [map['id']]);
            return false; // 允许新文章入库
          }
        }
        return true;
      }
    }

    return false;
  }

  /// 词级Jaccard相似度（中文按2-gram分词，英文按空格分词）
  double _wordJaccardSimilarity(String a, String b) {
    final setA = _tokenize(a).toSet();
    final setB = _tokenize(b).toSet();
    if (setA.isEmpty && setB.isEmpty) return 1.0;
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    return union == 0 ? 0 : intersection / union;
  }

  /// 简易分词：中文2-gram + 英文按空格
  List<String> _tokenize(String text) {
    final tokens = <String>[];
    // 先提取英文单词
    final words = text.split(RegExp(r'[\s,;.!?，。；！？]+'));
    tokens.addAll(words.where(
        (w) => w.length > 1 && !RegExp(r'^[\u4e00-\u9fff]+$').hasMatch(w)));
    // 中文2-gram（包括中英边界）
    final chars = text.runes.map((r) => String.fromCharCode(r)).toList();
    for (var i = 0; i < chars.length - 1; i++) {
      final cur = chars[i];
      final next = chars[i + 1];
      final curIsCjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(cur);
      final nextIsCjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(next);
      if (curIsCjk || nextIsCjk) {
        tokens.add('$cur$next');
      }
    }
    return tokens;
  }

  /// 编辑距离相似度
  double _editDistanceSimilarity(String a, String b) {
    final distance = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    return maxLen == 0 ? 1 : 1 - distance / maxLen;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> prev = List.filled(b.length + 1, 0);
    List<int> curr = List.filled(b.length + 1, 0);

    for (int j = 0; j <= b.length; j++) prev[j] = j;

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1,
          curr[j - 1] + 1,
          prev[j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }

    return prev[b.length];
  }

  /// 记录执行日志
  Future<void> _logExecution({
    required String taskType,
    required String status,
    int? startedAt,
    int? completedAt,
    String? errorMessage,
    String? label,
  }) async {
    final start = startedAt ?? DateTime.now().millisecondsSinceEpoch;
    final end = completedAt ?? DateTime.now().millisecondsSinceEpoch;
    await _db.insert('execution_logs', {
      'id': 'el${DateTime.now().millisecondsSinceEpoch}_${taskType.hashCode.abs()}',
      'task_type': taskType,
      'status': status,
      'started_at': start,
      'completed_at': end,
      'duration': end - start,
      'error_message': errorMessage,
      'label': label,
    });
  }
}

class FetchResult {
  final int fetched;
  final int deduped;
  final int inserted;

  const FetchResult({
    required this.fetched,
    required this.deduped,
    required this.inserted,
  });
}

/// RSS/Atom 条目内部模型
class _RssItem {
  final String title;
  final String link;
  final String description;
  final String? content;
  final int? pubDate;
  final String? author;

  const _RssItem({
    this.title = '',
    this.link = '',
    this.description = '',
    this.content,
    this.pubDate,
    this.author,
  });
}
