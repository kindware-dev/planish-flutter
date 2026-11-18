import 'package:planish/planish.dart';
import 'package:planish_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home page renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Planish.init(
      PlanishConfig(
        sender: const CallbackFeedbackSender(_ignore),
        captureDebugPrint: false,
      ),
    );
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Send feedback'), findsWidgets);
  });
}

Future<void> _ignore(FeedbackReport _) async {}
