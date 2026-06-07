import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/feed_service.dart';
import '../services/fetch_service.dart';
import '../services/score_service.dart';
import '../services/llm_service.dart';
import '../services/summary_service.dart';
import '../services/briefing_service.dart';
import '../services/export_service.dart';

// ==================== 服务 Providers ====================

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService(ref.watch(databaseServiceProvider));
});

final llmServiceProvider = Provider<LLMService>((ref) {
  return LLMService(ref.watch(databaseServiceProvider));
});

final fetchServiceProvider = Provider<FetchService>((ref) {
  return FetchService(
    ref.watch(databaseServiceProvider),
    ref.watch(feedServiceProvider),
  );
});

final scoreServiceProvider = Provider<ScoreService>((ref) {
  return ScoreService(
    ref.watch(databaseServiceProvider),
    ref.watch(llmServiceProvider),
  );
});

final summaryServiceProvider = Provider<SummaryService>((ref) {
  return SummaryService(
    ref.watch(databaseServiceProvider),
    ref.watch(llmServiceProvider),
  );
});

final briefingServiceProvider = Provider<BriefingService>((ref) {
  return BriefingService(
    ref.watch(databaseServiceProvider),
    ref.watch(fetchServiceProvider),
    ref.watch(scoreServiceProvider),
    ref.watch(summaryServiceProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(databaseServiceProvider));
});

// ==================== 应用状态 Providers ====================

/// Onboarding 是否完成
final onboardingDoneProvider = StateProvider<bool>((ref) => false);

/// Onboarding 初始化：从数据库加载
final onboardingInitializerProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  final db = ref.watch(databaseServiceProvider);
  final results = await db.query('user_config', where: 'id = ?', whereArgs: ['default']);
  final done = results.isNotEmpty && (results.first['onboarding_done'] as int? ?? 0) == 1;
  Future.microtask(() => ref.read(onboardingDoneProvider.notifier).state = done);
  return done;
});

/// 当前页面
final currentPageProvider = StateProvider<String>((ref) => 'welcome');

/// 首页筛选
final homeFilterProvider = StateProvider<String>((ref) => 'all');

/// 首页排序
final homeSortProvider = StateProvider<String>((ref) => 'score');

/// Web 专用已读文章 ID 集合
final readArticleIdsProvider = StateProvider<Set<String>>((ref) => {});

/// 收藏的文章 ID 集合
final favoritedArticleIdsProvider = StateProvider<Set<String>>((ref) => {});

/// 收藏ID初始化：从数据库加载
final favoritedIdsInitializerProvider = FutureProvider<Set<String>>((ref) async {
  if (kIsWeb) return {'1', '5'};
  final db = ref.watch(databaseServiceProvider);
  final results = await db.query('articles', columns: ['id'], where: 'is_favorited = 1');
  final ids = results.map((m) => m['id'] as String).toSet();
  Future.microtask(() => ref.read(favoritedArticleIdsProvider.notifier).state = ids);
  return ids;
});

/// 简报生成状态
final briefingGeneratingProvider = StateProvider<bool>((ref) => false);

/// 简报生成进度 (0.0 - 1.0)
final briefingProgressProvider = StateProvider<double>((ref) => 0);

/// 简报生成步骤
final briefingStepProvider = StateProvider<String>((ref) => '');

/// 数据刷新触发器（递增计数器，修改后触发相关 Provider 重新加载）
final _refreshCounterProvider = StateProvider<int>((ref) => 0);

// ==================== 数据 Providers ====================

/// 文章列表
final articlesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // 监听刷新触发器
  ref.watch(_refreshCounterProvider);

  // Web 平台不支持 sqflite，直接返回模拟数据
  if (kIsWeb) {
    final articles = _getMockArticles();
    final favoritedIds = ref.watch(favoritedArticleIdsProvider);
    final filter = ref.watch(homeFilterProvider);
    final sort = ref.watch(homeSortProvider);

    final readIds = ref.watch(readArticleIdsProvider);
    var result = articles.map((a) {
      final id = a['id'] as String;
      return Map<String, dynamic>.from(a)
        ..['is_favorited'] = favoritedIds.contains(id) ? 1 : 0
        ..['is_read'] = readIds.contains(id) ? 1 : a['is_read'];
    }).toList();

    switch (filter) {
      case 'unread':
        result = result.where((a) => a['is_read'] == 0).toList();
        break;
      case 'favorited':
        result = result.where((a) => a['is_favorited'] == 1).toList();
        break;
    }

    if (sort == 'score') {
      result.sort((a, b) => (b['score_total'] as double).compareTo(a['score_total'] as double));
    } else {
      result.sort((a, b) => (b['published_at'] as int).compareTo(a['published_at'] as int));
    }

    return result;
  }

  final db = ref.watch(databaseServiceProvider);
  final filter = ref.watch(homeFilterProvider);
  final sort = ref.watch(homeSortProvider);

  // 构建查询条件
  final whereParts = <String>[];
  final whereArgs = <Object?>[];

  // 筛选过滤
  switch (filter) {
    case 'unread':
      whereParts.add('is_read = 0');
      break;
    case 'favorited':
      whereParts.add('is_favorited = 1');
      break;
  }

  final where = whereParts.isNotEmpty ? whereParts.join(' AND ') : null;

  try {
    return await db.query(
      'articles',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: sort == 'score' ? 'score_total DESC' : 'published_at DESC',
    );
  } catch (e) {
    return [];
  }
});

/// 收藏文章列表（独立 Provider，供收藏页面使用）
final favoriteArticlesProvider = FutureProvider<List<Article>>((ref) async {
  ref.watch(_refreshCounterProvider);
  if (kIsWeb) {
    return _getMockArticles()
        .where((a) => a['is_favorited'] == 1)
        .map((m) => Article.fromMap(m))
        .toList();
  }
  final db = ref.watch(databaseServiceProvider);
  final maps = await db.query(
    'articles',
    where: 'is_favorited = 1',
    orderBy: 'fetched_at DESC',
  );
  return maps.map((m) => Article.fromMap(m)).toList();
});

/// 文章详情 Provider（按文章ID查询）
final articleDetailProvider = FutureProvider.family<Article?, String>((ref, articleId) async {
  if (kIsWeb) {
    final mock = _getMockArticles().where((a) => a['id'] == articleId).firstOrNull;
    return mock != null ? Article.fromMap(mock) : null;
  }
  final db = ref.watch(databaseServiceProvider);
  final maps = await db.query('articles', where: 'id = ?', whereArgs: [articleId]);
  if (maps.isEmpty) return null;
  return Article.fromMap(maps.first);
});

/// 文章评分记录 Provider（按文章ID查询）
final articleScoreProvider = FutureProvider.family<Score?, String>((ref, articleId) async {
  if (kIsWeb) return null;
  ref.watch(_refreshCounterProvider);
  final db = ref.watch(databaseServiceProvider);
  final maps = await db.query('scores', where: 'article_id = ?', whereArgs: [articleId]);
  if (maps.isEmpty) return null;
  return Score.fromMap(maps.first);
});

/// 今日简报
final todayBriefingProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(_refreshCounterProvider);
  final db = ref.watch(databaseServiceProvider);
  final today = DateTime.now().toIso8601String().split('T')[0];
  final results = await db.query(
    'briefings',
    where: 'date = ?',
    whereArgs: [today],
  );
  return results.isEmpty ? null : results.first;
});

/// 今日简报关联的文章
final todayBriefingArticlesProvider = FutureProvider<List<Article>>((ref) async {
  ref.watch(_refreshCounterProvider);
  if (kIsWeb) return _getMockArticles().map((m) => Article.fromMap(m)).take(5).toList();
  final db = ref.watch(databaseServiceProvider);
  final today = DateTime.now().toIso8601String().split('T')[0];
  final briefingMaps = await db.query('briefings', where: 'date = ?', whereArgs: [today]);
  if (briefingMaps.isEmpty) return [];
  final briefingId = briefingMaps.first['id'] as String;
  final maps = await db.query(
    'articles',
    where: 'briefing_id = ?',
    whereArgs: [briefingId],
    orderBy: 'score_total DESC',
  );
  return maps.map((m) => Article.fromMap(m)).toList();
});

/// 数据源列表
final feedsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(_refreshCounterProvider);
  final db = ref.watch(databaseServiceProvider);
  return db.query('feeds', orderBy: 'name ASC');
});

/// 执行日志
final executionLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(_refreshCounterProvider);
  final db = ref.watch(databaseServiceProvider);
  return db.query('execution_logs', orderBy: 'started_at DESC', limit: 100);
});

/// 用户配置（强类型）
final userConfigProvider = FutureProvider<UserConfig>((ref) async {
  ref.watch(_refreshCounterProvider);
  final db = ref.watch(databaseServiceProvider);
  final results = await db.query('user_config', where: 'id = ?', whereArgs: ['default']);
  if (results.isEmpty) return const UserConfig();
  return UserConfig.fromMap(results.first);
});

/// LLM 配置（强类型）
final llmConfigProvider = FutureProvider<LLMConfig>((ref) async {
  ref.watch(_refreshCounterProvider);
  final db = ref.watch(databaseServiceProvider);
  final results = await db.query('llm_config', where: 'id = ?', whereArgs: ['default']);
  if (results.isEmpty) return const LLMConfig();
  return LLMConfig.fromMap(results.first);
});

/// 历史简报列表
final historyBriefingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(_refreshCounterProvider);
  if (kIsWeb) return [];
  final db = ref.watch(databaseServiceProvider);
  return db.query('briefings', where: 'status = ?', whereArgs: ['completed'], orderBy: 'date DESC', limit: 30);
});

/// LLM 月度成本统计
final monthlyCostStatsProvider = FutureProvider<MonthlyCostStats?>((ref) async {
  if (kIsWeb) return null;
  final llmService = ref.watch(llmServiceProvider);
  return llmService.getMonthlyCostStats();
});

/// 异常数据源列表
final errorFeedsProvider = FutureProvider<List<Feed>>((ref) async {
  ref.watch(_refreshCounterProvider);
  if (kIsWeb) return [];
  final feedService = ref.watch(feedServiceProvider);
  return feedService.getErrorFeeds();
});

/// 文章反馈状态 Provider
final articleFeedbackProvider = FutureProvider.family<String?, String>((ref, articleId) async {
  ref.watch(_refreshCounterProvider);
  if (kIsWeb) return null;
  final scoreService = ref.watch(scoreServiceProvider);
  return scoreService.getArticleFeedback(articleId);
});

// ==================== 数据库写入辅助 ====================

/// 触发数据刷新
void refreshData(WidgetRef ref) {
  ref.read(_refreshCounterProvider.notifier).state++;
}

/// 切换收藏状态（同时写DB）
Future<void> toggleFavorite(WidgetRef ref, String articleId) async {
  final favoritedIds = ref.read(favoritedArticleIdsProvider);
  final isFavorited = favoritedIds.contains(articleId);
  final newIds = isFavorited
      ? (Set<String>.from(favoritedIds)..remove(articleId))
      : (Set<String>.from(favoritedIds)..add(articleId));
  ref.read(favoritedArticleIdsProvider.notifier).state = newIds;

  if (!kIsWeb) {
    final db = ref.read(databaseServiceProvider);
    await db.update(
      'articles',
      {'is_favorited': isFavorited ? 0 : 1},
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }
  refreshData(ref);
}

/// 标记文章为已读（写DB）
Future<void> markArticleRead(WidgetRef ref, String articleId) async {
  if (kIsWeb) {
    final readIds = ref.read(readArticleIdsProvider);
    ref.read(readArticleIdsProvider.notifier).state = Set<String>.from(readIds)..add(articleId);
  } else {
    final db = ref.read(databaseServiceProvider);
    await db.update(
      'articles',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }
  refreshData(ref);
}

/// 保存用户配置（写DB + 刷新Provider）
Future<void> saveUserConfig(WidgetRef ref, UserConfig config) async {
  if (!kIsWeb) {
    final db = ref.read(databaseServiceProvider);
    final existing = await db.query('user_config', where: 'id = ?', whereArgs: ['default']);
    if (existing.isEmpty) {
      await db.insert('user_config', config.toMap());
    } else {
      await db.update('user_config', config.toMap(), where: 'id = ?', whereArgs: ['default']);
    }
  }
  refreshData(ref);
}

/// 保存 LLM 配置（写DB + 刷新Provider）
Future<void> saveLLMConfig(WidgetRef ref, LLMConfig config) async {
  if (!kIsWeb) {
    final llmService = ref.read(llmServiceProvider);
    await llmService.saveConfig(config);
  }
  refreshData(ref);
}

/// 添加数据源（写DB + 刷新Provider）
Future<void> addFeed(WidgetRef ref, {required String url, required String type, String? category, String? name}) async {
  if (!kIsWeb) {
    final feedService = ref.read(feedServiceProvider);
    await feedService.addFeed(url: url, type: type, category: category, name: name);
  }
  refreshData(ref);
}

/// 删除数据源（写DB + 刷新Provider）
Future<void> removeFeed(WidgetRef ref, String feedId) async {
  if (!kIsWeb) {
    final feedService = ref.read(feedServiceProvider);
    await feedService.removeFeed(feedId);
  }
  refreshData(ref);
}

/// 切换数据源启用状态（写DB + 刷新Provider）
Future<void> toggleFeed(WidgetRef ref, String feedId) async {
  if (!kIsWeb) {
    final feedService = ref.read(feedServiceProvider);
    await feedService.toggleFeed(feedId);
  }
  refreshData(ref);
}

/// 记录文章反馈（写DB + 刷新）
Future<void> recordArticleFeedback(WidgetRef ref, String articleId, String feedbackType) async {
  if (!kIsWeb) {
    final scoreService = ref.read(scoreServiceProvider);
    await scoreService.recordFeedback(articleId, feedbackType);
  }
  refreshData(ref);
}

/// 触发简报生成
Future<void> generateBriefing(WidgetRef ref) async {
  ref.read(briefingGeneratingProvider.notifier).state = true;
  ref.read(briefingProgressProvider.notifier).state = 0;
  ref.read(briefingStepProvider.notifier).state = '开始采集...';

  try {
    final briefingService = ref.read(briefingServiceProvider);

    ref.read(briefingProgressProvider.notifier).state = 0.2;
    ref.read(briefingStepProvider.notifier).state = '采集文章中...';

    ref.read(briefingProgressProvider.notifier).state = 0.5;
    ref.read(briefingStepProvider.notifier).state = '评分筛选中...';

    await briefingService.generate('manual');

    ref.read(briefingProgressProvider.notifier).state = 1.0;
    ref.read(briefingStepProvider.notifier).state = '生成完成';
  } catch (e) {
    ref.read(briefingStepProvider.notifier).state = '生成失败: $e';
  } finally {
    ref.read(briefingGeneratingProvider.notifier).state = false;
    refreshData(ref);
  }
}

/// 手动触发采集
Future<FetchResult?> runFetch(WidgetRef ref) async {
  if (kIsWeb) return null;
  final fetchService = ref.read(fetchServiceProvider);
  final result = await fetchService.runFetch();
  refreshData(ref);
  return result;
}

// ==================== Mock 数据 ====================

List<Map<String, dynamic>> _getMockArticles() {
  final now = DateTime.now().millisecondsSinceEpoch;
  return [
    {
      'id': '1',
      'title': 'OpenAI 发布 GPT-5 预览版：推理能力大幅提升，支持多模态实时交互',
      'url': 'https://example.com/1',
      'content': 'OpenAI 今日发布了 GPT-5 预览版，新模型在逻辑推理、数学计算和代码生成方面都有显著提升...',
      'summary_one': 'GPT-5 预览版发布，推理能力大幅提升，支持实时多模态交互，标志着大语言模型进入新阶段。',
      'summary_points': '["推理能力提升","多模态实时交互","代码生成优化"]',
      'source_name': '36氪',
      'published_at': now - 3600000,
      'fetched_at': now - 3600000,
      'score_total': 9.2,
      'score_credibility': 8.5,
      'score_density': 9.0,
      'score_mode': 'llm',
      'is_read': 0,
      'is_favorited': 1,
    },
    {
      'id': '2',
      'title': '全球供应链重组加速：东南亚制造业崛起，中国产业链向高端迁移',
      'url': 'https://example.com/2',
      'content': '随着地缘政治变化和技术升级，全球供应链正在经历深刻重组...',
      'summary_one': '全球供应链加速重组，东南亚承接中低端制造，中国向高端产业链升级。',
      'summary_points': '["东南亚制造业崛起","中国产业升级","供应链多元化"]',
      'source_name': '财新网',
      'published_at': now - 7200000,
      'fetched_at': now - 7200000,
      'score_total': 8.7,
      'score_credibility': 9.0,
      'score_density': 8.5,
      'score_mode': 'llm',
      'is_read': 0,
      'is_favorited': 0,
    },
    {
      'id': '3',
      'title': '新能源汽车市场格局重塑：比亚迪销量超越特斯拉，智能化成新战场',
      'url': 'https://example.com/3',
      'content': '2024年新能源汽车市场出现重大转折，比亚迪全球销量首次超越特斯拉...',
      'summary_one': '比亚迪销量首超特斯拉，新能源汽车竞争从电动化转向智能化。',
      'summary_points': '["比亚迪超越特斯拉","智能化竞争","市场格局重塑"]',
      'source_name': '第一财经',
      'published_at': now - 10800000,
      'fetched_at': now - 10800000,
      'score_total': 8.5,
      'score_credibility': 8.0,
      'score_density': 8.5,
      'score_mode': 'local',
      'is_read': 1,
      'is_favorited': 0,
    },
    {
      'id': '4',
      'title': '苹果 Vision Pro 国行版上市：空间计算能否开启下一代计算平台？',
      'url': 'https://example.com/4',
      'content': '苹果 Vision Pro 国行版今日正式发售，起售价 29999 元...',
      'summary_one': 'Vision Pro 国行上市，空间计算概念引发热议，但价格和内容生态仍是挑战。',
      'summary_points': '["空间计算平台","高价策略","内容生态挑战"]',
      'source_name': '极客公园',
      'published_at': now - 14400000,
      'fetched_at': now - 14400000,
      'score_total': 7.8,
      'score_credibility': 7.5,
      'score_density': 7.5,
      'score_mode': 'local',
      'is_read': 0,
      'is_favorited': 0,
    },
    {
      'id': '5',
      'title': '美联储暗示降息路径：通胀数据改善，市场预期 9 月开启降息周期',
      'url': 'https://example.com/5',
      'content': '美联储最新会议纪要显示，多数官员认为通胀正在向 2% 目标回落...',
      'summary_one': '美联储暗示 9 月可能降息，全球资本市场迎来流动性宽松预期。',
      'summary_points': '["降息预期","通胀改善","全球流动性"]',
      'source_name': '华尔街见闻',
      'published_at': now - 18000000,
      'fetched_at': now - 18000000,
      'score_total': 8.9,
      'score_credibility': 9.0,
      'score_density': 8.5,
      'score_mode': 'llm',
      'is_read': 0,
      'is_favorited': 1,
    },
    {
      'id': '6',
      'title': 'Rust 语言在系统编程领域持续扩张：Linux 内核正式合并 Rust 驱动',
      'url': 'https://example.com/6',
      'content': 'Linus Torvalds 确认 Linux 6.11 将正式包含 Rust 编写的驱动程序...',
      'summary_one': 'Linux 内核正式支持 Rust 驱动，内存安全语言在系统编程领域取得重大突破。',
      'summary_points': '["Rust进入内核","内存安全","系统编程变革"]',
      'source_name': 'InfoQ',
      'published_at': now - 21600000,
      'fetched_at': now - 21600000,
      'score_total': 7.5,
      'score_credibility': 8.0,
      'score_density': 7.0,
      'score_mode': 'local',
      'is_read': 1,
      'is_favorited': 0,
    },
    {
      'id': '7',
      'title': '欧盟通过《人工智能法案》：全球首部全面监管 AI 的法律框架',
      'url': 'https://example.com/7',
      'content': '欧盟理事会正式批准《人工智能法案》，这是全球首部全面监管人工智能的法律...',
      'summary_one': '欧盟通过全球首部 AI 监管法案，按风险分级管理，影响全球 AI 产业发展。',
      'summary_points': '["AI监管法案","风险分级","全球影响"]',
      'source_name': 'BBC 中文网',
      'published_at': now - 25200000,
      'fetched_at': now - 25200000,
      'score_total': 8.3,
      'score_credibility': 8.5,
      'score_density': 8.0,
      'score_mode': 'llm',
      'is_read': 0,
      'is_favorited': 0,
    },
    {
      'id': '8',
      'title': '量子计算新突破：IBM 发布 1000+ 量子比特处理器，实用化进程加速',
      'url': 'https://example.com/8',
      'content': 'IBM 今日发布新一代量子处理器 Condor，量子比特数突破 1000...',
      'summary_one': 'IBM 发布千量子比特处理器，量子计算向实用化迈出重要一步。',
      'summary_points': '["千量子比特","量子纠错","实用化进程"]',
      'source_name': 'MIT Technology Review',
      'published_at': now - 28800000,
      'fetched_at': now - 28800000,
      'score_total': 8.1,
      'score_credibility': 9.0,
      'score_density': 7.5,
      'score_mode': 'llm',
      'is_read': 0,
      'is_favorited': 0,
    },
  ];
}
