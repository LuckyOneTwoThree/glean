import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知服务
/// 对应 PRD Phase 5: 采集完成/简报就绪通知
/// 含通知点击跳转回调
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 通知点击回调（由外部设置，如 main.dart 中绑定导航逻辑）
  static void Function(NotificationResponse)? onNotificationTap;

  /// 初始化通知插件（必须在 App 启动时调用）
  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  /// 请求通知权限（iOS 14+ / Android 13+）
  static Future<bool> requestPermission() async {
    if (!_initialized) await init();
    // Android 13+ 需要运行时权限
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    // iOS
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return true;
  }

  /// 采集完成通知
  static Future<void> showFetchNotification({
    required String title,
    required String body,
    int? insertedCount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'glean_fetch',
      '采集通知',
      channelDescription: '资讯采集完成通知',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      0,
      title,
      body,
      details,
      payload: 'fetch',
    );
  }

  /// 简报就绪通知
  static Future<void> showBriefingNotification({
    required String title,
    required String body,
    String? briefingId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'glean_briefing',
      '简报通知',
      channelDescription: '每日简报就绪通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      1,
      title,
      body,
      details,
      payload: 'briefing${briefingId != null ? ':$briefingId' : ''}',
    );
  }

  /// 取消所有通知
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// 通知点击回调
  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // 调用外部设置的回调
    onNotificationTap?.call(response);
  }
}
