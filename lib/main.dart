import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/schedule_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化后台任务调度（仅移动端）
  if (!kIsWeb) {
    ScheduleService.init();
    await NotificationService.init();
  }

  runApp(const ProviderScope(child: GleanApp()));
}
