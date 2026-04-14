import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/utils/logger.dart';

/// Clipboard timeout service interface
/// 
/// Manages clipboard operations with automatic timeout for security
abstract class ClipboardTimeoutService {
  /// Copies text to clipboard with automatic timeout
  /// 
  /// Parameters:
  /// - [text]: Text to copy
  /// - [timeoutSeconds]: Custom timeout (uses app config default if null)
  /// 
  /// Returns true if copy was successful
  Future<bool> copyWithTimeout(String text, {int? timeoutSeconds});

  /// Copies text to clipboard without timeout
  /// 
  /// Parameters:
  /// - [text]: Text to copy
  /// 
  /// Returns true if copy was successful
  Future<bool> copyWithoutTimeout(String text);

  /// Clears the clipboard
  /// 
  /// Returns true if clear was successful
  Future<bool> clearClipboard();

  /// Gets the current clipboard content
  /// 
  /// Returns the clipboard text or null if empty
  Future<String?> getClipboardContent();

  /// Cancels the active clipboard timeout
  void cancelTimeout();

  /// Checks if there's an active timeout
  bool hasActiveTimeout();
}

/// Clipboard timeout service implementation
class ClipboardTimeoutServiceImpl implements ClipboardTimeoutService {
  final AppConfig _appConfig;
  Timer? _timeoutTimer;
  String? _lastCopiedText;

  ClipboardTimeoutServiceImpl(this._appConfig);

  @override
  Future<bool> copyWithTimeout(String text, {int? timeoutSeconds}) async {
    try {
      // Copy text to clipboard
      await Clipboard.setData(ClipboardData(text: text));
      _lastCopiedText = text;

      // Cancel any existing timer
      _timeoutTimer?.cancel();

      // Set new timer with configured timeout
      final timeout = timeoutSeconds ?? _appConfig.clipboardTimeoutSeconds;
      _timeoutTimer = Timer(Duration(seconds: timeout), () async {
        await _clearClipboardInternal();
        AppLogger.info('Clipboard cleared after $timeout seconds timeout');
      });

      AppLogger.debug('Copied text to clipboard with $timeout second timeout');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to copy text to clipboard', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> copyWithoutTimeout(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _lastCopiedText = text;

      // Cancel any existing timer
      _timeoutTimer?.cancel();

      AppLogger.debug('Copied text to clipboard without timeout');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to copy text to clipboard', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> clearClipboard() async {
    try {
      _timeoutTimer?.cancel();
      await _clearClipboardInternal();
      AppLogger.debug('Clipboard cleared manually');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear clipboard', e, stackTrace);
      return false;
    }
  }

  @override
  Future<String?> getClipboardContent() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get clipboard content', e, stackTrace);
      return null;
    }
  }

  @override
  void cancelTimeout() {
    _timeoutTimer?.cancel();
    AppLogger.debug('Clipboard timeout cancelled');
  }

  @override
  bool hasActiveTimeout() {
    return _timeoutTimer?.isActive ?? false;
  }

  Future<void> _clearClipboardInternal() async {
    try {
      // Clear by copying empty string
      await Clipboard.setData(const ClipboardData(text: ''));
      _lastCopiedText = null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear clipboard internally', e, stackTrace);
    }
  }

  /// Disposes resources
  void dispose() {
    _timeoutTimer?.cancel();
  }
}
