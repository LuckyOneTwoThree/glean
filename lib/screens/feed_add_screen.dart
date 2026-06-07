import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../providers/app_state_provider.dart';

/// 添加自定义数据源页面
/// 对应 PRD 4.1 多源资讯采集 - 自定义源
class FeedAddScreen extends ConsumerStatefulWidget {
  const FeedAddScreen({super.key});

  @override
  ConsumerState<FeedAddScreen> createState() => _FeedAddScreenState();
}

class _FeedAddScreenState extends ConsumerState<FeedAddScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  String _feedType = 'rss';
  bool _isTesting = false;
  bool _testSuccess = false;

  static const _inkBlue = Color(0xFF1A2B3C);
  static const _onSurfaceVariant = Color(0xFF44474C);

  final List<_FeedTypeOption> _feedTypes = [
    _FeedTypeOption('rss', 'RSS / Atom', Icons.rss_feed_outlined),
    _FeedTypeOption('html', '网页抓取', Icons.language_outlined),
    _FeedTypeOption('api', 'API 接口', Icons.api_outlined),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          '添加数据源',
          style: GoogleFonts.sourceSerif4(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _inkBlue,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '添加自定义数据源',
              style: GoogleFonts.sourceSerif4(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _inkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '支持 RSS/Atom 订阅源、网页抓取和 API 接口',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: const Color(0xFF74777D),
              ),
            ),
            const SizedBox(height: 24),

            // 数据源类型选择
            Text(
              '数据源类型',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _feedTypes.map((type) {
                final isSelected = _feedType == type.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _feedType = type.id;
                      _testSuccess = false;
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _inkBlue : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? _inkBlue
                              : const Color(0xFFC4C6CD).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type.icon,
                            size: 20,
                            color: isSelected ? Colors.white : _inkBlue,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.label,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : _inkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 名称
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '数据源名称',
                labelStyle: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: _onSurfaceVariant,
                ),
                hintText: '例如：我的技术博客',
              ),
            ),
            const SizedBox(height: 16),

            // URL
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: _feedType == 'rss'
                    ? 'RSS 订阅地址'
                    : _feedType == 'html'
                        ? '网页地址'
                        : 'API 端点',
                labelStyle: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: _onSurfaceVariant,
                ),
                hintText: _feedType == 'rss'
                    ? 'https://example.com/feed.xml'
                    : 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // 测试连接按钮
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _testSuccess ? Icons.check_circle : Icons.wifi_tethering,
                      size: 18,
                      color: _testSuccess ? const Color(0xFF388E3C) : _inkBlue,
                    ),
              label: Text(
                _isTesting
                    ? '测试中...'
                    : _testSuccess
                        ? '连接成功'
                        : '测试连接',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _testSuccess ? const Color(0xFF388E3C) : _inkBlue,
                side: BorderSide(
                  color: _testSuccess ? const Color(0xFF388E3C) : const Color(0xFFC4C6CD),
                ),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 保存按钮
            FilledButton(
              onPressed: _saveFeed,
              child: Text(
                '添加数据源',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _inkBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写地址')),
      );
      return;
    }

    setState(() => _isTesting = true);
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.headers = {'User-Agent': 'Glean/1.0 (RSS Reader)'};
      final response = await dio.get<String>(_urlController.text);
      setState(() {
        _isTesting = false;
        _testSuccess = response.statusCode == 200 && (response.data?.isNotEmpty ?? false);
      });
      if (_testSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接成功！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接失败：未获取到内容')),
        );
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('连接失败: $e')),
      );
    }
  }

  Future<void> _saveFeed() async {
    if (_nameController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写名称和地址')),
      );
      return;
    }

    final feedService = ref.read(feedServiceProvider);
    await feedService.addFeed(
      url: _urlController.text,
      type: _feedType,
      name: _nameController.text,
    );
    refreshData(ref);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数据源添加成功')),
      );
    }
  }
}

class _FeedTypeOption {
  final String id;
  final String label;
  final IconData icon;

  const _FeedTypeOption(this.id, this.label, this.icon);
}
