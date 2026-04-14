import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/presentation/screens/intruder/intruder_logs_screen.dart';
import 'package:cover/core/intruder/intruder_detection_service.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  IntruderDetectionService,
])
import 'intruder_logs_screen_test.mocks.dart';

void main() {
  group('IntruderLogsScreen', () {
    late MockIntruderDetectionService mockIntruderService;

    setUp(() {
      mockIntruderService = MockIntruderDetectionService();
    });

    testWidgets('should display loading indicator initially', (tester) async {
      // Arrange
      when(mockIntruderService.getIntruderLogs()).thenAnswer((_) async => []);
      when(mockIntruderService.isEnabled).thenReturn(true);

      await tester.pumpProvider(
        overrides: [
          intruderDetectionServiceProvider.overrideWithValue(mockIntruderService),
        ],
        (ref) => const ProviderScope(
          child: MaterialApp(
            home: IntruderLogsScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no logs', (tester) async {
      // Arrange
      when(mockIntruderService.getIntruderLogs()).thenAnswer((_) async => []);
      when(mockIntruderService.isEnabled).thenReturn(true);

      await tester.pumpProvider(
        overrides: [
          intruderDetectionServiceProvider.overrideWithValue(mockIntruderService),
        ],
        (ref) => const ProviderScope(
          child: MaterialApp(
            home: IntruderLogsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No Intruder Logs'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('should display logs when available', (tester) async {
      // Arrange
      final logs = [
        IntruderLog(
          id: 1,
          vaultId: null,
          timestamp: DateTime.now(),
          eventType: 'wrong_pin',
          encryptedPhotoPath: 'photo1.jpg',
          encryptedLocation: 'encrypted_location',
          metadata: '{}',
        ),
        IntruderLog(
          id: 2,
          vaultId: null,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          eventType: 'screenshot',
          encryptedPhotoPath: 'photo2.jpg',
          encryptedLocation: null,
          metadata: '{}',
        ),
      ];
      when(mockIntruderService.getIntruderLogs()).thenAnswer((_) async => logs);
      when(mockIntruderService.isEnabled).thenReturn(true);

      await tester.pumpProvider(
        overrides: [
          intruderDetectionServiceProvider.overrideWithValue(mockIntruderService),
        ],
        (ref) => const ProviderScope(
          child: MaterialApp(
            home: IntruderLogsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Wrong PIN Attempt'), findsOneWidget);
      expect(find.text('Screenshot Detected'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('should show filter bar', (tester) async {
      // Arrange
      when(mockIntruderService.getIntruderLogs()).thenAnswer((_) async => []);
      when(mockIntruderService.isEnabled).thenReturn(true);

      await tester.pumpProvider(
        overrides: [
          intruderDetectionServiceProvider.overrideWithValue(mockIntruderService),
        ],
        (ref) => const ProviderScope(
          child: MaterialApp(
            home: IntruderLogsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('should navigate to detail screen on tap', (tester) async {
      // Arrange
      final logs = [
        IntruderLog(
          id: 1,
          vaultId: null,
          timestamp: DateTime.now(),
          eventType: 'wrong_pin',
          encryptedPhotoPath: 'photo1.jpg',
          encryptedLocation: 'encrypted_location',
          metadata: '{}',
        ),
      ];
      when(mockIntruderService.getIntruderLogs()).thenAnswer((_) async => logs);
      when(mockIntruderService.isEnabled).thenReturn(true);

      await tester.pumpProvider(
        overrides: [
          intruderDetectionServiceProvider.overrideWithValue(mockIntruderService),
        ],
        (ref) => const ProviderScope(
          child: MaterialApp(
            home: IntruderLogsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Wrong PIN Attempt'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Log Details'), findsOneWidget);
    });

    testWidgets('should show delete confirmation', (tester) async {
      // Arrange
      final logs = [
        IntruderLog(
          id: 1,
          vaultId: null,
          timestamp: DateTime.now(),
          eventType: 'wrong_pin',
          encryptedPhotoPath: 'photo1.jpg',
          encryptedLocation: null,
          metadata: '{}',
        ),
      ];
      when(mockIntruderService.getIntruderLogs()).thenAnswer((_) async => logs);
      when(mockIntruderService.deleteIntruderLog(1)).thenAnswer((_) async {});
      when(mockIntruderService.isEnabled).thenReturn(true);

      await tester.pumpProvider(
        overrides: [
          intruderDetectionServiceProvider.overrideWithValue(mockIntruderService),
        ],
        (ref) => const ProviderScope(
          child: MaterialApp(
            home: IntruderLogsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear All Logs'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Clear All Logs'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
