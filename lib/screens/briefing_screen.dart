import 'dart:convert';
import '../utils/snackbar_util.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/article.dart';
import '../providers/app_state_provider.dart';
import 'article_detail_screen.dart';
import '../widgets/shimmer.dart';

/// 简报页面
class BriefingScreen extends ConsumerStatefulWidget {
  const BriefingScreen({super.key});

  @override
  ConsumerState<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends ConsumerState<BriefingScreen> {
  @override
  Widget build(BuildContext context) {
    final briefingAsync = ref.watch(todayBriefingProvider);
    final articlesAsync = ref.watch(todayBriefingArticlesProvider);
    final isGenerating = ref.watch(briefingGeneratingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      body: isGenerating
          ? const _BriefingGeneratingView()
          : CustomScrollView(
              slivers: [
                // 顶部 AppBar
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xFFF9F9F8),
                  title: Text(
                    '拾光 / Glean',
                    style: GoogleFonts.sourceSerif4(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A2B3C),
                    ),
                  ),
                  centerTitle: true,
                  leading: const SizedBox(width: 48),
                  actions: const [
                    SizedBox(width: 48),
                  ],
                ),

                // 简报标题区域
                SliverToBoxAdapter(
                  child: _buildBriefingHeader(context),
                ),

                // 统计卡片
                SliverToBoxAdapter(
                  child: _buildStatsCard(context),
                ),

                // 文章列表（按分类分组）
                articlesAsync.when(
                  skipLoadingOnReload: true,
                  skipLoadingOnRefresh: true,
                  data: (articles) {
                    if (articles.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(child: Text('暂无简报内容')),
                      );
                    }

                    // 按分类分组
                    final grouped = _groupByCategory(articles);

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = grouped.keys.elementAt(index);
                          final items = grouped[category]!;
                          return _buildCategorySection(context, category, items);
                        },
                        childCount: grouped.length,
                      ),
                    );
                  },
                  loading: () => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ArticleSkeleton(),
                      childCount: 3,
                    ),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(child: Text('加载失败: $err')),
                  ),
                ),

                // 底部按钮区域
                SliverToBoxAdapter(
                  child: _buildBottomActions(context),
                ),

                // 历史简报
                SliverToBoxAdapter(
                  child: _buildHistorySection(context),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
    );
  }

  /// 简报标题
  Widget _buildBriefingHeader(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.15),
                  Colors.transparent,
                ],
                radius: 0.6,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1A2B3C).withOpacity(0.08),
                  Colors.transparent,
                ],
                radius: 0.6,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI DAILY BRIEFING 标签
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFD4AF37),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI DAILY BRIEFING',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD4AF37),
                      letterSpacing: 0.08,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 大标题
              Text(
                '拾光日报 · $dateStr',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: const Color(0xFF1A2B3C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 统计卡片
  Widget _buildStatsCard(BuildContext context) {
    final briefingAsync = ref.watch(todayBriefingProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2B3C).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: briefingAsync.when(
        data: (briefing) {
          final totalFetched = briefing?['total_fetched'] as int? ?? 0;
          final articleCount = briefing?['article_count'] as int? ?? 0;
          final domesticCount = briefing?['domestic_count'] as int? ?? 0;
          final internationalCount = briefing?['international_count'] as int? ?? 0;
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_outlined, color: Color(0xFFD4AF37), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF44474C),
                    ),
                    children: [
                      TextSpan(text: '今日采集 $totalFetched 条，AI 精选 '),
                      TextSpan(
                        text: '$articleCount 条\n',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2B3C),
                        ),
                      ),
                      TextSpan(
                        text: '国内 $domesticCount 条 · 国际 $internationalCount 条',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF74777D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('加载失败'),
      ),
    );
  }

  /// 分类分组（按文章真实category分组）
  Map<String, List<Article>> _groupByCategory(List<Article> articles) {
    final Map<String, List<Article>> grouped = {};
    for (final article in articles) {
      final cat = article.category ?? '其他';
      grouped.putIfAbsent(cat, () => []).add(article);
    }
    return grouped;
  }

  /// 分类区块
  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<Article> articles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: const Color(0xFFC4C6CD).withOpacity(0.3),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  category,
                  style: GoogleFonts.sourceSerif4(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B3C),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: const Color(0xFFC4C6CD).withOpacity(0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),
        ),
        // 文章列表
        ...articles.map((article) => _buildBriefingArticleItem(context, article)),
      ],
    );
  }

  /// 简报文章项（紧凑样式）
  Widget _buildBriefingArticleItem(BuildContext context, Article article) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => ArticleDetailScreen(article: article),
              ),
            );
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: isPressed ? 0.98 : 1.0,
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPressed ? const Color(0xFFF9F9F8) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC4C6CD).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A2B3C).withOpacity(isPressed ? 0.02 : 0.04),
                    blurRadius: isPressed ? 8 : 16,
                    offset: Offset(0, isPressed ? 2 : 4),
                  ),
                ],
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 评分 + 标题
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.scoreTotal.toStringAsFixed(1),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: article.scoreTotal >= 8.5
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF1A2B3C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 一句话摘要
            if (article.summaryOne != null && article.summaryOne!.isNotEmpty)
              Text(
                article.summaryOne!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: const Color(0xFF44474C).withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            // 来源 + 查看全文
            Row(
              children: [
                Text(
                  article.sourceName.toUpperCase(),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF74777D),
                    letterSpacing: 0.04,
                  ),
                ),
                const Spacer(),
                Text(
                  '查看全文 →',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A2B3C).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
},
);
}

  /// 底部操作按钮
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 导出简报
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                _showExportSheet(context);
              },
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                '导出简报',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A2B3C),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 重新生成
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _simulateRegenerate(context);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                '刷新简报',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B3C),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A2B3C),
                minimumSize: const Size(0, 48),
                side: const BorderSide(color: Color(0xFFC4C6CD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateRegenerate(BuildContext context) {
    ref.read(briefingGeneratingProvider.notifier).state = true;
    ref.read(briefingServiceProvider).generate('manual').then((_) {
      if (mounted) {
        refreshData(ref);
        ref.read(briefingGeneratingProvider.notifier).state = false;
      }
    }).catchError((e) {
      if (mounted) {
        ref.read(briefingGeneratingProvider.notifier).state = false;
        showFloatingSnackBar(context, '简报生成失败: $e');
      }
    });
  }

  /// 历史简报区块
  Widget _buildHistorySection(BuildContext context) {
    final historyAsync = ref.watch(historyBriefingsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: const Color(0xFFC4C6CD).withOpacity(0.3),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '历史简报',
                  style: GoogleFonts.sourceSerif4(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B3C),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: const Color(0xFFC4C6CD).withOpacity(0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 历史简报列表
          historyAsync.when(
            data: (briefings) {
              if (briefings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('暂无历史简报', style: TextStyle(color: Color(0xFF74777D))),
                  ),
                );
              }
              // 跳过今日简报（已在上方展示）
              final today = DateTime.now().toIso8601String().split('T')[0];
              final history = briefings.where((b) => b['date'] != today).toList();
              return Column(
                children: history.map((briefing) => _buildHistoryBriefingItem(context, briefing)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('加载失败')),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryBriefingItem(BuildContext context, Map<String, dynamic> briefing) {
    final date = briefing['date'] as String? ?? '';
    final articleCount = briefing['article_count'] as int? ?? 0;
    // 从categories_json提取分类标签
    String tags = '';
    final categoriesJson = briefing['categories_json'] as String?;
    if (categoriesJson != null && categoriesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(categoriesJson) as Map<String, dynamic>;
        tags = decoded.keys.take(3).join(', ');
      } catch (_) {}
    }

    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            // TODO: 跳转历史简报详情
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: isPressed ? 0.98 : 1.0,
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPressed ? const Color(0xFFF9F9F8) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC4C6CD).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A2B3C).withOpacity(isPressed ? 0.02 : 0.04),
                    blurRadius: isPressed ? 8 : 16,
                    offset: Offset(0, isPressed ? 2 : 4),
                  ),
                ],
              ),
        child: Row(
          children: [
            // 日期图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  date.split('-').last,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2B3C),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '拾光日报 · $date',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A2B3C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tags.isNotEmpty ? '精选 $articleCount 条 · $tags' : '精选 $articleCount 条',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      color: const Color(0xFF74777D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF74777D),
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
},
);
}

  void _showExportSheet(BuildContext context) {
    final briefingId = ref.read(todayBriefingProvider).value?['id'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF9F9F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '导出简报',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B3C),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Color(0xFF1A2B3C)),
                title: Text(
                  'Markdown 格式',
                  style: GoogleFonts.hankenGrotesk(fontSize: 15),
                ),
                subtitle: Text(
                  '适合导入笔记软件',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF74777D),
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (briefingId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('暂无简报可导出')),
                    );
                    return;
                  }
                  try {
                    await ref.read(exportServiceProvider).shareBriefing(briefingId, 'md');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('简报 Markdown 导出成功')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showFloatingSnackBar(context, '导出失败: $e');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Color(0xFF1A2B3C)),
                title: Text(
                  'JSON 格式',
                  style: GoogleFonts.hankenGrotesk(fontSize: 15),
                ),
                subtitle: Text(
                  '包含完整元数据',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF74777D),
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (briefingId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('暂无简报可导出')),
                    );
                    return;
                  }
                  try {
                    await ref.read(exportServiceProvider).shareBriefing(briefingId, 'json');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('简报 JSON 导出成功')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showFloatingSnackBar(context, '导出失败: $e');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 简报生成中视图（嵌入在BriefingScreen内部，保留底部导航）
class _BriefingGeneratingView extends ConsumerStatefulWidget {
  const _BriefingGeneratingView();

  @override
  ConsumerState<_BriefingGeneratingView> createState() => _BriefingGeneratingViewState();
}

class _BriefingGeneratingViewState extends ConsumerState<_BriefingGeneratingView>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;

  int _currentStep = 0;
  bool _isCompleted = false;
  String _headline = '正在为你拾取\n今日之光';

  final List<_LoadingStep> _steps = [
    _LoadingStep(
      icon: Icons.language,
      title: '扫描全网信息源',
      subtitle: '正在拉取 32 个高质量信源',
    ),
    _LoadingStep(
      icon: Icons.psychology,
      title: '提炼核心洞察',
      subtitle: 'AI 深度分析降噪中...',
    ),
    _LoadingStep(
      icon: Icons.auto_awesome,
      title: '排版专属简报',
      subtitle: '应用清晰格式与排版',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _startSimulation();
  }

  void _startSimulation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _currentStep = 0);
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _currentStep = 1);
    });

    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) setState(() => _currentStep = 2);
    });

    Future.delayed(const Duration(milliseconds: 7000), () {
      if (mounted) {
        setState(() {
          _isCompleted = true;
          _headline = '今日简报已就绪';
        });
        _progressController.animateTo(1.0, duration: const Duration(milliseconds: 500));
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 标题
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: Text(
                _headline,
                key: ValueKey(_headline),
                textAlign: TextAlign.center,
                style: GoogleFonts.sourceSerif4(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: const Color(0xFF1A2B3C),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 副标题
            AnimatedOpacity(
              opacity: _isCompleted ? 0 : 1,
              duration: const Duration(milliseconds: 500),
              child: Text(
                '请稍候，AI正在构建您的专属知识晶体',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: const Color(0xFF74777D),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // 进度卡片
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFC4C6CD).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A2B3C).withOpacity(0.04),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 进度条
                  _buildProgressLine(),
                  const SizedBox(height: 24),

                  // 步骤列表
                  ...List.generate(_steps.length, (index) {
                    return _buildStepItem(index);
                  }),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // 完成按钮
            AnimatedOpacity(
              opacity: _isCompleted ? 1 : 0,
              duration: const Duration(milliseconds: 800),
              child: AnimatedSlide(
                offset: _isCompleted ? Offset.zero : const Offset(0, 0.5),
                duration: const Duration(milliseconds: 800),
                child: _isCompleted
                    ? FilledButton.icon(
                        onPressed: () {
                          // 通过provider关闭生成状态，回到简报内容
                          ref.read(briefingGeneratingProvider.notifier).state = false;
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          '查看简报',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2B3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressLine() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEED),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2B3C), Color(0xFFD4AF37)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepItem(int index) {
    final step = _steps[index];
    final isActive = index == _currentStep && !_isCompleted;
    final isCompleted = index < _currentStep || _isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF1A2B3C)
                  : isActive
                      ? const Color(0xFFD4AF37).withOpacity(0.1)
                      : const Color(0xFFF3F4F3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF1A2B3C)
                    : isCompleted
                        ? const Color(0xFF1A2B3C)
                        : const Color(0xFFC4C6CD).withOpacity(0.3),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1A2B3C).withOpacity(0.1),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 20,
                      color: Colors.white,
                    )
                  : AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Icon(
                          step.icon,
                          size: 20,
                          color: isActive
                              ? Color.lerp(
                                  const Color(0xFF1A2B3C),
                                  const Color(0xFFD4AF37),
                                  _pulseController.value,
                                )
                              : const Color(0xFF74777D),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF1A2B3C)
                        : isCompleted
                            ? const Color(0xFF1A2B3C)
                            : const Color(0xFF74777D),
                  ),
                  child: Text(step.title),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 500),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: isActive
                        ? const Color(0xFF44474C)
                        : isCompleted
                            ? const Color(0xFF74777D)
                            : const Color(0xFF74777D).withOpacity(0.5),
                  ),
                  child: Text(step.subtitle),
                ),
              ],
            ),
          ),
          if (isCompleted && !_isCompleted)
            const Icon(
              Icons.check_circle,
              color: Color(0xFFD4AF37),
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _LoadingStep {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LoadingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

