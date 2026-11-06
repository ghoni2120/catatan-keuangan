import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:catatan_keuangan/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App basic smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CatatanKeuanganApp());
    await tester.pumpAndSettle();
    expect(find.byType(CatatanKeuanganApp), findsOneWidget);
  });
}
