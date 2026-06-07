import 'dart:convert';
import '../utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';

/// 简报配置页面 - 关注领域选择
/// 对应 PRD 4.4 简报配置
/// 与 Onboarding Step1 共享同一套领域列表，数据从数据库加载/保存
class BriefingConfigScreen extends ConsumerStatefulWidget {
  const BriefingConfigScreen({super.key});

  @override
  ConsumerState<BriefingConfigScreen> createState() => _BriefingConfigScreenState();
}

class _BriefingConfigScreenState extends ConsumerState<BriefingConfigScreen> {
  Set<String> _selectedDomains = {};
  bool _loaded = false;

  // 与 Onboarding Step1 保持一致的领域列表
  static const _domains = [
    _DomainOption('AI', 'AI', Icons.smart_toy_outlined),
    _DomainOption('科技商业', '科技商业', Icons.trending_up_outlined),
    _DomainOption('技术', '技术', Icons.code_outlined),
    _DomainOption('消费科技', '消费科技', Icons.devices_outlined),
    _DomainOption('前沿科技', '前沿科技', Icons.rocket_launch_outlined),
    _DomainOption('效率工具', '效率工具', Icons.speed_outlined),
    _DomainOption('综合科技', '综合科技', Icons.public_outlined),
    _DomainOption('开源生态', '开源生态', Icons.source_outlined),
    _DomainOption('产品与设计', '产品与设计', Icons.palette_outlined),
    _DomainOption('安全与隐私', '安全与隐私', Icons.shield_outlined),
    _DomainOption('云与基础设施', '云与基础设施', Icons.cloud_outlined),
    _DomainOption('科技文化', '科技文化', Icons.auto_stories_outlined),
  ];

  static const _inkBlue = Color(0xFF1A2B3C);
  static const _goldenHour = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    // 从数据库加载当前配置
    final configAsync = ref.watch(userConfigProvider);
    configAsync.whenData((config) {
      if (!_loaded) {
        _loaded = true;
        setState(() {
          _selectedDomains = Set<String>.from(config.categories);
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
          '关注领域',
          style: GoogleFonts.sourceSerif4(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _inkBlue,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择你感兴趣的领域',
                    style: GoogleFonts.sourceSerif4(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: _inkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '至少选择 1 个领域，系统将按此筛选资讯',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      color: const Color(0xFF74777D),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _domains.map((domain) {
                      final isSelected = _selectedDomains.contains(domain.id);
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(domain.icon, size: 16),
                            const SizedBox(width: 6),
                            Text(domain.label),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDomains.add(domain.id);
                            } else {
                              if (_selectedDomains.length > 1) {
                                _selectedDomains.remove(domain.id);
                              }
                            }
                          });
                        },
                        selectedColor: _inkBlue,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : _inkBlue,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? _inkBlue
                                : const Color(0xFFC4C6CD).withOpacity(0.3),
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          // 底部保存按钮
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFC4C6CD).withOpacity(0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: FilledButton(
                onPressed: _save,
                child: Text(
                  '保存 (${_selectedDomains.length} 个领域)',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final configAsync = ref.read(userConfigProvider);
    configAsync.whenData((config) async {
      final newConfig = config.copyWith(
        categories: _selectedDomains.toList(),
      );
      await saveUserConfig(ref, newConfig);

      if (mounted) {
        showFloatingSnackBar(context, '已保存 ${_selectedDomains.length} 个关注领域');
        Navigator.of(context).pop();
      }
    });
  }
}

class _DomainOption {
  final String id;
  final String label;
  final IconData icon;
  const _DomainOption(this.id, this.label, this.icon);
}
