import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/article.dart';
import '../providers/app_state_provider.dart';
import '../widgets/article_card.dart';
import 'briefing_screen.dart';
import 'settings_screen.dart';
import 'article_detail_screen.dart';
import 'favorites_screen.dart';

/// 首页当前tab索引
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// 首页
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          _HomeTab(),
          BriefingScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A2B3C).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(ref, 0, Icons.home, '首页'),
                _buildNavItem(ref, 1, Icons.auto_awesome, '简报'),
                _buildNavItem(ref, 2, Icons.bookmark, '收藏'),
                _buildNavItem(ref, 3, Icons.settings, '设置'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(WidgetRef ref, int index, IconData icon, String label) {
    final currentIndex = ref.watch(homeTabIndexProvider);
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        ref.read(homeTabIndexProvider.notifier).state = index;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEEEED) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF1A2B3C) : const Color(0xFF74777D),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF1A2B3C) : const Color(0xFF74777D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 首页标签内容
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider);
    final filter = ref.watch(homeFilterProvider);
    final sort = ref.watch(homeSortProvider);

    return CustomScrollView(
      slivers: [
        // 顶部 AppBar
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
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

        // 今日简报卡片
        SliverToBoxAdapter(
          child: _buildBriefingCard(context, ref),
        ),

        // 筛选标签栏
        SliverToBoxAdapter(
          child: _buildFilterBar(context, ref, filter, sort),
        ),

        // 文章列表
        articlesAsync.when(
          data: (articles) {
            if (articles.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: const Color(0xFFC4C6CD),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '暂无文章',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          color: const Color(0xFF74777D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                                        onPressed: () async {
                          try {
                            await runFetch(ref);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('采集失败: $e')),
                              );
                            }
                          }
                        },
                                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '采集',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2B3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                                      ),
                    ],
                  ),
                ),
              );
            }

            final articleList = articles
                .map((map) => Article.fromMap(map))
                .toList();

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final article = articleList[index];
                  return ArticleCard(
                    article: article,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailScreen(article: article),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      toggleFavorite(ref, article.id);
                    },
                  );
                },
                childCount: articleList.length,
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => SliverFillRemaining(
            child: Center(child: Text('加载失败: $err')),
          ),
        ),

        // 底部留白
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  /// 今日简报卡片
  Widget _buildBriefingCard(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final briefingAsync = ref.watch(todayBriefingProvider);

    // 从简报数据提取统计和AI洞察
    final articleCount = briefingAsync.value?['article_count'] as int? ?? 0;
    final domesticCount = briefingAsync.value?['domestic_count'] as int? ?? 0;
    final internationalCount = briefingAsync.value?['international_count'] as int? ?? 0;
    final aiInsight = briefingAsync.value?['ai_insight'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        // 跳转到简报页面
        ref.read(homeTabIndexProvider.notifier).state = 1;
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8E8E6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A2B3C).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 右上角装饰渐变
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(80),
                  ),
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '今日简报 · $dateStr',
                            style: GoogleFonts.sourceSerif4(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A2B3C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            articleCount > 0
                                ? '今日精选 $articleCount 条 | 国内 $domesticCount 条 · 国际 $internationalCount 条'
                                : '今日简报尚未生成',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF74777D),
                              fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // AI 图标
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                    ),
                  ],
                ),

                // 分割线带 psychology 图标
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Divider(
                        height: 1,
                        color: const Color(0xFFE8E8E6),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.white,
                        child: Icon(
                          Icons.psychology,
                          size: 16,
                          color: const Color(0xFF1A2B3C).withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),

                // AI Insight 卡片
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E2E2),
                      width: 1,
                    ),
                  ),
                  child: RichText(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: const Color(0xFF1A2B3C),
                        fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
                      ),
                      children: [
                        const TextSpan(
                          text: 'AI Insight: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        TextSpan(
                          text: aiInsight.isNotEmpty
                              ? aiInsight
                              : '今日简报尚未生成，点击生成专属资讯简报',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 筛选标签栏
  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    String filter,
    String sort,
  ) {
    final filters = [
      ('all', '全部'),
      ('unread', '未读'),
      ('favorited', '收藏'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 筛选标签
            ...filters.map((item) {
              final isActive = filter == item.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    ref.read(homeFilterProvider.notifier).state = item.$1;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF1A2B3C)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isActive
                          ? null
                          : Border.all(
                              color: const Color(0xFFE8E8E6),
                            ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1A2B3C).withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      item.$2,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.02,
                        color: isActive ? Colors.white : const Color(0xFF74777D),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 16),
            // 排序按钮
            Row(
              children: [
                // 评分排序
                GestureDetector(
                  onTap: () {
                    ref.read(homeSortProvider.notifier).state = 'score';
                  },
                  child: Row(
                    children: [
                      Text(
                        '评分',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.04,
                          color: sort == 'score'
                              ? const Color(0xFF1A2B3C)
                              : const Color(0xFF74777D),
                        ),
                      ),
                      if (sort == 'score')
                        const Icon(
                          Icons.arrow_downward,
                          size: 14,
                          color: Color(0xFF1A2B3C),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 分隔线
                Container(
                  width: 1,
                  height: 12,
                  color: const Color(0xFFE8E8E6),
                ),
                const SizedBox(width: 8),
                // 时间排序
                GestureDetector(
                  onTap: () {
                    ref.read(homeSortProvider.notifier).state = 'time';
                  },
                  child: Row(
                    children: [
                      Text(
                        '时间',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.04,
                          color: sort == 'time'
                              ? const Color(0xFF1A2B3C)
                              : const Color(0xFF74777D),
                        ),
                      ),
                      if (sort == 'time')
                        const Icon(
                          Icons.unfold_more,
                          size: 14,
                          color: Color(0xFF1A2B3C),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}


