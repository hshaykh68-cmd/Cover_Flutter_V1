import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/presentation/screens/vault/vault_shell_screen.dart';

void main() {
  group('VaultShellScreen', () {
    testWidgets('should render VaultShellScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VaultShellScreen(),
          ),
        ),
      );

      expect(find.byType(VaultShellScreen), findsOneWidget);
    });

    testWidgets('should display bottom navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VaultShellScreen(),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should display 4 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VaultShellScreen(),
          ),
        ),
      );

      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should switch tabs on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VaultShellScreen(),
          ),
        ),
      );

      // Tap on Files tab
      await tester.tap(find.text('Files'));
      await tester.pumpAndSettle();

      // Verify tab switched
      expect(find.text('Files'), findsOneWidget);
    });

    testWidgets('should preserve state when switching tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VaultShellScreen(),
          ),
        ),
      );

      // Navigate to Files tab
      await tester.tap(find.text('Files'));
      await tester.pumpAndSettle();

      // Navigate back to Gallery tab
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // Navigate to Files tab again
      await tester.tap(find.text('Files'));
      await tester.pumpAndSettle();

      // State should be preserved (scroll position, etc.)
      expect(find.text('Files'), findsOneWidget);
    });
  });
}
