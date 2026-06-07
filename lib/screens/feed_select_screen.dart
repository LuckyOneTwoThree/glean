import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/feed.dart';
import '../providers/app_state_provider.dart';
import 'feed_add_screen.dart';

/// 数据源管理页面
/// 对应 PRD 4.1 多源资讯采集 / UI _6
class FeedSelectScreen extends ConsumerStatefulWidget {
  const FeedSelectScreen({super.key});

  @override
  ConsumerState<FeedSelectScreen> createState() => _FeedSelectScreenState();
}

class _FeedSelectScreenState extends ConsumerState<FeedSelectScreen> {
  List<Feed> _feeds = [];
  bool _isLoading = true;

  static const _inkBlue = Color(0xFF1A2B3C);
  static const _onSurfaceVariant = Color(0xFF44474C);

  // 数据源图标颜色映射
  static const _feedColors = <String, (Color, Color)>{
    'preset_qbitai': (Color(0xFFE3F2FD), Color(0xFF1976D2)),
    'preset_36kr': (Color(0xFFE0F7FA), Color(0xFF00838F)),
    'preset_infoq': (Color(0xFFFBE9E7), Color(0xFFD84315)),
    'preset_ifanr': (Color(0xFFFFF3E0), Color(0xFFE65100)),
    'preset_sspai': (Color(0xFFFFF3E0), Color(0xFFE65100)),
    'preset_ithome': (Color(0xFFE8F5E9), Color(0xFF388E3C)),
    'preset_jqzx': (Color(0xFFE3F2FD), Color(0xFF1976D2)),
    'preset_huxiu': (Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
    'preset_techcrunch': (Color(0xFFE8F5E9), Color(0xFF388E3C)),
    'preset_verge': (Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
    'preset_hn': (Color(0xFFE3F2FD), Color(0xFF1976D2)),
    'preset_arst': (Color(0xFFFBE9E7), Color(0xFFD84315)),
    'preset_mittr': (Color(0xFFE0F7FA), Color(0xFF00838F)),
    'preset_wired': (Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
    'preset_openai': (Color(0xFFE3F2FD), Color(0xFF1976D2)),
    'preset_googleai': (Color(0xFFE8F5E9), Color(0xFF388E3C)),
  };

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    final feedService = ref.read(feedServiceProvider);
    final feeds = await feedService.getAllFeeds();
    if (mounted) {
      setState(() {
        _feeds = feeds;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFeed(Feed feed) async {
    final feedService = ref.read(feedServiceProvider);
    await feedService.toggleFeed(feed.id);
    await _loadFeeds();
    // 刷新 feedsProvider 缓存
    refreshData(ref);
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = _feeds.where((f) => f.isEnabled).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _inkBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '数据源管理',
          style: GoogleFonts.sourceSerif4(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _inkBlue,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push(CupertinoPageRoute(builder: (_) => const FeedAddScreen()))
                  .then((_) => _loadFeeds());
            },
            child: Text(
              '添加',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _inkBlue,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 已启用数量
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '已启用 $enabledCount 个数据源',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          color: const Color(0xFF74777D),
                        ),
                      ),
                    ],
                  ),
                ),

                // 数据源列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _feeds.length,
                    itemBuilder: (context, index) {
                      final feed = _feeds[index];
                      return _buildFeedCard(feed);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeedCard(Feed feed) {
    final colors = _feedColors[feed.id] ??
        (const Color(0xFFF3F4F3), const Color(0xFF74777D));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: feed.isEnabled
              ? _inkBlue.withOpacity(0.3)
              : const Color(0xFFC4C6CD).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.$1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                feed.name.length > 2
                    ? feed.name.substring(0, 2)
                    : feed.name,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.$2,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feed.name,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _inkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feed.category ?? feed.type,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: _onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      feed.isDomestic ? Icons.location_on : Icons.public,
                      size: 12,
                      color: _onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      feed.isDomestic ? 'DOMESTIC' : 'GLOBAL',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        color: _onSurfaceVariant.withOpacity(0.5),
                        letterSpacing: 0.04,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 开关
          Switch(
            value: feed.isEnabled,
            onChanged: (value) => _toggleFeed(feed),
          ),
        ],
      ),
    );
  }
}
