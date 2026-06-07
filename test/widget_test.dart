import 'package:flutter_test/flutter_test.dart';
import 'package:glean/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GleanApp()),
    );
    // 验证应用能启动
    expect(find.byType(GleanApp), findsOneWidget);
  });
}
