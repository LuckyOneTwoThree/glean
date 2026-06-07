import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/snackbar_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/article.dart';
import '../providers/app_state_provider.dart';
import '../widgets/article_card.dart';
import 'article_detail_screen.dart';
import '../widgets/shimmer.dart';

/// 收藏页面
/// 对应 PRD 5.1 文章收藏
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider);
    final favoritedIds = ref.watch(favoritedArticleIdsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      body: CustomScrollView(
        slivers: [
          // 顶部 AppBar
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFFF9F9F8),
            title: Text(
              '收藏',
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

          // 收藏文章列表
          articlesAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            data: (articles) {
              final favoritedArticles = articles
                  .map((map) => Article.fromMap(map))
                  .where((a) => favoritedIds.contains(a.id))
                  .toList();

              if (favoritedArticles.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyFavoritesState(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final article = favoritedArticles[index];
                    return Dismissible(
                      key: ValueKey(article.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: const Color(0xFFBA1A1A).withOpacity(0.9),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                      ),
                      onDismissed: (_) {
                        toggleFavorite(ref, article.id);
                        showFloatingSnackBar(
                          context,
                          '已取消收藏',
                        );
                      },
                      child: ArticleCard(
                        article: article,
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => ArticleDetailScreen(article: article),
                            ),
                          );
                        },
                        onFavoriteToggle: () {
                          toggleFavorite(ref, article.id);
                        },
                      ),
                    );
                  },
                  childCount: favoritedArticles.length,
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

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

/// 空收藏状态
class _EmptyFavoritesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: const Color(0xFF74777D).withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏文章',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF74777D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击文章卡片上的收藏图标收藏',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: const Color(0xFF74777D).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
