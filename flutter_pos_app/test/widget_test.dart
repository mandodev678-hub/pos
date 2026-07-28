import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pos_app/main.dart';

void main() {
  testWidgets('POS App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZimamPosApp());
  });
}
