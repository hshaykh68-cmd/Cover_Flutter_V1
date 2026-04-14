import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/core/secure_storage/secure_key_storage_impl.dart';

void main() {
  group('SecureKeyStorageImpl', () {
    late SecureKeyStorage secureStorage;

    setUp(() {
      secureStorage = SecureKeyStorageImpl();
    });

    tearDown(() async {
      await secureStorage.clearAll();
    });

    group('storeKey and retrieveKey', () {
      test('should store and retrieve key correctly', () async {
        final key = 'test_key';
        final value = Uint8List.fromList([1, 2, 3, 4, 5]);

        await secureStorage.storeKey(key, value);
        final retrieved = await secureStorage.retrieveKey(key);

        expect(retrieved, equals(value));
      });

      test('should store and retrieve empty key', () async {
        final key = 'empty_key';
        final value = Uint8List(0);

        await secureStorage.storeKey(key, value);
        final retrieved = await secureStorage.retrieveKey(key);

        expect(retrieved, equals(value));
      });

      test('should store and retrieve large key', () async {
        final key = 'large_key';
        final value = Uint8List.fromList(List.generate(10000, (i) => i % 256));

        await secureStorage.storeKey(key, value);
        final retrieved = await secureStorage.retrieveKey(key);

        expect(retrieved, equals(value));
      });

      test('should store and retrieve key with special bytes', () async {
        final key = 'special_key';
        final value = Uint8List.fromList([0, 255, 128, 64, 32]);

        await secureStorage.storeKey(key, value);
        final retrieved = await secureStorage.retrieveKey(key);

        expect(retrieved, equals(value));
      });

      test('should return null for non-existent key', () async {
        final key = 'non_existent_key';

        final retrieved = await secureStorage.retrieveKey(key);

        expect(retrieved, isNull);
      });

      test('should overwrite existing key', () async {
        final key = 'overwrite_key';
        final value1 = Uint8List.fromList([1, 2, 3]);
        final value2 = Uint8List.fromList([4, 5, 6]);

        await secureStorage.storeKey(key, value1);
        await secureStorage.storeKey(key, value2);

        final retrieved = await secureStorage.retrieveKey(key);

        expect(retrieved, equals(value2));
      });
    });

    group('containsKey', () {
      test('should return true for existing key', () async {
        final key = 'existing_key';
        final value = Uint8List.fromList([1, 2, 3]);

        await secureStorage.storeKey(key, value);
        final contains = await secureStorage.containsKey(key);

        expect(contains, isTrue);
      });

      test('should return false for non-existent key', () async {
        final key = 'non_existent_key';

        final contains = await secureStorage.containsKey(key);

        expect(contains, isFalse);
      });
    });

    group('deleteKey', () {
      test('should delete existing key', () async {
        final key = 'delete_key';
        final value = Uint8List.fromList([1, 2, 3]);

        await secureStorage.storeKey(key, value);
        await secureStorage.deleteKey(key);

        final contains = await secureStorage.containsKey(key);
        expect(contains, isFalse);

        final retrieved = await secureStorage.retrieveKey(key);
        expect(retrieved, isNull);
      });

      test('should handle deleting non-existent key', () async {
        final key = 'non_existent_key';

        await secureStorage.deleteKey(key);

        // Should not throw
        expect(() async => await secureStorage.deleteKey(key), returnsNormally);
      });
    });

    group('clearAll', () {
      test('should clear all keys', () async {
        final keys = ['key1', 'key2', 'key3'];
        final value = Uint8List.fromList([1, 2, 3]);

        for (final key in keys) {
          await secureStorage.storeKey(key, value);
        }

        await secureStorage.clearAll();

        for (final key in keys) {
          final contains = await secureStorage.containsKey(key);
          expect(contains, isFalse);
        }
      });

      test('should handle clearing empty storage', () async {
        await secureStorage.clearAll();

        // Should not throw
        expect(() async => await secureStorage.clearAll(), returnsNormally);
      });
    });

    group('listKeys', () {
      test('should list all keys', () async {
        final keys = ['key1', 'key2', 'key3'];
        final value = Uint8List.fromList([1, 2, 3]);

        for (final key in keys) {
          await secureStorage.storeKey(key, value);
        }

        final listedKeys = await secureStorage.listKeys();

        expect(listedKeys.length, equals(keys.length));
        for (final key in keys) {
          expect(listedKeys, contains(key));
        }
      });

      test('should return empty list when no keys', () async {
        final listedKeys = await secureStorage.listKeys();

        expect(listedKeys, isEmpty);
      });
    });

    group('SecureStorageOptions', () {
      test('should use default options when not specified', () async {
        final key = 'default_options_key';
        final value = Uint8List.fromList([1, 2, 3]);

        await secureStorage.storeKey(key, value);
        final retrieved = await secureStorage.retrieveKey(key);

        expect(retrieved, equals(value));
      });

      test('should store with custom options', () async {
        final key = 'custom_options_key';
        final value = Uint8List.fromList([1, 2, 3]);
        final customOptions = SecureStorageOptions.derivedKey;

        await secureStorage.storeKey(key, value, options: customOptions);
        final retrieved = await secureStorage.retrieveKey(key);

        expect(retrieved, equals(value));
      });
    });

    group('KeyRotationStrategy', () {
      test('should have default strategy values', () {
        final strategy = KeyRotationStrategy.defaultStrategy;

        expect(strategy.maxKeyAgeDays, equals(365));
        expect(strategy.rotateOnVersionChange, isTrue);
        expect(strategy.rotateOnCompromise, isTrue);
      });

      test('should have high security strategy values', () {
        final strategy = KeyRotationStrategy.highSecurityStrategy;

        expect(strategy.maxKeyAgeDays, equals(90));
        expect(strategy.rotateOnVersionChange, isTrue);
        expect(strategy.rotateOnCompromise, isTrue);
      });

      test('should accept custom strategy values', () {
        final strategy = KeyRotationStrategy(
          maxKeyAgeDays: 180,
          rotateOnVersionChange: false,
          rotateOnCompromise: true,
        );

        expect(strategy.maxKeyAgeDays, equals(180));
        expect(strategy.rotateOnVersionChange, isFalse);
        expect(strategy.rotateOnCompromise, isTrue);
      });
    });
  });
}
