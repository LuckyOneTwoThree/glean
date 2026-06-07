import 'package:workmanager/workmanager.dart';

import 'database_service.dart';
import 'fetch_service.dart';
import 'feed_service.dart';
import 'notification_service.dart';
import 'score_service.dart';
import 'llm_service.dart';
import 'summary_service.dart';
import 'briefing_service.dart';

/// 定时采集调度服务
/// 对应 PRD Phase 5: 后台任务调度
class ScheduleService {
  static const _fetchTaskName = 'com.glean.fetch';
  static const _briefingTaskName = 'com.glean.briefing';

  /// 初始化 Workmanager（必须在 main 中调用）
  static void init() {
    Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
  }

  /// 注册定时采集任务
  /// [intervalHours] 采集间隔（小时），0表示手动模式（不注册）
  /// [wifiOnly] 是否仅 WiFi 下采集
  static Future<void> scheduleFetch({int intervalHours = 2, bool wifiOnly = true}) async {
    await Workmanager().cancelByUniqueName(_fetchTaskName);

    if (intervalHours <= 0) return;

    await Workmanager().registerPeriodicTask(
      _fetchTaskName,
      _fetchTaskName,
      frequency: Duration(hours: intervalHours),
      constraints: Constraints(
        networkType: wifiOnly ? NetworkType.unmetered : NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  /// 注册简报定时推送任务
  /// [pushTime] 推送时间，格式 "HH:mm"（如 "08:00"），null 或空则不注册
  /// Workmanager 最小周期 15 分钟，使用 periodic task + 时间窗口模拟定时推送
  static Future<void> scheduleBriefing({String? pushTime}) async {
    await Workmanager().cancelByUniqueName(_briefingTaskName);

    if (pushTime == null || pushTime.isEmpty) return;

    // 解析推送时间
    final parts = pushTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    // 计算距离下次推送的初始延迟
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final initialDelay = scheduled.difference(now);

    // 注册每日定时任务（使用 OneOffTask + 初始延迟模拟定时推送）
    // 注意：Workmanager 的 PeriodicTask 最小间隔 15 分钟，无法精确到每天一次
    // 因此使用 registerOneOffTask 配合 initialDelay，执行完后重新注册
    await Workmanager().registerOneOffTask(
      _briefingTaskName,
      _briefingTaskName,
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// 取消所有定时任务
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// 一次性采集（手动触发）
  static Future<void> runOneOffFetch() async {
    await Workmanager().registerOneOffTask(
      '${_fetchTaskName}_oneoff',
      _fetchTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}

/// Workmanager 回调分发器（顶级函数）
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'com.glean.fetch':
          return await _doFetch();
        case 'com.glean.briefing':
          return await _doBriefing();
        default:
          return true;
      }
    } catch (e) {
      return false;
    }
  });
}

/// 后台采集执行
Future<bool> _doFetch() async {
  final dbService = DatabaseService();
  final feedService = FeedService(dbService);
  final fetchService = FetchService(dbService, feedService);

  final result = await fetchService.runFetch();

  // 记录执行日志
  await dbService.insert('execution_logs', {
    'id': 'el${DateTime.now().millisecondsSinceEpoch}_fetch',
    'task_type': 'fetch',
    'status': 'completed',
    'started_at': DateTime.now().millisecondsSinceEpoch,
    'duration': 0,
    'label': '采集 ${result.fetched} 条，新增 ${result.inserted} 条，去重 ${result.deduped} 条',
  });

  // 如果有新文章，发送通知
  if (result.inserted > 0) {
    await NotificationService.showFetchNotification(
      title: '拾光 · 采集完成',
      body: '新增 ${result.inserted} 篇文章，去重 ${result.deduped} 条',
    );
  }

  return true;
}

/// 后台简报生成执行
Future<bool> _doBriefing() async {
  final dbService = DatabaseService();
  final feedService = FeedService(dbService);
  final fetchService = FetchService(dbService, feedService);
  final llmService = LLMService(dbService);
  final scoreService = ScoreService(dbService, llmService);
  final summaryService = SummaryService(dbService, llmService);
  final briefingService = BriefingService(dbService, fetchService, scoreService, summaryService);

  await briefingService.generate('scheduled');

  // 记录执行日志
  await dbService.insert('execution_logs', {
    'id': 'el${DateTime.now().millisecondsSinceEpoch}_briefing',
    'task_type': 'briefing',
    'status': 'completed',
    'started_at': DateTime.now().millisecondsSinceEpoch,
    'duration': 0,
    'label': '简报生成完成',
  });

  await NotificationService.showBriefingNotification(
    title: '拾光 · 简报已就绪',
    body: '今日资讯简报已生成，点击查看',
  );

  // 重新注册明天的简报推送任务
  try {
    final configMaps = await dbService.query('user_config', where: 'id = ?', whereArgs: ['default']);
    if (configMaps.isNotEmpty) {
      final pushTime = configMaps.first['push_time'] as String? ?? '';
      await ScheduleService.scheduleBriefing(pushTime: pushTime);
    }
  } catch (_) {}

  return true;
}
