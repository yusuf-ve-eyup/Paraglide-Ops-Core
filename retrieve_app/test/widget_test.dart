import 'package:flutter_test/flutter_test.dart';
import 'package:retrieve_app/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We pass isLoggedIn: false so it shows the LoginScreen
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Verify that the Login screen is shown.
    // We look for text that appears on the LoginScreen.
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Group ID'), findsOneWidget);
    expect(find.text('User ID'), findsOneWidget);
  });
}
