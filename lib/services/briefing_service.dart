import 'dart:convert';
import '../models/models.dart';
import 'database_service.dart';
import 'feed_service.dart';
import 'fetch_service.dart';
import 'score_service.dart';
import 'summary_service.dart';

/// 简报生成服务
/// 对应 PRD 接口 BriefingService
/// 含执行日志记录、先评分再筛选逻辑
class BriefingService {
  final DatabaseService _db;
  final FetchService _fetchService;
  final ScoreService _scoreService;
  final SummaryService _summaryService;

  BriefingService(
    this._db,
    this._fetchService,
    this._scoreService,
    this._summaryService,
  );

  /// 领域关键词映射（用于按 category 过滤文章）
  static const categoryKeywords = <String, List<String>>{
    'AI': ['AI', '人工智能', '机器学习', '深度学习', 'LLM', 'GPT', '大模型', '神经网络', 'NLP', '计算机视觉', 'ChatGPT', 'Claude', 'Gemini'],
    '科技商业': ['科技', '创业', '融资', '上市', '商业模式', '互联网', '电商', 'SaaS', '数字化转型', '独角兽', 'IPO', '风投'],
    '技术': ['编程', '开发', '架构', '开源', 'API', '框架', '微服务', '容器', 'DevOps', '数据库', 'Rust', 'Go', 'Python', 'TypeScript'],
    '消费科技': ['手机', '电脑', '芯片', '硬件', '智能设备', '可穿戴', 'VR', 'AR', 'IoT', '苹果', '三星', '华为', '小米'],
    '前沿科技': ['量子', '生物科技', '新能源', '航天', '机器人', '自动驾驶', '脑机接口', '核聚变', 'SpaceX', 'Tesla'],
    '效率工具': ['效率', '工具', '笔记', '日历', '自动化', '工作流', '生产力', 'Notion', 'Obsidian', 'VS Code'],
    '综合科技': ['科技新闻', '行业动态', '政策', '监管', '数据安全', '隐私', '反垄断', '合规'],
    '开源生态': ['开源', 'GitHub', 'Linux', 'Kubernetes', 'Docker', 'Apache', 'MIT License', 'GPL', '贡献者', '仓库'],
    '产品与设计': ['产品', '设计', 'UX', 'UI', '交互', '用户体验', '原型', 'Figma', '需求', '迭代', 'MVP'],
    '安全与隐私': ['安全', '漏洞', 'CVE', '渗透测试', '加密', '零信任', '勒索软件', '数据泄露', '隐私保护', '网络安全'],
    '云与基础设施': ['云计算', 'AWS', 'Azure', 'GCP', 'K8s', 'Serverless', 'CDN', '边缘计算', '运维', 'SRE', '负载均衡'],
    '科技文化': ['科技文化', '数字生活', '未来趋势', '社会影响', '数字游民', '远程办公', '数字鸿沟', '科技伦理'],
  };

  /// 生成/刷新简报
  /// 首次调用创建简报，再次调用刷新补充新文章
  Future<Briefing> generate(String triggerType) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final startedAt = DateTime.now().millisecondsSinceEpoch;

    // 查找今日已有简报
    final existingBriefings = await _db.query(
      'briefings',
      where: 'date = ?',
      whereArgs: [today],
    );
    final isRefresh = existingBriefings.isNotEmpty;
    final briefingId = isRefresh
        ? existingBriefings.first['id'] as String
        : 'b${DateTime.now().millisecondsSinceEpoch}';

    if (!isRefresh) {
      // 首次生成：创建简报记录
      final briefing = Briefing(
        id: briefingId,
        date: today,
        articleCount: 0,
        generatedAt: startedAt,
        triggerType: triggerType,
        status: 'generating',
      );
      await _db.insert('briefings', briefing.toMap());
    }

    try {
      // 1. 采集新文章
      final fetchResult = await _fetchService.runFetch();

      // 2. 获取用户配置
      final configMaps = await _db.query('user_config');
      final config = configMaps.isNotEmpty
          ? UserConfig.fromMap(configMaps.first)
          : const UserConfig();

      // 3. 获取过去24h文章
      final yesterday = DateTime.now()
          .subtract(const Duration(hours: 24))
          .millisecondsSinceEpoch;
      final allArticles = await _db.query(
        'articles',
        where: 'fetched_at >= ?',
        whereArgs: [yesterday],
        orderBy: 'score_total DESC',
      );

      // 4. 对未评分文章进行评分和摘要
      for (final map in allArticles) {
        var article = Article.fromMap(map);
        try {
          if (article.scoreTotal == 0) {
            await _scoreService.scoreArticle(article.id, config.aiMode);
            // 重新查询以获取可能由 LLM 评分附带生成的摘要
            final updatedMaps = await _db.query('articles', where: 'id = ?', whereArgs: [article.id]);
            if (updatedMaps.isNotEmpty) {
              article = Article.fromMap(updatedMaps.first);
            }
          }
          
          final needsSummary = article.summaryOne == null || article.summaryOne!.isEmpty;
          // economy 模式：仅无摘要时本地生成
          // hybrid 模式：强制使用 LLM 生成摘要（覆盖本地空摘要）
          // quality 模式：如上面已生成 LLM 摘要，则跳过
          if (needsSummary || (config.aiMode != 'economy' && article.scoreMode != 'llm')) {
            await _summaryService.summarize(article.id, config.aiMode);
          }
        } catch (e) {
          // 单篇文章评分/摘要失败不影响其他文章
        }
      }

      // 5. 重新查询已评分的文章
      final scoredArticles = await _db.query(
        'articles',
        where: 'fetched_at >= ? AND score_total > 0',
        whereArgs: [yesterday],
        orderBy: 'score_total DESC',
      );

      // 6. 按关注领域过滤
      final filteredArticles = _filterByCategories(scoredArticles, config.categories);

      // 7. 按国内外比例分配
      final selectedArticles = await _allocateByRatio(
        filteredArticles,
        config.dailyCount,
        config.domesticRatio,
      );

      // 8. 关联文章到简报（先清除旧关联，再重新关联）
      await _db.update(
        'articles',
        {'briefing_id': null},
        where: 'briefing_id = ?',
        whereArgs: [briefingId],
      );
      for (final map in selectedArticles) {
        try {
          await _db.update(
            'articles',
            {'briefing_id': briefingId},
            where: 'id = ?',
            whereArgs: [map['id']],
          );
        } catch (_) {
          // 关联失败不影响其他文章
        }
      }

      // 9. 统计分类信息
      final stats = _computeStats(scoredArticles, selectedArticles);

      // 10. 更新简报
      final completedAt = DateTime.now().millisecondsSinceEpoch;
      await _db.update(
        'briefings',
        {
          'article_count': selectedArticles.length,
          'status': 'completed',
          'ai_insight': _generateAIInsight(selectedArticles),
          'total_fetched': stats['totalFetched'],
          'domestic_count': stats['domesticCount'],
          'international_count': stats['internationalCount'],
          'categories_json': stats['categoriesJson'],
          'generated_at': completedAt,
        },
        where: 'id = ?',
        whereArgs: [briefingId],
      );

      // 11. 记录执行日志
      await _logExecution(
        taskType: isRefresh ? 'refresh' : 'generate',
        status: 'success',
        startedAt: startedAt,
        completedAt: completedAt,
        label: '${isRefresh ? "刷新" : "生成"}简报完成，精选 ${selectedArticles.length} 条（采集 ${fetchResult.fetched} 条，新增 ${fetchResult.inserted} 条）',
      );

      return Briefing(
        id: briefingId,
        date: today,
        articleCount: selectedArticles.length,
        generatedAt: completedAt,
        triggerType: triggerType,
        status: 'completed',
        totalFetched: stats['totalFetched'] as int,
        domesticCount: stats['domesticCount'] as int,
        internationalCount: stats['internationalCount'] as int,
        categoriesJson: stats['categoriesJson'] as String?,
        aiInsight: _generateAIInsight(selectedArticles),
      );
    } catch (e) {
      // 更新简报状态为失败
      await _db.update(
        'briefings',
        {'status': 'failed'},
        where: 'id = ?',
        whereArgs: [briefingId],
      );

      // 记录失败日志
      await _logExecution(
        taskType: isRefresh ? 'refresh' : 'generate',
        status: 'error',
        startedAt: startedAt,
        errorMessage: e.toString(),
        label: '${isRefresh ? "刷新" : "生成"}简报失败',
      );

      rethrow;
    }
  }

  /// 生成 AI 洞察摘要
  String _generateAIInsight(List<Map<String, dynamic>> selectedArticles) {
    if (selectedArticles.isEmpty) return '今日暂无精选资讯';

    // 按领域分组统计
    final categoryCounts = <String, int>{};
    for (final article in selectedArticles) {
      final category = article['category'] as String? ?? '其他';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    if (categoryCounts.isEmpty) return '今日精选 ${selectedArticles.length} 条高价值资讯';

    final topCategory = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final avgScore = selectedArticles.fold<double>(
          0, (sum, a) => sum + ((a['score_total'] as num?)?.toDouble() ?? 0),
        ) /
        selectedArticles.length;

    return '今日精选 ${selectedArticles.length} 条高价值资讯，'
        '平均评分 ${avgScore.toStringAsFixed(1)}，'
        '${topCategory.key}领域最活跃（${topCategory.value} 条）';
  }

  /// 按关注领域过滤文章（宽松模式：未匹配领域的文章保留，匹配的优先）
  List<Map<String, dynamic>> _filterByCategories(
    List<Map<String, dynamic>> articles,
    List<String> categories,
  ) {
    if (categories.isEmpty) return articles;

    // 分离：匹配领域的文章 + 未匹配的文章
    final matched = <Map<String, dynamic>>[];
    final unmatched = <Map<String, dynamic>>[];

    for (final article in articles) {
      final category = article['category'] as String?;
      if (category != null && categories.contains(category)) {
        matched.add(article);
        continue;
      }

      // 如果文章没有 category，用标题和内容匹配关键词
      final title = (article['title'] as String?) ?? '';
      final content = (article['content'] as String?) ?? '';
      final text = '$title $content';

      bool keywordMatched = false;
      for (final cat in categories) {
        final keywords = categoryKeywords[cat];
        if (keywords != null) {
          for (final keyword in keywords) {
            if (text.contains(keyword)) {
              keywordMatched = true;
              break;
            }
          }
        }
        if (keywordMatched) break;
      }

      if (keywordMatched) {
        matched.add(article);
      } else {
        unmatched.add(article);
      }
    }

    // 优先返回匹配的文章，再用未匹配的补充（确保简报数量充足）
    return [...matched, ...unmatched];
  }

  /// 按国内外比例分配文章名额
  /// 过滤极低分文章（score < 3.0），再按比例分配
  Future<List<Map<String, dynamic>>> _allocateByRatio(
    List<Map<String, dynamic>> articles,
    int dailyCount,
    double domesticRatio,
  ) async {
    // 过滤极低分文章（评分低于3.0的不入选简报）
    final qualified = articles.where((a) {
      final score = (a['score_total'] as num?)?.toDouble() ?? 0;
      return score >= 3.0;
    }).toList();

    // 从 feeds 表获取国内外映射
    final feeds = await _db.query('feeds');
    final feedDomesticMap = <String, bool>{};
    for (final feed in feeds) {
      final url = feed['url'] as String? ?? '';
      final isDomestic = (feed['is_domestic'] as int?) == 1;
      feedDomesticMap[url] = isDomestic;
    }

    // 分离国内外文章
    final domestic = <Map<String, dynamic>>[];
    final international = <Map<String, dynamic>>[];

    for (final article in qualified) {
      final sourceUrl = article['source_url'] as String? ?? '';
      final sourceName = article['source_name'] as String? ?? '';

      // 优先通过 feeds 表的 is_domestic 字段判断
      bool isDomestic = feedDomesticMap[sourceUrl] ?? FeedService.isDomesticUrl(sourceUrl);

      // 如果仍无法判断，用 source_name 匹配
      if (sourceUrl.isEmpty) {
        const domesticNames = [
          '36氪', '量子位', '机器之心', 'InfoQ', '少数派', '爱范儿',
          'IT之家', '虎嗅', '财新网', '第一财经', '极客公园', '华尔街见闻',
        ];
        isDomestic = domesticNames.any((n) => sourceName.contains(n));
      }

      if (isDomestic) {
        domestic.add(article);
      } else {
        international.add(article);
      }
    }

    // 按比例分配名额（不超过实际可用数量）
    int domesticSlots = (dailyCount * domesticRatio).round();
    int internationalSlots = dailyCount - domesticSlots;

    // 动态名额补偿
    if (domestic.length < domesticSlots) {
      // 国内不足，名额顺延给国际
      final deficit = domesticSlots - domestic.length;
      domesticSlots = domestic.length;
      internationalSlots += deficit;
    } else if (international.length < internationalSlots) {
      // 国际不足，名额顺延给国内
      final deficit = internationalSlots - international.length;
      internationalSlots = international.length;
      domesticSlots += deficit;
    }

    final selected = <Map<String, dynamic>>[];
    selected.addAll(domestic.take(domesticSlots));
    selected.addAll(international.take(internationalSlots));

    return selected;
  }

  /// 获取今日简报
  Future<Briefing?> getTodayBriefing() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final maps = await _db.query(
      'briefings',
      where: 'date = ?',
      whereArgs: [today],
    );
    if (maps.isEmpty) return null;
    return Briefing.fromMap(maps.first);
  }

  /// 获取简报关联的文章
  Future<List<Article>> getBriefingArticles(String briefingId) async {
    final maps = await _db.query(
      'articles',
      where: 'briefing_id = ?',
      whereArgs: [briefingId],
      orderBy: 'score_total DESC',
    );
    return maps.map((m) => Article.fromMap(m)).toList();
  }

  /// 获取历史简报列表
  Future<List<Briefing>> getHistoryBriefings({int limit = 30}) async {
    final maps = await _db.query(
      'briefings',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => Briefing.fromMap(m)).toList();
  }

  /// 计算简报统计信息
  Map<String, dynamic> _computeStats(
    List<Map<String, dynamic>> allFetched,
    List<Map<String, dynamic>> selected,
  ) {
    int domesticCount = 0;
    int internationalCount = 0;
    final categoryCounts = <String, int>{};

    for (final article in selected) {
      final sourceUrl = article['source_url'] as String? ?? '';
      final sourceName = article['source_name'] as String? ?? '';
      bool isDomestic = FeedService.isDomesticUrl(sourceUrl);
      if (sourceUrl.isEmpty) {
        const domesticNames = [
          '36氪', '量子位', '机器之心', 'InfoQ', '少数派', '爱范儿',
          'IT之家', '虎嗅', '财新网', '第一财经', '极客公园', '华尔街见闻',
        ];
        isDomestic = domesticNames.any((n) => sourceName.contains(n));
      }
      if (isDomestic) {
        domesticCount++;
      } else {
        internationalCount++;
      }
      final category = article['category'] as String?;
      if (category != null) {
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    return {
      'totalFetched': allFetched.length,
      'domesticCount': domesticCount,
      'internationalCount': internationalCount,
      'categoriesJson': categoryCounts.isNotEmpty
          ? jsonEncode(categoryCounts)
          : null,
    };
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
