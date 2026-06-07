import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../services/schedule_service.dart';

/// 采集设置页面
/// 对应 PRD 5.12 采集频率与网络策略
class FetchSettingsScreen extends ConsumerStatefulWidget {
  const FetchSettingsScreen({super.key});

  @override
  ConsumerState<FetchSettingsScreen> createState() => _FetchSettingsScreenState();
}

class _FetchSettingsScreenState extends ConsumerState<FetchSettingsScreen> {
  int _fetchInterval = 2;
  bool _wifiOnly = true;
  bool _initialized = false;

  static const _inkBlue = Color(0xFF1A2B3C);

  @override
  Widget build(BuildContext context) {
    // 从数据库加载配置（仅一次）
    final configAsync = ref.watch(userConfigProvider);
    configAsync.whenData((config) {
      if (!_initialized) {
        _fetchInterval = config.fetchInterval;
        _wifiOnly = config.wifiOnly;
        _initialized = true;
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
          '采集设置',
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
            // 采集间隔
            _buildSectionTitle('采集间隔'),
            const SizedBox(height: 12),
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
                    _fetchInterval > 0 ? '每 $_fetchInterval 小时采集一次' : '手动采集',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _inkBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _IntervalOption(1, '1小时', _fetchInterval, _updateInterval),
                      _IntervalOption(2, '2小时', _fetchInterval, _updateInterval),
                      _IntervalOption(4, '4小时', _fetchInterval, _updateInterval),
                      _IntervalOption(0, '手动', _fetchInterval, _updateInterval),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 网络策略
            _buildSectionTitle('网络策略'),
            const SizedBox(height: 12),
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
                children: [
                  _buildNetworkOption(
                    isWifiOnly: true,
                    title: '仅 Wi-Fi',
                    subtitle: '只在 Wi-Fi 环境下采集，节省流量',
                    icon: Icons.wifi,
                  ),
                  const Divider(height: 24),
                  _buildNetworkOption(
                    isWifiOnly: false,
                    title: 'Wi-Fi + 移动数据',
                    subtitle: '允许使用移动网络采集',
                    icon: Icons.signal_cellular_alt,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _updateInterval(int value) {
    setState(() => _fetchInterval = value);
    _saveConfig();
  }

  void _updateWifiOnly(bool value) {
    setState(() => _wifiOnly = value);
    _saveConfig();
  }

  Future<void> _saveConfig() async {
    final db = ref.read(databaseServiceProvider);
    await db.update(
      'user_config',
      {
        'fetch_interval': _fetchInterval,
        'wifi_only': _wifiOnly ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: ['default'],
    );
    refreshData(ref);

    // 同步更新定时任务（仅移动端）
    if (!kIsWeb) {
      await ScheduleService.scheduleFetch(intervalHours: _fetchInterval);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.sourceSerif4(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _inkBlue,
      ),
    );
  }

  Widget _buildNetworkOption({
    required bool isWifiOnly,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _wifiOnly == isWifiOnly;
    return GestureDetector(
      onTap: () => _updateWifiOnly(isWifiOnly),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFD4AF37).withOpacity(0.1)
                  : const Color(0xFFF3F4F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isSelected ? const Color(0xFFD4AF37) : _inkBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
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
                    color: const Color(0xFF74777D),
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: Color(0xFFD4AF37),
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _IntervalOption extends StatelessWidget {
  final int value;
  final String label;
  final int selectedValue;
  final ValueChanged<int> onSelect;

  const _IntervalOption(
    this.value,
    this.label,
    this.selectedValue,
    this.onSelect,
  );

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A2B3C) : const Color(0xFFF3F4F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF1A2B3C),
          ),
        ),
      ),
    );
  }
}
