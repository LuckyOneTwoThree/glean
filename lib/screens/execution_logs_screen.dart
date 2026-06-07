import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';

/// 执行记录页面
/// 对应 PRD 5.13 执行记录
class ExecutionLogsScreen extends ConsumerWidget {
  const ExecutionLogsScreen({super.key});

  static const _inkBlue = Color(0xFF1A2B3C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(executionLogsProvider);

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
          '执行记录',
          style: GoogleFonts.sourceSerif4(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _inkBlue,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseServiceProvider);
              await db.delete('execution_logs');
              refreshData(ref);
            },
            child: Text(
              '清空',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFBA1A1A),
              ),
            ),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: const Color(0xFF74777D).withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('暂无执行记录', style: GoogleFonts.hankenGrotesk(fontSize: 16, color: const Color(0xFF74777D))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogItem(log);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final taskType = log['task_type'] as String? ?? '';
    final status = log['status'] as String? ?? 'running';
    final errorMsg = log['error_message'] as String?;
    final startedAt = log['started_at'] as int? ?? 0;
    final duration = log['duration'] as int?;
    final label = log['label'] as String?;

    final (icon, color) = _getStatusInfo(status);
    final date = DateTime.fromMillisecondsSinceEpoch(startedAt);

    // 构建消息
    String message;
    if (errorMsg != null && errorMsg.isNotEmpty) {
      message = errorMsg;
    } else if (label != null && label.isNotEmpty) {
      message = label;
    } else {
      message = '$taskType ${status == 'completed' ? '完成' : status == 'failed' ? '失败' : '进行中'}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC4C6CD).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        taskType,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF74777D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(date),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF74777D),
                      ),
                    ),
                    const Spacer(),
                    if (duration != null)
                      Text(
                        '${(duration / 1000).toStringAsFixed(0)}s',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: const Color(0xFF74777D),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    color: const Color(0xFF44474C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getStatusInfo(String status) {
    return switch (status) {
      'completed' => (Icons.check_circle_outline, const Color(0xFF388E3C)),
      'failed' => (Icons.error_outline, const Color(0xFFBA1A1A)),
      'running' => (Icons.sync, const Color(0xFFE65100)),
      _ => (Icons.info_outline, const Color(0xFF74777D)),
    };
  }
}
