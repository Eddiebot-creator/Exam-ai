import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_exam_assistant/main.dart';

void main() {
  testWidgets('renders onboarding screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ExamAssistantApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ExamAI'), findsOneWidget);
    expect(find.text('Upload your notes'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
