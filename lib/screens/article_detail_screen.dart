import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../providers/app_state_provider.dart';

/// 文章详情页面
/// 对应 UI 设计图 _9/screen.png
class ArticleDetailScreen extends ConsumerStatefulWidget {
  final Article article;

  const ArticleDetailScreen({
    super.key,
    required this.article,
  });

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 进入详情页标记为已读
    Future.microtask(() => markArticleRead(ref, widget.article.id));
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final favoritedIds = ref.watch(favoritedArticleIdsProvider);
    final isFavorited = favoritedIds.contains(article.id);

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2B3C)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              '拾光 / Glean',
              style: GoogleFonts.sourceSerif4(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B3C),
              ),
            ),
            centerTitle: true,
            actions: [
              // 收藏按钮
              IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited
                      ? const Color(0xFFBA1A1A)
                      : const Color(0xFF1A2B3C),
                ),
                onPressed: () async {
                  await toggleFavorite(ref, article.id);
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(!isFavorited ? '已收藏' : '已取消收藏'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          // 文章内容
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // 标题 + 评分
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        style: GoogleFonts.sourceSerif4(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: const Color(0xFF1A2B3C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _ScoreCircle(score: article.scoreTotal),
                  ],
                ),

                const SizedBox(height: 16),

                // 来源 + 时间
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.sourceName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF74777D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDate(article.publishedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF44474C).withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    // AI 评分模式标签
                    if (article.scoreMode == 'llm')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 10,
                              color: const Color(0xFFD4AF37).withOpacity(0.8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'AI评分',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFD4AF37).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // 一句话摘要卡片
                if (article.summaryOne != null && article.summaryOne!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC4C6CD).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.format_quote,
                              size: 16,
                              color: const Color(0xFFD4AF37).withOpacity(0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '一句话摘要',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD4AF37).withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.summaryOne!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: const Color(0xFF44474C).withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // 三要点展开
                if (article.summaryPoints.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC4C6CD).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.list,
                              size: 16,
                              color: const Color(0xFF1A2B3C).withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '核心要点',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A2B3C).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...article.summaryPoints.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final point = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 10, top: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A2B3C).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$index',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A2B3C).withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.55,
                                      color: const Color(0xFF44474C).withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // 评分详情
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC4C6CD).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 16,
                            color: const Color(0xFF1A2B3C).withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI 质量评分',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A2B3C).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ScoreBar(
                        label: '来源可信度',
                        score: article.scoreCredibility,
                        color: const Color(0xFF1A2B3C),
                      ),
                      const SizedBox(height: 12),
                      _ScoreBar(
                        label: '信息密度',
                        score: article.scoreDensity,
                        color: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showScoreExplanation(context),
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 14,
                              color: const Color(0xFF74777D).withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '评分标准说明',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF74777D).withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 正文内容
                if (article.content != null && article.content!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC4C6CD).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 16,
                              color: const Color(0xFF1A2B3C).withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '正文',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A2B3C).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          article.content!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: const Color(0xFF44474C).withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // 底部操作按钮
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.open_in_new,
                        label: '阅读原文',
                        onTap: () => _openOriginalUrl(article.url),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_outlined,
                        label: '分享',
                        onTap: () => _showShareSheet(context, article),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.download_outlined,
                  label: '导出文章 (Markdown / JSON)',
                  onTap: () => _showExportSheet(context, article),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy年MM月dd日 HH:mm').format(date);
  }

  void _showScoreExplanation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF9F9F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '评分标准说明',
              style: GoogleFonts.sourceSerif4(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B3C),
              ),
            ),
            const SizedBox(height: 16),
            _buildScoreExplanationItem(
              '来源可信度',
              '评估信息来源的权威性和可靠性。知名科技媒体、官方博客得分较高，匿名来源或低质量博客得分较低。',
            ),
            const SizedBox(height: 12),
            _buildScoreExplanationItem(
              '信息密度',
              '衡量文章内容的干货程度。包含具体数据、技术细节、独家信息的密度越高，得分越高。',
            ),
            const SizedBox(height: 12),
            _buildScoreExplanationItem(
              '时效性',
              '评估新闻的时效价值。突发新闻、独家报道得分较高，旧闻重复报道得分较低。',
            ),
            const SizedBox(height: 12),
            _buildScoreExplanationItem(
              '综合评分',
              '基于以上维度的加权计算，满分 10 分。8.5 分以上为高质量文章，5 分以下建议跳过。',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreExplanationItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A2B3C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            color: const Color(0xFF44474C),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _openOriginalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }

  void _showShareSheet(BuildContext context, Article article) {
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
                '分享',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B3C),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.link, color: Color(0xFF1A2B3C)),
                title: Text(
                  '复制链接',
                  style: GoogleFonts.hankenGrotesk(fontSize: 15),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('链接已复制到剪贴板')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF1A2B3C)),
                title: Text(
                  '系统分享',
                  style: GoogleFonts.hankenGrotesk(fontSize: 15),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context, Article article) {
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
                '导出文章',
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
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Markdown 导出成功')),
                  );
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
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON 导出成功')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 圆形评分组件
class _ScoreCircle extends StatelessWidget {
  final double score;

  const _ScoreCircle({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          Text(
            '评分',
            style: TextStyle(
              fontSize: 8,
              color: color.withOpacity(0.7),
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8.5) return const Color(0xFFD4AF37);
    if (score >= 7.0) return const Color(0xFF1A2B3C);
    if (score >= 5.0) return const Color(0xFF74777D);
    return const Color(0xFFBA1A1A);
  }
}

/// 评分条组件
class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ScoreBar({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF44474C).withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 10,
              backgroundColor: const Color(0xFFEEEEED),
              color: color.withOpacity(0.6),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          score.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            fontFamily: 'JetBrainsMono',
          ),
        ),
      ],
    );
  }
}

/// 底部操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B3C),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
