import 'package:flutter/material.dart';
import '../models/article.dart';
import 'score_badge.dart';

/// 文章卡片组件
class ArticleCard extends StatefulWidget {
  final Article article;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const ArticleCard({
    super.key,
    required this.article,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    
    // 已读文章整体透明度降低
    final opacity = article.isRead ? 0.65 : 1.0;
    final scale = _isPressed ? 0.97 : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE8E8E6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A2B3C).withOpacity(_isPressed ? 0.02 : 0.04),
                  blurRadius: _isPressed ? 10 : 20,
                  offset: Offset(0, _isPressed ? 2 : 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: article.isRead
                              ? const Color(0xFF74777D)
                              : const Color(0xFF1A2B3C),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ScoreBadge(score: article.scoreTotal),
                  ],
                ),
                const SizedBox(height: 8),
                // 摘要
                if (article.summaryOne != null && article.summaryOne!.isNotEmpty)
                  Text(
                    article.summaryOne!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: article.isRead
                          ? const Color(0xFF74777D)
                          : const Color(0xFF44474C).withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                // 底部信息行
                Row(
                  children: [
                    // 来源
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.sourceName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF74777D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 时间
                    Text(
                      _formatTime(article.publishedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF74777D).withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    // 收藏按钮
                    GestureDetector(
                      onTap: widget.onFavoriteToggle,
                      child: Icon(
                        article.isFavorited
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                        color: article.isFavorited
                            ? const Color(0xFFBA1A1A)
                            : const Color(0xFF74777D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}月${date.day}日';
  }
}
