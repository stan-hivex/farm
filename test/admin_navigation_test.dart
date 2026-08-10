import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farm/admin/core/admin_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('replaceAllWithBuilder removes previous routes and keeps only the target', (
      tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const FirstScreen(),
      ),
    );

    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const SecondScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Second screen'), findsOneWidget);

    AuthNavigation.replaceAllWithBuilder(
      navigatorKey.currentContext!,
      (_) => const ThirdScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Second screen'), findsNothing);
    expect(find.text('Third screen'), findsOneWidget);
  });
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('First screen')));
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Second screen')));
  }
}

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Third screen')));
  }
}
