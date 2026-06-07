import 'package:flutter/foundation.dart';
import '../utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../services/database_service.dart';

/// 数据管理页面
/// 对应 PRD 4.8 数据导出 / 5.6 数据生命周期管理
class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  static const _inkBlue = Color(0xFF1A2B3C);
  static const _onSurfaceVariant = Color(0xFF44474C);
  int _retentionDays = 30;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    // 从数据库加载保留天数
    final configAsync = ref.watch(userConfigProvider);
    configAsync.whenData((config) {
      if (!_initialized) {
        _retentionDays = config.retentionDays;
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
          '数据管理',
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
            // 存储占用
            _buildSectionTitle('存储占用'),
            const SizedBox(height: 12),
            _buildStorageCard(),

            const SizedBox(height: 32),

            // 数据导出
            _buildSectionTitle('数据导出'),
            const SizedBox(height: 12),
            _buildExportCard(
              context,
              icon: Icons.article_outlined,
              title: '单篇导出',
              subtitle: '导出当前查看的文章',
              formats: 'JSON / Markdown',
              onExport: () => _exportArticle(context),
            ),
            const SizedBox(height: 8),
            _buildExportCard(
              context,
              icon: Icons.description_outlined,
              title: '简报导出',
              subtitle: '导出当前简报的所有文章',
              formats: 'JSON / Markdown',
              onExport: () => _exportBriefing(context),
            ),
            const SizedBox(height: 8),
            _buildExportCard(
              context,
              icon: Icons.folder_zip_outlined,
              title: '全量导出',
              subtitle: '导出所有数据（含配置）',
              formats: 'ZIP',
              onExport: () => _exportAll(context),
            ),

            const SizedBox(height: 32),

            // 数据保留
            _buildSectionTitle('数据保留'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '数据保留天数',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _inkBlue,
                        ),
                      ),
                      Text(
                        '$_retentionDays 天',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _inkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '超过保留天数的非收藏文章将被自动清理',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: const Color(0xFF74777D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [7, 14, 30, 60, 90].map((days) {
                      final isSelected = days == _retentionDays;
                      return ChoiceChip(
                        label: Text('$days 天'),
                        selected: isSelected,
                        onSelected: (_) => _updateRetentionDays(days),
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
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 手动清理
            _buildSectionTitle('手动清理'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _cleanupExpiredData,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                '清理过期数据',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBA1A1A),
                side: const BorderSide(color: Color(0xFFBA1A1A)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _clearAllData,
              icon: const Icon(Icons.cleaning_services_outlined, size: 18),
              label: Text(
                '清空所有文章和简报',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBA1A1A),
                side: const BorderSide(color: Color(0xFFBA1A1A)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _resetDatabase,
              icon: const Icon(Icons.restore, size: 18),
              label: Text(
                '重置数据库（恢复初始状态）',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBA1A1A),
                side: const BorderSide(color: Color(0xFFBA1A1A)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    final db = ref.read(databaseServiceProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getStorageStats(db),
      builder: (context, snapshot) {
        final articleCount = snapshot.data?[0]['count'] as int? ?? 0;
        final briefingCount = snapshot.data?[1]['count'] as int? ?? 0;
        final scoreCount = snapshot.data?[2]['count'] as int? ?? 0;

        // 粗略估算：每条文章约20KB，每条简报约5KB，每条评分约2KB
        final articleMB = (articleCount * 20 / 1024).toStringAsFixed(0);
        final briefingMB = (briefingCount * 5 / 1024).toStringAsFixed(0);
        final scoreMB = (scoreCount * 2 / 1024).toStringAsFixed(0);
        final totalMB = (articleCount * 20 + briefingCount * 5 + scoreCount * 2) / 1024;
        final totalStr = totalMB < 1 ? '${(totalMB * 1024).toStringAsFixed(0)} KB' : '${totalMB.toStringAsFixed(1)} MB';

        return Container(
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Text(
                    totalStr,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _inkBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '本地数据库',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      color: const Color(0xFF74777D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StorageItem('文章', '$articleCount 条', const Color(0xFF1A2B3C)),
                  _StorageItem('简报', '$briefingCount 条', const Color(0xFFD4AF37)),
                  _StorageItem('评分', '$scoreCount 条', const Color(0xFF74777D)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getStorageStats(DatabaseService db) async {
    final articles = await db.rawQuery('SELECT COUNT(*) as count FROM articles');
    final briefings = await db.rawQuery('SELECT COUNT(*) as count FROM briefings');
    final scores = await db.rawQuery('SELECT COUNT(*) as count FROM scores');
    return [articles.first, briefings.first, scores.first];
  }

  void _updateRetentionDays(int days) {
    setState(() => _retentionDays = days);
    _saveConfig();
  }

  Future<void> _saveConfig() async {
    final db = ref.read(databaseServiceProvider);
    await db.update(
      'user_config',
      {'retention_days': _retentionDays},
      where: 'id = ?',
      whereArgs: ['default'],
    );
    refreshData(ref);
  }

  Future<void> _cleanupExpiredData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '确认清理？',
          style: GoogleFonts.sourceSerif4(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '将清理超过 $_retentionDays 天的非收藏文章，此操作不可撤销。',
          style: GoogleFonts.hankenGrotesk(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认清理'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseServiceProvider);
      final cutoff = DateTime.now()
          .subtract(Duration(days: _retentionDays))
          .millisecondsSinceEpoch;
      await db.delete(
        'articles',
        where: 'fetched_at < ? AND is_favorited = 0',
        whereArgs: [cutoff],
      );
      refreshData(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('清理完成')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '确认清空所有数据？',
          style: GoogleFonts.sourceSerif4(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '将删除所有文章、简报、评分和日志数据，保留配置和数据源设置。此操作不可撤销。',
          style: GoogleFonts.hankenGrotesk(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseServiceProvider);
      await db.clearAllData();
      refreshData(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有数据已清空')),
        );
      }
    }
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '确认重置数据库？',
          style: GoogleFonts.sourceSerif4(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '将删除数据库并重建，所有配置、数据源和文章数据都将丢失，恢复为初始状态。此操作不可撤销。',
          style: GoogleFonts.hankenGrotesk(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseServiceProvider);
      await db.resetDatabase();
      refreshData(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据库已重置，请重启应用')),
        );
      }
    }
  }

  Future<void> _exportArticle(BuildContext context) async {
    final articlesAsync = ref.read(todayBriefingArticlesProvider);
    final articles = articlesAsync.value ?? [];
    if (articles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无文章可导出')),
        );
      }
      return;
    }
    try {
      final articleId = articles.first.id;
      await ref.read(exportServiceProvider).shareArticle(articleId, 'md');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('单篇导出成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        showFloatingSnackBar(context, '导出失败: $e');
      }
    }
  }

  Future<void> _exportBriefing(BuildContext context) async {
    final briefingAsync = ref.read(todayBriefingProvider);
    final briefingId = briefingAsync.value?['id'] as String?;
    if (briefingId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无简报可导出')),
        );
      }
      return;
    }
    try {
      await ref.read(exportServiceProvider).shareBriefing(briefingId, 'md');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('简报导出成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        showFloatingSnackBar(context, '导出失败: $e');
      }
    }
  }

  Future<void> _exportAll(BuildContext context) async {
    try {
      await ref.read(exportServiceProvider).shareAll('json');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('全量导出成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        showFloatingSnackBar(context, '导出失败: $e');
      }
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

  Widget _buildExportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String formats,
    required VoidCallback onExport,
  }) {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _inkBlue, size: 20),
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
          TextButton(
            onPressed: onExport,
            child: Text(
              formats,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _inkBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StorageItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            color: const Color(0xFF74777D),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A2B3C),
          ),
        ),
      ],
    );
  }
}
