import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/llm_config.dart';
import '../providers/app_state_provider.dart';

/// AI 模式与 LLM 配置页面
/// 对应 PRD 4.9 LLM 提供商配置 / 5.7 AI 运行模式管理
class LLMConfigScreen extends ConsumerStatefulWidget {
  const LLMConfigScreen({super.key});

  @override
  ConsumerState<LLMConfigScreen> createState() => _LLMConfigScreenState();
}

class _LLMConfigScreenState extends ConsumerState<LLMConfigScreen> {
  String _aiMode = 'hybrid';
  String _provider = 'mimo';
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool _llmConfigLoaded = false;
  bool _userConfigLoaded = false;

  static const _inkBlue = Color(0xFF1A2B3C);
  static const _goldenHour = Color(0xFFD4AF37);
  static const _onSurfaceVariant = Color(0xFF44474C);

  final List<_AIModeOption> _aiModes = [
    _AIModeOption('economy', '省钱模式', '纯本地规则评分，零 API 费用', Icons.savings_outlined, '零成本'),
    _AIModeOption('quality', '质量模式', 'LLM 深度分析，最高筛选精度', Icons.auto_awesome_outlined, '按量计费'),
    _AIModeOption('hybrid', '混合模式', '本地初筛 + LLM 精选，推荐', Icons.tune_outlined, '低成本'),
  ];

  final List<_ProviderOption> _providers = [
    _ProviderOption('mimo', 'MiMo', 'https://token-plan-cn.xiaomimimo.com/v1', 'mimo-v2.5-pro'),
    _ProviderOption('openai', 'OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini'),
    _ProviderOption('deepseek', 'DeepSeek', 'https://api.deepseek.com/v1', 'deepseek-chat'),
    _ProviderOption('custom', '自定义', '', ''),
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
    // 从数据库加载配置
    final llmConfigAsync = ref.watch(llmConfigProvider);
    llmConfigAsync.whenData((config) {
      if (!_llmConfigLoaded) {
        _llmConfigLoaded = true;
        setState(() {
          _provider = config.provider;
          _apiKeyController.text = config.apiKey ?? '';
          _baseUrlController.text = config.baseUrl ??
              _providers.firstWhere((p) => p.id == _provider, orElse: () => _providers.first).baseUrl;
          _modelController.text = config.model;
        });
      }
    });

    final userConfigAsync = ref.watch(userConfigProvider);
    userConfigAsync.whenData((config) {
      if (!_userConfigLoaded) {
        _userConfigLoaded = true;
        setState(() {
          _aiMode = config.aiMode;
        });
      }
    });

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
          'AI 设置',
          style: GoogleFonts.sourceSerif4(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _inkBlue,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveAll,
            child: Text(
              '保存',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _goldenHour,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI 模式选择
            Text(
              'AI 运行模式',
              style: GoogleFonts.sourceSerif4(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _inkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择 AI 评分和摘要的生成方式',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: const Color(0xFF74777D),
              ),
            ),
            const SizedBox(height: 16),

            ..._aiModes.map((mode) {
              final isSelected = _aiMode == mode.id;
              return GestureDetector(
                onTap: () => setState(() => _aiMode = mode.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _goldenHour.withOpacity(0.2)
                              : const Color(0xFFF3F4F3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          mode.icon,
                          color: isSelected ? _goldenHour : _inkBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  mode.name,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : _inkBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.2)
                                        : const Color(0xFFF3F4F3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    mode.cost,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF74777D),
                                    ),
                                  ),
                                ),
                              ],
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
                          color: _goldenHour,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),

            // LLM 提供商配置
            Text(
              'LLM 提供商配置',
              style: GoogleFonts.sourceSerif4(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _inkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '配置 LLM API 以使用质量模式或混合模式',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: const Color(0xFF74777D),
              ),
            ),
            const SizedBox(height: 16),

            // 提供商选择
            Container(
              padding: const EdgeInsets.all(16),
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
                  Text(
                    '选择提供商',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _providers.map((p) {
                      final isSelected = _provider == p.id;
                      return ChoiceChip(
                        label: Text(p.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _provider = p.id;
                              _baseUrlController.text = p.baseUrl;
                              _modelController.text = p.defaultModel;
                            });
                          }
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

                  const SizedBox(height: 20),

                  // API Key
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      labelStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: _onSurfaceVariant,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                          color: const Color(0xFF74777D),
                        ),
                        onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Base URL
                  TextField(
                    controller: _baseUrlController,
                    decoration: InputDecoration(
                      labelText: 'Base URL',
                      labelStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 模型名称
                  TextField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: '模型名称',
                      labelStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 连通性测试按钮
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering, size: 18),
                    label: Text(
                      _isTesting ? '测试中...' : '测试连通性',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _inkBlue,
                      side: const BorderSide(color: Color(0xFFC4C6CD)),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 成本监控
            _buildCostMonitor(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCostMonitor() {
    // 从数据库读取真实 token 消耗
    return FutureBuilder<int>(
      future: _getMonthlyTokenUsage(),
      builder: (context, snapshot) {
        final used = snapshot.data ?? 0;
        final budget = 100000; // 默认预算 100k tokens
        final ratio = budget > 0 ? used / budget : 0.0;
        final isOverBudget = ratio > 1.0;

        return Container(
          padding: const EdgeInsets.all(16),
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
              Text(
                '本月消耗',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _formatTokenCount(used),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _inkBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'tokens / 预算 ${_formatTokenCount(budget)} tokens',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      color: const Color(0xFF74777D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0, 1.5),
                  backgroundColor: const Color(0xFFEEEEED),
                  color: isOverBudget ? const Color(0xFFBA1A1A) : _inkBlue,
                  minHeight: 8,
                ),
              ),
              if (isOverBudget) ...[
                const SizedBox(height: 8),
                Text(
                  '已超出预算，建议切换到省钱模式',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: const Color(0xFFBA1A1A),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<int> _getMonthlyTokenUsage() async {
    if (kIsWeb) return 0;
    try {
      final db = ref.read(databaseServiceProvider);
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final results = await db.rawQuery(
        "SELECT SUM(token_count) as total FROM execution_logs WHERE timestamp >= ? AND task_type IN ('score_llm', 'summary_llm')",
        [monthStart],
      );
      return (results.first['total'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String _formatTokenCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入 API Key')),
      );
      return;
    }

    setState(() => _isTesting = true);
    try {
      final llmService = ref.read(llmServiceProvider);
      final config = LLMConfig(
        provider: _provider,
        apiKey: _apiKeyController.text,
        baseUrl: _baseUrlController.text.isEmpty ? null : _baseUrlController.text,
        model: _modelController.text.isEmpty ? 'mimo' : _modelController.text,
      );
      final result = await llmService.testConnection(config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? '连接成功！延迟 ${result.latency}ms'
              : '连接失败：${result.errorMessage ?? "未知错误"}'),
          backgroundColor: result.success ? Colors.green : const Color(0xFFBA1A1A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('测试出错：$e')),
      );
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _saveAll() async {
    if (kIsWeb) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final db = ref.read(databaseServiceProvider);

    // 保存 AI 模式到 user_config（统一使用 economy/quality/hybrid）
    await db.update(
      'user_config',
      {'ai_mode': _aiMode},
      where: 'id = ?',
      whereArgs: ['default'],
    );

    // 保存 LLM 配置到 llm_config
    await db.update(
      'llm_config',
      {
        'provider': _provider,
        'api_key': _apiKeyController.text,
        'base_url': _baseUrlController.text,
        'model': _modelController.text,
      },
      where: 'id = ?',
      whereArgs: ['default'],
    );

    refreshData(ref);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
      Navigator.of(context).pop();
    }
  }
}

class _AIModeOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String cost;

  const _AIModeOption(
    this.id,
    this.name,
    this.description,
    this.icon,
    this.cost,
  );
}

class _ProviderOption {
  final String id;
  final String name;
  final String baseUrl;
  final String defaultModel;

  const _ProviderOption(
    this.id,
    this.name,
    this.baseUrl,
    this.defaultModel,
  );
}
