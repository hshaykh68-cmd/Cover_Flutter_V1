import 'dart:math';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/utils/logger.dart';

/// Password generator service interface
/// 
/// Provides secure random password generation with configurable options
abstract class PasswordGeneratorService {
  /// Generates a random password with the specified options
  /// 
  /// Parameters:
  /// - [length]: Length of the password (default: 16)
  /// - [includeUppercase]: Include uppercase letters (default: true)
  /// - [includeLowercase]: Include lowercase letters (default: true)
  /// - [includeNumbers]: Include numbers (default: true)
  /// - [includeSpecialChars]: Include special characters (default: true)
  /// - [excludeAmbiguous]: Exclude ambiguous characters like 0, O, 1, l, I (default: true)
  /// 
  /// Returns the generated password string
  String generatePassword({
    int? length,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
    bool excludeAmbiguous = true,
  });

  /// Generates a passphrase using random words
  /// 
  /// Parameters:
  /// - [wordCount]: Number of words in the passphrase (default: 4)
  /// - [separator]: Separator between words (default: "-")
  /// - [capitalize]: Capitalize first letter of each word (default: true)
  /// 
  /// Returns the generated passphrase
  String generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = true,
  });

  /// Estimates password strength (0-100)
  /// 
  /// Parameters:
  /// - [password]: The password to evaluate
  /// 
  /// Returns strength score (0-100)
  int estimateStrength(String password);

  /// Checks if password meets minimum requirements
  /// 
  /// Parameters:
  /// - [password]: The password to check
  /// 
  /// Returns true if password meets requirements
  bool meetsRequirements(String password);
}

/// Password generator service implementation
class PasswordGeneratorServiceImpl implements PasswordGeneratorService {
  final AppConfig _appConfig;
  final Random _random = Random.secure();

  // Character sets
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const String _ambiguous = '0O1lI';

  // Word list for passphrases (common, easy to remember words)
  static const List<String> _wordList = [
    'correct', 'horse', 'battery', 'staple', 'apple', 'brave', 'cloud', 'dance',
    'eagle', 'flame', 'grape', 'house', 'image', 'jolly', 'knife', 'lemon',
    'mango', 'night', 'ocean', 'piano', 'quiet', 'river', 'stone', 'tiger',
    'unity', 'voice', 'water', 'zebra', 'abroad', 'beacon', 'cabinet', 'doctor',
    'engine', 'family', 'garden', 'harbor', 'island', 'journey', 'kingdom', 'legend',
    'market', 'nature', 'orange', 'palace', 'queen', 'rocket', 'safari', 'temple',
    'unique', 'violet', 'wonder', 'yellow', 'zombie', 'bridge', 'castle', 'diamond',
    'emerald', 'forest', 'giant', 'hammer', 'ivory', 'jungle', 'knight', 'lunar',
    'meteor', 'nebula', 'orbit', 'planet', 'quartz', 'robot', 'shadow', 'thunder',
    'uranus', 'velvet', 'whisper', 'xenon', 'yacht', 'zenith',
  ];

  PasswordGeneratorServiceImpl(this._appConfig);

  @override
  String generatePassword({
    int? length,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
    bool excludeAmbiguous = true,
  }) {
    final actualLength = length ?? _appConfig.passwordGeneratorMin;

    // Validate that at least one character type is selected
    if (!includeUppercase && !includeLowercase && !includeNumbers && !includeSpecialChars) {
      throw ArgumentError('At least one character type must be included');
    }

    // Build character pool
    String charPool = '';
    if (includeLowercase) {
      charPool += _lowercase;
    }
    if (includeUppercase) {
      charPool += _uppercase;
    }
    if (includeNumbers) {
      charPool += _numbers;
    }
    if (includeSpecialChars) {
      charPool += _specialChars;
    }

    // Remove ambiguous characters if requested
    if (excludeAmbiguous) {
      for (final char in _ambiguous) {
        charPool = charPool.replaceAll(char, '');
      }
    }

    // Ensure pool is not empty after filtering
    if (charPool.isEmpty) {
      throw ArgumentError('Character pool is empty after filtering');
    }

    // Generate password
    final password = StringBuffer();
    for (int i = 0; i < actualLength; i++) {
      password.write(charPool[_random.nextInt(charPool.length)]);
    }

    AppLogger.debug('Generated password of length $actualLength');
    return password.toString();
  }

  @override
  String generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = true,
  }) {
    if (wordCount < 2) {
      throw ArgumentError('Passphrase must have at least 2 words');
    }

    final words = <String>[];
    final usedIndices = <int>{};

    // Select random words without repetition
    while (words.length < wordCount) {
      final index = _random.nextInt(_wordList.length);
      if (!usedIndices.contains(index)) {
        usedIndices.add(index);
        final word = _wordList[index];
        words.add(capitalize ? _capitalizeWord(word) : word);
      }
    }

    final passphrase = words.join(separator);
    AppLogger.debug('Generated passphrase with $wordCount words');
    return passphrase;
  }

  @override
  int estimateStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Length contribution (max 40 points)
    score += (password.length * 2).clamp(0, 40);

    // Character variety (max 30 points)
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));

    int varietyCount = [hasLowercase, hasUppercase, hasNumbers, hasSpecial].where((e) => e).length;
    score += varietyCount * 7.5;

    // Entropy bonus (max 20 points)
    final uniqueChars = password.split('').toSet().length;
    score += (uniqueChars / password.length * 20).round();

    // Penalty for common patterns (max -10 points)
    if (password.contains(RegExp(r'(.)\1{2,}'))) {
      score -= 5; // Repeated characters
    }
    if (password.contains(RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)'))) {
      score -= 5; // Sequential patterns
    }

    return score.clamp(0, 100);
  }

  @override
  bool meetsRequirements(String password) {
    final minLength = _appConfig.passwordGeneratorMin;
    final maxLength = _appConfig.passwordGeneratorMax;

    if (password.length < minLength || password.length > maxLength) {
      return false;
    }

    // Check for at least 3 character types
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));

    int varietyCount = [hasLowercase, hasUppercase, hasNumbers, hasSpecial].where((e) => e).length;
    return varietyCount >= 3;
  }

  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }
}
