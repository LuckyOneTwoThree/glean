import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/app_state_provider.dart';
import '../utils/snackbar_util.dart';
import 'briefing_loading_screen.dart';
import 'home_screen.dart';

/// Onboarding 流程（6步）
/// Step 0: 欢迎页 → Step 1: 领域选择 → Step 2: 数据源选择
/// → Step 3: 偏好配置 → Step 4: LLM配置(可选) → Step 5: 生成简报
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 6;

  // 配置状态
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedFeeds = {
    'preset_hn', 'preset_sspai', 'preset_36kr',
    'preset_jiqizhixin',
  };
  String _aiMode = 'hybrid';
  double _domesticRatio = 0.5;
  int _dailyCount = 20;

  // LLM 配置状态
  String _llmProvider = 'mimo';
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _obscureApiKey = true;

  static const _inkBlue = Color(0xFF1A2B3C);
  static const _goldenHour = Color(0xFFD4AF37);
  static const _onSurfaceVariant = Color(0xFF44474C);
  static const _surfaceContainerHigh = Color(0xFFE8E8E7);

  // 方向选项（对齐 BriefingService.categoryKeywords 的 key）
  final List<_CategoryOption> _categories = [
    _CategoryOption('AI', 'AI', Icons.smart_toy_outlined),
    _CategoryOption('科技商业', '科技商业', Icons.trending_up_outlined),
    _CategoryOption('技术', '技术', Icons.code_outlined),
    _CategoryOption('消费科技', '消费科技', Icons.devices_outlined),
    _CategoryOption('前沿科技', '前沿科技', Icons.rocket_launch_outlined),
    _CategoryOption('效率工具', '效率工具', Icons.speed_outlined),
    _CategoryOption('综合科技', '综合科技', Icons.public_outlined),
    _CategoryOption('开源生态', '开源生态', Icons.source_outlined),
    _CategoryOption('产品与设计', '产品与设计', Icons.palette_outlined),
    _CategoryOption('安全与隐私', '安全与隐私', Icons.shield_outlined),
    _CategoryOption('云与基础设施', '云与基础设施', Icons.cloud_outlined),
    _CategoryOption('科技文化', '科技文化', Icons.auto_stories_outlined),
  ];

  // 数据源选项（ID 对齐数据库种子数据 preset_*）
  final List<_FeedOption> _feeds = [
    // 国际源
    _FeedOption(
      'preset_hn',
      'Hacker News',
      '全球最大技术社区，深度工程讨论。',
      'H',
      const Color(0xFFE3F2FD),
      const Color(0xFF1976D2),
      true,
      'GLOBAL',
    ),
    _FeedOption(
      'preset_techcrunch',
      'TechCrunch',
      '全球科技创业与投资新闻。',
      'T',
      const Color(0xFFE8F5E9),
      const Color(0xFF388E3C),
      false,
      'GLOBAL',
    ),
    _FeedOption(
      'preset_verge',
      'The Verge',
      '科技、科学、艺术与文化跨界报道。',
      'V',
      const Color(0xFFF3E5F5),
      const Color(0xFF7B1FA2),
      false,
      'GLOBAL',
    ),
    _FeedOption(
      'preset_arstechnica',
      'Ars Technica',
      '深度技术分析与安全报道。',
      'A',
      const Color(0xFFFCE4EC),
      const Color(0xFFC62828),
      false,
      'GLOBAL',
    ),
    _FeedOption(
      'preset_thehackernews',
      'The Hacker News',
      '网络安全与隐私最新动态。',
      'TH',
      const Color(0xFFFFF3E0),
      const Color(0xFFE65100),
      false,
      'GLOBAL',
    ),
    _FeedOption(
      'preset_devto',
      'Dev.to',
      '开发者社区，技术教程与实践分享。',
      'D',
      const Color(0xFFE0F2F1),
      const Color(0xFF00695C),
      false,
      'GLOBAL',
    ),
    // 国内源
    _FeedOption(
      'preset_sspai',
      '少数派 (sspai)',
      '高质量数字生活与效率工具。',
      '少数',
      const Color(0xFFFFF8E1),
      const Color(0xFFE65100),
      true,
      'DOMESTIC',
    ),
    _FeedOption(
      'preset_36kr',
      '36氪',
      '中国科技商业与创业投资。',
      '36',
      const Color(0xFFE3F2FD),
      const Color(0xFF0D47A1),
      true,
      'DOMESTIC',
    ),
    _FeedOption(
      'preset_jiqizhixin',
      '机器之心',
      'AI 与前沿技术深度报道。',
      '机',
      const Color(0xFFF3E5F5),
      const Color(0xFF4A148C),
      true,
      'DOMESTIC',
    ),
    _FeedOption(
      'preset_infoq',
      'InfoQ 中文',
      '技术架构与研发实践。',
      'IQ',
      const Color(0xFFE8F5E9),
      const Color(0xFF1B5E20),
      false,
      'DOMESTIC',
    ),
    _FeedOption(
      'preset_qianxin',
      '奇安信威胁情报',
      '网络安全威胁与漏洞预警。',
      '奇',
      const Color(0xFFFBE9E7),
      const Color(0xFFBF360C),
      false,
      'DOMESTIC',
    ),
    _FeedOption(
      'preset_jike',
      '即刻热门',
      '年轻人科技生活与趋势讨论。',
      '即',
      const Color(0xFFFCE4EC),
      const Color(0xFFAD1457),
      false,
      'DOMESTIC',
    ),
  ];

  // AI 模式选项
  final List<_AIModeOption> _aiModes = [
    _AIModeOption('economy', '省钱模式', '纯本地规则评分，零 API 费用', Icons.savings_outlined),
    _AIModeOption('quality', '质量模式', 'LLM 深度分析，最高筛选精度', Icons.auto_awesome_outlined),
    _AIModeOption('hybrid', '混合模式', '本地初筛 + LLM 精选，推荐', Icons.tune_outlined),
  ];

  // LLM 提供商选项
  final List<_LLMProviderOption> _llmProviders = [
    _LLMProviderOption('mimo', 'MiMo', '小米大模型，免费额度充足', Icons.psychology_outlined),
    _LLMProviderOption('deepseek', 'DeepSeek', '高性价比推理模型', Icons.auto_awesome_outlined),
    _LLMProviderOption('openai', 'OpenAI', 'GPT 系列模型', Icons.smart_toy_outlined),
    _LLMProviderOption('custom', '自定义', '兼容 OpenAI 接口的任意服务', Icons.settings_outlined),
  ];

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
        title: Text(
          '拾光 / Glean',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _completeOnboarding,
            child: Text(
              '跳过',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: _onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度指示器
          _buildProgressIndicator(),

          // 页面内容
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(),
            ),
          ),

          // 底部按钮
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ==================== 进度指示器 ====================

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? _goldenHour : _surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==================== 步骤内容 ====================

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Welcome();
      case 1:
        return _buildStep1Categories();
      case 2:
        return _buildStep2Feeds();
      case 3:
        return _buildStep3Preferences();
      case 4:
        return _buildStep4LLMConfig();
      case 5:
        return _buildStep5Generate();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 0: 欢迎页
  Widget _buildStep0Welcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Logo / 品牌图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _inkBlue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _inkBlue.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            '拾光',
            style: GoogleFonts.sourceSerif4(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: _inkBlue,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Glean',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: _goldenHour,
              letterSpacing: 4,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            '你的 AI 科技日报',
            style: GoogleFonts.sourceSerif4(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _inkBlue,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            '从全球优质信源中，为你筛选、评分、摘要\n每天只需 5 分钟，掌握科技前沿',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              color: _onSurfaceVariant,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 48),

          // 特性列表
          _buildFeatureItem(Icons.rss_feed_outlined, '多源采集', 'RSS/Atom 全网科技信源'),
          const SizedBox(height: 16),
          _buildFeatureItem(Icons.auto_awesome_outlined, 'AI 筛选', '智能评分 + 深度摘要'),
          const SizedBox(height: 16),
          _buildFeatureItem(Icons.newspaper_outlined, '每日简报', '个性化定制，按领域分组'),
          const SizedBox(height: 16),
          _buildFeatureItem(Icons.download_outlined, '数据导出', 'Markdown / JSON 随心分享'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC4C6CD).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _inkBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _inkBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: 方向选择
  Widget _buildStep1Categories() {
    return _StepContainer(
      title: '内容方向',
      subtitle: '选择你关注的领域，我们将据此筛选和评分你的每日简报。',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _categories.map((cat) {
          final isSelected = _selectedCategories.contains(cat.id);
          return ChoiceChip(
            label: Text(cat.label),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedCategories.add(cat.id);
                } else {
                  _selectedCategories.remove(cat.id);
                }
              });
            },
            avatar: Icon(cat.icon, size: 18),
            selectedColor: _inkBlue,
            backgroundColor: const Color(0xFFF3F4F3),
            labelStyle: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : _inkBlue,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: isSelected ? _inkBlue : const Color(0xFFC4C6CD).withOpacity(0.3),
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
        }).toList(),
      ),
    );
  }

  /// Step 2: 数据源选择
  Widget _buildStep2Feeds() {
    return _StepContainer(
      title: '精选信源',
      subtitle: '选择构成你每日简报的频道，我们已预选高信噪比的优质出版物。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Color(0xFF44474C)),
              hintText: '搜索出版物或粘贴 URL',
              suffixIcon: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加\n信源'),
                style: TextButton.styleFrom(
                  foregroundColor: _inkBlue,
                  textStyle: GoogleFonts.hankenGrotesk(fontSize: 11),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 分类标题
          Text(
            '科技与洞察',
            style: GoogleFonts.sourceSerif4(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _inkBlue,
            ),
          ),

          const SizedBox(height: 16),

          // 数据源列表
          ..._feeds.map((feed) {
            final isSelected = _selectedFeeds.contains(feed.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC4C6CD).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: feed.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        feed.iconText,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: feed.iconText.length > 1 ? 14 : 20,
                          fontWeight: FontWeight.w700,
                          color: feed.iconColor,
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
                          feed.description,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            color: _onSurfaceVariant,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              feed.scope == 'GLOBAL'
                                  ? Icons.public
                                  : Icons.location_on,
                              size: 12,
                              color: _onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              feed.scope,
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
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value) {
                          _selectedFeeds.add(feed.id);
                        } else {
                          _selectedFeeds.remove(feed.id);
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Step 3: 偏好配置（AI 模式 + 地域 + 数量）
  Widget _buildStep3Preferences() {
    return _StepContainer(
      title: '偏好精调',
      subtitle: '校准你的每日简报偏好。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 模式选择
          Text(
            'AI 模式',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _inkBlue,
            ),
          ),
          const SizedBox(height: 12),
          ..._aiModes.map((mode) {
            final isSelected = _aiMode == mode.id;
            return GestureDetector(
              onTap: () => setState(() => _aiMode = mode.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? _inkBlue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _inkBlue
                        : const Color(0xFFC4C6CD).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mode.icon,
                      color: isSelected ? Colors.white : _inkBlue,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.name,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : _inkBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.description,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : _onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // 地域偏好卡片
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFC4C6CD).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '地域\n聚焦',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _inkBlue,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      _getBalanceText(),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _goldenHour,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 滑块
                Slider(
                  value: _domesticRatio,
                  onChanged: (value) {
                    // 吸附到 5% 梯度（0.05 步进，对应 20 篇文章每篇 5%）
                    final snapped = (value * 20).round() / 20;
                    setState(() => _domesticRatio = snapped);
                  },
                  divisions: 20,
                  label: _getBalanceText(),
                  activeColor: _inkBlue,
                  inactiveColor: const Color(0xFFEEEEED),
                ),

                // 标签
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '国内 ${(_domesticRatio * 100).round()}%',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _inkBlue,
                      ),
                    ),
                    Text(
                      '国际 ${100 - (_domesticRatio * 100).round()}%',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _inkBlue,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 48),

                // 信息密度
                Text(
                  '信息密度',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _inkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '选择你偏好的每日阅读量。',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    color: _onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // 数量选择
                Row(
                  children: [10, 20, 30, 50].map((count) {
                    final isSelected = _dailyCount == count;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _dailyCount = count),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? _inkBlue : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? _inkBlue
                                  : const Color(0xFFC4C6CD).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$count',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : _inkBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '篇',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : _onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 4: LLM 配置（可选，省钱模式可跳过）
  Widget _buildStep4LLMConfig() {
    final isEconomy = _aiMode == 'economy';
    final needsLLM = !isEconomy;

    return _StepContainer(
      title: 'AI 接入',
      subtitle: needsLLM
          ? '配置 LLM API 以启用 AI 深度分析和摘要。'
          : '省钱模式无需 API Key，如需升级可在设置中配置。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEconomy) ...[
            // 省钱模式提示
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, color: _inkBlue, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '省钱模式已选择',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _inkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '所有评分和摘要将在本地完成，无需 API Key。你可以随时在设置中升级到质量模式或混合模式。',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            color: _onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 提供商选择
            Text(
              '选择提供商',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _inkBlue,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _llmProviders.map((provider) {
                final isSelected = _llmProvider == provider.id;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(provider.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(provider.name),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _llmProvider = provider.id),
                  selectedColor: _inkBlue,
                  backgroundColor: const Color(0xFFF3F4F3),
                  labelStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : _inkBlue,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // API Key
            Text(
              'API Key',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _inkBlue,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                hintText: '输入你的 API Key',
                suffixIcon: IconButton(
                  icon: Icon(_obscureApiKey ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Base URL（仅自定义模式显示）
            if (_llmProvider == 'custom') ...[
              Text(
                'Base URL',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _inkBlue,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  hintText: 'https://api.example.com/v1',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 模型名称
            Text(
              '模型名称',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _inkBlue,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _modelController,
              decoration: InputDecoration(
                hintText: _llmProvider == 'mimo'
                    ? '默认: MiMo-7B-RL'
                    : _llmProvider == 'deepseek'
                        ? '默认: deepseek-chat'
                        : _llmProvider == 'openai'
                            ? '默认: gpt-4o-mini'
                            : '输入模型名称',
              ),
            ),

            const SizedBox(height: 20),

            // 提示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: _goldenHour, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'API Key 仅存储在本地，不会上传到任何服务器。你也可以稍后在设置中配置。',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Step 5: 生成第一份简报
  Widget _buildStep5Generate() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          // 配置摘要卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFC4C6CD).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: _inkBlue.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checklist_rtl_outlined, color: _goldenHour, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      '配置摘要',
                      style: GoogleFonts.sourceSerif4(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _inkBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSummaryRow('关注领域', '${_selectedCategories.length} 个领域'),
                const SizedBox(height: 12),
                _buildSummaryRow('数据源', '${_selectedFeeds.length} 个信源'),
                const SizedBox(height: 12),
                _buildSummaryRow('AI 模式', _aiModes.firstWhere((m) => m.id == _aiMode).name),
                const SizedBox(height: 12),
                _buildSummaryRow('地域偏好', '国内 ${(_domesticRatio * 100).round()}% / 国际 ${100 - (_domesticRatio * 100).round()}%'),
                const SizedBox(height: 12),
                _buildSummaryRow('每日简报', '$_dailyCount 篇'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            '一切就绪',
            style: GoogleFonts.sourceSerif4(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _inkBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击下方按钮，拾光将为你采集信源\n并生成第一份专属简报',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              color: _onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            color: _onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _inkBlue,
          ),
        ),
      ],
    );
  }

  String _getBalanceText() {
    final domestic = (_domesticRatio * 100).round();
    final global = 100 - domestic;
    if (domestic == 50) return '均衡\n(50/50)';
    if (domestic > 50) return '国内侧重\n($domestic/$global)';
    return '国际侧重\n($domestic/$global)';
  }

  // ==================== 底部按钮 ====================

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFC4C6CD).withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentStep == 2)
              // Step 2: 显示已选择数量 + 继续按钮
              Row(
                children: [
                  Text(
                    '已选择 ${_selectedFeeds.length} 个信源',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _goNext,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '继续配置',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else if (isLastStep)
              // 最后一步：生成简报按钮
              FilledButton.icon(
                onPressed: _completeOnboarding,
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: Text(
                  '开启我的拾光之旅',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              FilledButton(
                onPressed: _goNext,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '继续',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),

            if (!isLastStep) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  '暂时跳过',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    color: _onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _goNext() {
    // 校验当前步骤
    if (_currentStep == 1 && _selectedCategories.isEmpty) {
      showFloatingSnackBar(context, '请至少选择一个关注领域');
      return;
    }
    if (_currentStep == 2 && _selectedFeeds.isEmpty) {
      showFloatingSnackBar(context, '请至少选择一个数据源');
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    // 持久化配置到数据库
    if (!kIsWeb) {
      try {
        // 读取现有配置，合并 onboarding 字段后保存
        final db = ref.read(databaseServiceProvider);
        final results = await db.query('user_config', where: 'id = ?', whereArgs: ['default']);
        final existing = results.isNotEmpty ? UserConfig.fromMap(results.first) : const UserConfig();
        final newConfig = existing.copyWith(
          categories: _selectedCategories.toList(),
          domesticRatio: _domesticRatio,
          dailyCount: _dailyCount,
          aiMode: _aiMode,
        );
        await saveUserConfig(ref, newConfig);

        // 启用选中的数据源，禁用未选中的
        final feedService = ref.read(feedServiceProvider);
        final allFeeds = await feedService.getAllFeeds();
        for (final feed in allFeeds) {
          final shouldEnable = _selectedFeeds.contains(feed.id);
          if (feed.isEnabled != shouldEnable) {
            await feedService.toggleFeed(feed.id);
          }
        }

        // 保存 LLM 配置（如果用户填写了）
        if (_apiKeyController.text.isNotEmpty) {
          final llmResults = await db.query('llm_config', where: 'id = ?', whereArgs: ['default']);
          final llmExisting = llmResults.isNotEmpty
              ? LLMConfig.fromMap(llmResults.first)
              : const LLMConfig();

          String baseUrl = _baseUrlController.text.trim();
          String model = _modelController.text.trim();
          if (_llmProvider == 'mimo') {
            baseUrl = baseUrl.isEmpty ? 'https://api.maimiao.cn/v1' : baseUrl;
            model = model.isEmpty ? 'MiMo-7B-RL' : model;
          } else if (_llmProvider == 'deepseek') {
            baseUrl = baseUrl.isEmpty ? 'https://api.deepseek.com/v1' : baseUrl;
            model = model.isEmpty ? 'deepseek-chat' : model;
          } else if (_llmProvider == 'openai') {
            baseUrl = baseUrl.isEmpty ? 'https://api.openai.com/v1' : baseUrl;
            model = model.isEmpty ? 'gpt-4o-mini' : model;
          }

          final newLLMConfig = llmExisting.copyWith(
            provider: _llmProvider,
            apiKey: _apiKeyController.text.trim(),
            baseUrl: baseUrl,
            model: model,
          );
          await saveLLMConfig(ref, newLLMConfig);
        }

        refreshData(ref);
      } catch (e) {
        debugPrint('Onboarding save error: $e');
      }
    }

    // 跳转到简报生成加载页
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (_) => BriefingLoadingScreen(
          nextScreen: const HomeScreen(),
          showCompletionButton: true,
        ),
      ),
    );

    // 延迟设置 onboarding 完成，避免 GleanApp 重建导致导航冲突
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(onboardingDoneProvider.notifier).state = true;
      if (!kIsWeb) {
        final db = ref.read(databaseServiceProvider);
        db.update(
          'user_config',
          {'onboarding_done': 1},
          where: 'id = ?',
          whereArgs: ['default'],
        );
      }
    });
  }
}

// ==================== 辅助组件 ====================

class _StepContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepContainer({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  static const _inkBlue = Color(0xFF1A2B3C);
  static const _onSurfaceVariant = Color(0xFF44474C);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: ValueKey(title),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sourceSerif4(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: _inkBlue,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              color: _onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

// ==================== 数据类 ====================

class _CategoryOption {
  final String id;
  final String label;
  final IconData icon;
  const _CategoryOption(this.id, this.label, this.icon);
}

class _FeedOption {
  final String id;
  final String name;
  final String description;
  final String iconText;
  final Color bgColor;
  final Color iconColor;
  final bool defaultSelected;
  final String scope;
  const _FeedOption(
    this.id,
    this.name,
    this.description,
    this.iconText,
    this.bgColor,
    this.iconColor,
    this.defaultSelected,
    this.scope,
  );
}

class _AIModeOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  const _AIModeOption(this.id, this.name, this.description, this.icon);
}

class _LLMProviderOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  const _LLMProviderOption(this.id, this.name, this.description, this.icon);
}
