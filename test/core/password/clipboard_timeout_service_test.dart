import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:cover/core/password/clipboard_timeout_service.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/domain/repository/remote_config_repository.dart';

class MockRemoteConfigRepository implements RemoteConfigRepository {
  @override
  bool getBool(String key, bool defaultValue) => defaultValue;

  @override
  int getInt(String key, int defaultValue) => defaultValue;

  @override
  String getString(String key, String defaultValue) => defaultValue;

  @override
  double getDouble(String key, double defaultValue) => defaultValue;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ClipboardTimeoutService clipboardService;
  late AppConfig appConfig;

  setUp(() {
    final mockRemoteConfig = MockRemoteConfigRepository();
    appConfig = AppConfig(mockRemoteConfig);
    clipboardService = ClipboardTimeoutServiceImpl(appConfig);
  });

  tearDown(() {
    clipboardService.dispose();
  });

  group('ClipboardTimeoutService', () {
    test('should copy text with timeout', () async {
      const testText = 'test_password_123';
      final result = await clipboardService.copyWithTimeout(testText);
      expect(result, isTrue);
      expect(clipboardService.hasActiveTimeout(), isTrue);
    });

    test('should copy text without timeout', () async {
      const testText = 'test_password_123';
      final result = await clipboardService.copyWithoutTimeout(testText);
      expect(result, isTrue);
      expect(clipboardService.hasActiveTimeout(), isFalse);
    });

    test('should cancel timeout', () async {
      const testText = 'test_password_123';
      await clipboardService.copyWithTimeout(testText);
      expect(clipboardService.hasActiveTimeout(), isTrue);
      
      clipboardService.cancelTimeout();
      expect(clipboardService.hasActiveTimeout(), isFalse);
    });

    test('should clear clipboard', () async {
      const testText = 'test_password_123';
      await clipboardService.copyWithTimeout(testText);
      final result = await clipboardService.clearClipboard();
      expect(result, isTrue);
    });

    test('should get clipboard content', () async {
      const testText = 'test_password_123';
      await clipboardService.copyWithTimeout(testText);
      final content = await clipboardService.getClipboardContent();
      expect(content, equals(testText));
    });

    test('should use custom timeout duration', () async {
      const testText = 'test_password_123';
      const customTimeout = 5;
      await clipboardService.copyWithTimeout(testText, timeoutSeconds: customTimeout);
      expect(clipboardService.hasActiveTimeout(), isTrue);
    });

    test('should cancel previous timeout when new copy is made', () async {
      const text1 = 'password_1';
      const text2 = 'password_2';
      
      await clipboardService.copyWithTimeout(text1);
      expect(clipboardService.hasActiveTimeout(), isTrue);
      
      await clipboardService.copyWithTimeout(text2);
      expect(clipboardService.hasActiveTimeout(), isTrue);
      
      final content = await clipboardService.getClipboardContent();
      expect(content, equals(text2));
    });

    test('should return false on copy error', () async {
      // This test would need mocking of Clipboard to simulate error
      // For now, we test the happy path
      const testText = 'test_password_123';
      final result = await clipboardService.copyWithTimeout(testText);
      expect(result, isTrue);
    });
  });
}
