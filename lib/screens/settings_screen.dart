import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import 'briefing_config_screen.dart';
import 'feed_select_screen.dart';
import 'llm_config_screen.dart';
import 'data_management_screen.dart';
import 'fetch_settings_screen.dart';
import 'execution_logs_screen.dart';

/// 设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showRatioSlider = false;
  bool _showDailyTotal = false;
  double _ratio = 0.5;
  int _dailyTotal = 20;
  String _categories = '';
  String _aiMode = 'hybrid';
  String _provider = 'mimo';
  int _retentionDays = 30;
  int _fetchInterval = 2;
  bool _wifiOnly = true;
  bool _configLoaded = false;

  static const _inkBlue = Color(0xFF1A2B3C);

  static const _aiModeLabels = {
    'economy': '省钱模式 (纯本地规则)',
    'quality': '质量模式 (LLM 深度分析)',
    'hybrid': '混合模式 (平衡成本与质量)',
  };

  static const _providerLabels = {
    'mimo': 'MiMo',
    'openai': 'OpenAI',
    'deepseek': 'DeepSeek',
    'custom': '自定义',
  };

  @override
  Widget build(BuildContext context) {
    // 从数据库加载配置
    final configAsync = ref.watch(userConfigProvider);
    configAsync.whenData((config) {
      setState(() {
        _ratio = config.domesticRatio;
        _dailyTotal = config.dailyCount;
        _aiMode = config.aiMode;
        _retentionDays = config.retentionDays;
        _fetchInterval = config.fetchInterval;
        _wifiOnly = config.wifiOnly;
        _categories = config.categories.join(', ');
        if (!_configLoaded) _configLoaded = true;
      });
    });

    // 读取 LLM 配置
    final llmConfigAsync = ref.watch(llmConfigProvider);
    llmConfigAsync.whenData((config) {
      _provider = config.provider;
    });

    // 读取 feeds 数量
    final feedsAsync = ref.watch(feedsProvider);
    final enabledFeedsCount = feedsAsync.whenData((feeds) {
      return feeds.where((f) => f['is_enabled'] == 1).length;
    }).value ?? 0;

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
              '设置',
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

          // 简报配置
          SliverToBoxAdapter(
            child: _buildSectionHeader('简报配置'),
          ),
          SliverToBoxAdapter(
            child: _buildSettingsCard([
              _SettingsItem(
                title: '关注领域',
                subtitle: _categories,
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF74777D)),
                onTap: () => _navigateTo(context, const BriefingConfigScreen()),
              ),
              _buildDivider(),
              _SettingsItem(
                title: '数据源管理',
                subtitle: '已启用 $enabledFeedsCount 个来源',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF74777D)),
                onTap: () => _navigateTo(context, const FeedSelectScreen()),
              ),
              _buildDivider(),
              // 国内/国际比例 - 点击展开
              Column(
                children: [
                  _SettingsItem(
                    title: '国内/国际比例',
                    subtitle: _ratioLabel(_ratio),
                    trailing: AnimatedRotation(
                      turns: _showRatioSlider ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, color: Color(0xFF74777D)),
                    ),
                    onTap: () => setState(() => _showRatioSlider = !_showRatioSlider),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Slider(
                            value: _ratio,
                            onChanged: (value) {
                              // 吸附到 5% 梯度（0.05 步进，对应 20 篇文章每篇 5%）
                              final snapped = (value * 20).round() / 20;
                              setState(() => _ratio = snapped);
                              _saveConfig('domestic_ratio', snapped);
                            },
                            divisions: 20,
                            label: _ratioLabel(_ratio),
                            activeColor: _inkBlue,
                            inactiveColor: const Color(0xFFEEEEED),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '国内 ${(_ratio * 100).round()}%',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _inkBlue,
                                ),
                              ),
                              Text(
                                '国际 ${100 - (_ratio * 100).round()}%',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _inkBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: _showRatioSlider
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
              _buildDivider(),
              // 每日总量 - 点击展开
              Column(
                children: [
                  _SettingsItem(
                    title: '每日总量',
                    subtitle: '$_dailyTotal 条',
                    trailing: AnimatedRotation(
                      turns: _showDailyTotal ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, color: Color(0xFF74777D)),
                    ),
                    onTap: () => setState(() => _showDailyTotal = !_showDailyTotal),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Wrap(
                        spacing: 8,
                        children: [10, 15, 20, 30, 50].map((v) {
                          final isSelected = v == _dailyTotal;
                          return ChoiceChip(
                            label: Text('$v 条'),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _dailyTotal = v);
                              _saveConfig('daily_count', v);
                            },
                            selectedColor: _inkBlue,
                            backgroundColor: const Color(0xFFF3F4F3),
                            labelStyle: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : _inkBlue,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                    ),
                    crossFadeState: _showDailyTotal
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ]),
          ),

          // AI 设置
          SliverToBoxAdapter(
            child: _buildSectionHeader('AI 设置'),
          ),
          SliverToBoxAdapter(
            child: _buildSettingsCard([
              _SettingsItem(
                title: 'AI 模式',
                subtitle: _aiModeLabels[_aiMode] ?? _aiMode,
                trailing: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 18),
                onTap: () => _navigateTo(context, const LLMConfigScreen()),
              ),
              _buildDivider(),
              _SettingsItem(
                title: 'LLM 提供商配置',
                subtitle: _providerLabels[_provider] ?? _provider,
                trailing: const Icon(Icons.tune, color: Color(0xFF74777D)),
                onTap: () => _navigateTo(context, const LLMConfigScreen()),
              ),
              _buildDivider(),
              _SettingsItem(
                title: '成本监控',
                subtitle: '查看本月 Token 消耗',
                trailing: const Icon(Icons.credit_card, color: Color(0xFF74777D), size: 18),
                onTap: () => _navigateTo(context, const LLMConfigScreen()),
              ),
            ]),
          ),

          // 数据管理
          SliverToBoxAdapter(
            child: _buildSectionHeader('数据管理'),
          ),
          SliverToBoxAdapter(
            child: _buildSettingsCard([
              _SettingsItem(
                title: '存储占用',
                subtitle: '管理本地数据',
                trailing: TextButton(
                  onPressed: () => _navigateTo(context, const DataManagementScreen()),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFBA1A1A),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '清理',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onTap: () => _navigateTo(context, const DataManagementScreen()),
              ),
              _buildDivider(),
              _SettingsItem(
                title: '数据导出',
                subtitle: '导出为 Markdown 或 JSON',
                trailing: const Icon(Icons.download, color: Color(0xFF74777D), size: 18),
                onTap: () => _navigateTo(context, const DataManagementScreen()),
              ),
              _buildDivider(),
              _SettingsItem(
                title: '数据保留天数',
                subtitle: '$_retentionDays 天',
                trailing: const Icon(Icons.history, color: Color(0xFF74777D), size: 18),
                onTap: () => _navigateTo(context, const DataManagementScreen()),
              ),
            ]),
          ),

          // 采集设置
          SliverToBoxAdapter(
            child: _buildSectionHeader('采集设置'),
          ),
          SliverToBoxAdapter(
            child: _buildSettingsCard([
              _SettingsItem(
                title: '采集间隔',
                subtitle: '每 $_fetchInterval 小时',
                trailing: const Icon(Icons.timer, color: Color(0xFF74777D), size: 18),
                onTap: () => _navigateTo(context, const FetchSettingsScreen()),
              ),
              _buildDivider(),
              _SettingsItem(
                title: '网络策略',
                subtitle: _wifiOnly ? '仅在 Wi-Fi 下采集' : '任何网络均可采集',
                trailing: const Icon(Icons.wifi, color: Color(0xFF74777D), size: 18),
                onTap: () => _navigateTo(context, const FetchSettingsScreen()),
              ),
              _buildDivider(),
              _SettingsItem(
                title: '立即采集',
                subtitle: '手动触发一次资讯采集',
                trailing: const Icon(Icons.download_outlined, color: Color(0xFF74777D), size: 18),
                onTap: () async {
                  if (!kIsWeb) {
                    await runFetch(ref);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(kIsWeb ? 'Web端暂不支持后台采集' : '采集任务已启动')),
                    );
                  }
                },
              ),
            ]),
          ),

          // 执行记录
          SliverToBoxAdapter(
            child: _buildSectionHeader('执行记录'),
          ),
          SliverToBoxAdapter(
            child: _buildSettingsCard([
              _SettingsItem(
                title: '查看系统日志',
                subtitle: '查看采集和生成记录',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF74777D)),
                onTap: () => _navigateTo(context, const ExecutionLogsScreen()),
              ),
            ]),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Future<void> _saveConfig(String key, dynamic value) async {
    final db = ref.read(databaseServiceProvider);
    await db.update(
      'user_config',
      {key: value},
      where: 'id = ?',
      whereArgs: ['default'],
    );
    refreshData(ref);
  }

  /// 比例标签：国内 X% · 国际 Y%
  static String _ratioLabel(double ratio) {
    final domestic = (ratio * 100).round();
    final international = 100 - domestic;
    return '国内 $domestic% · 国际 $international%';
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// 分组标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF44474C),
          letterSpacing: 0.04,
        ),
      ),
    );
  }

  /// 设置卡片
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC4C6CD).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// 分隔线
  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: const Color(0xFFC4C6CD).withOpacity(0.2),
    );
  }
}

/// 设置项组件
class _SettingsItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A2B3C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF74777D),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
