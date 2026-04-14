import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cover/data/repository/remote_config_repository_impl.dart';
import 'package:cover/domain/repository/remote_config_repository.dart';

@GenerateMocks([FirebaseRemoteConfig])
import 'remote_config_repository_test.mocks.dart';

void main() {
  group('RemoteConfigRepository', () {
    late RemoteConfigRepository repository;
    late MockFirebaseRemoteConfig mockRemoteConfig;

    setUp(() {
      mockRemoteConfig = MockFirebaseRemoteConfig();
      repository = RemoteConfigRepositoryImpl(mockRemoteConfig);
    });

    group('Initialization', () {
      test('should set defaults and fetch on initialize', () async {
        when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.setConfigSettings(any)).thenAnswer((_) async {});
        when(mockRemoteConfig.fetch()).thenAnswer((_) async => true);
        when(mockRemoteConfig.activate()).thenAnswer((_) async {});

        await repository.initialize();

        verify(mockRemoteConfig.setDefaults(any)).called(1);
        verify(mockRemoteConfig.setConfigSettings(any)).called(1);
        verify(mockRemoteConfig.fetch()).called(1);
        verify(mockRemoteConfig.activate()).called(1);
      });

      test('should handle initialization errors gracefully', () async {
        when(mockRemoteConfig.setDefaults(any)).thenThrow(Exception('Firebase error'));

        expect(() => repository.initialize(), returnsNormally);
      });
    });

    group('Fetch and Activate', () {
      test('should fetch and activate successfully', () async {
        when(mockRemoteConfig.fetch()).thenAnswer((_) async => true);
        when(mockRemoteConfig.activate()).thenAnswer((_) async {});

        await repository.fetchAndActivate();

        verify(mockRemoteConfig.fetch()).called(1);
        verify(mockRemoteConfig.activate()).called(1);
      });

      test('should handle fetch failure gracefully', () async {
        when(mockRemoteConfig.fetch()).thenThrow(Exception('Network error'));

        expect(() => repository.fetchAndActivate(), returnsNormally);
      });
    });

    group('Fetch with Retry', () {
      test('should retry on failure', () async {
        when(mockRemoteConfig.fetch()).thenThrow(Exception('Network error'));
        when(mockRemoteConfig.activate()).thenAnswer((_) async {});

        await repository.fetchWithRetry(maxRetries: 2);

        verify(mockRemoteConfig.fetch()).called(2);
      });

      test('should succeed on retry', () async {
        when(mockRemoteConfig.fetch())
            .thenThrow(Exception('Network error'))
            .thenAnswer((_) async => true);
        when(mockRemoteConfig.activate()).thenAnswer((_) async {});

        await repository.fetchWithRetry(maxRetries: 2);

        verify(mockRemoteConfig.fetch()).called(2);
        verify(mockRemoteConfig.activate()).called(1);
      });
    });

    group('Get Bool Value', () {
      test('should return bool value', () {
        when(mockRemoteConfig.getBool('test_key')).thenReturn(true);

        final result = repository.getBool('test_key', false);

        expect(result, isTrue);
      });

      test('should return default value on error', () {
        when(mockRemoteConfig.getBool('test_key')).thenThrow(Exception('Error'));

        final result = repository.getBool('test_key', false);

        expect(result, isFalse);
      });
    });

    group('Get Int Value', () {
      test('should return int value', () {
        when(mockRemoteConfig.getInt('test_key')).thenReturn(42);

        final result = repository.getInt('test_key', 0);

        expect(result, equals(42));
      });

      test('should return default value on error', () {
        when(mockRemoteConfig.getInt('test_key')).thenThrow(Exception('Error'));

        final result = repository.getInt('test_key', 0);

        expect(result, equals(0));
      });
    });

    group('Get Double Value', () {
      test('should return double value', () {
        when(mockRemoteConfig.getDouble('test_key')).thenReturn(3.14);

        final result = repository.getDouble('test_key', 0.0);

        expect(result, equals(3.14));
      });

      test('should return default value on error', () {
        when(mockRemoteConfig.getDouble('test_key')).thenThrow(Exception('Error'));

        final result = repository.getDouble('test_key', 0.0);

        expect(result, equals(0.0));
      });
    });

    group('Get String Value', () {
      test('should return string value', () {
        when(mockRemoteConfig.getString('test_key')).thenReturn('test_value');

        final result = repository.getString('test_key', 'default');

        expect(result, equals('test_value'));
      });

      test('should return default value on error', () {
        when(mockRemoteConfig.getString('test_key')).thenThrow(Exception('Error'));

        final result = repository.getString('test_key', 'default');

        expect(result, equals('default'));
      });
    });

    group('Needs Refresh', () {
      test('should return true when refresh interval has passed', () {
        when(mockRemoteConfig.getInt('config_fetch_interval_minutes', 60)).thenReturn(60);
        final lastFetch = DateTime.now().subtract(const Duration(minutes: 61));

        final result = repository.needsRefresh(lastFetch);

        expect(result, isTrue);
      });

      test('should return false when refresh interval has not passed', () {
        when(mockRemoteConfig.getInt('config_fetch_interval_minutes', 60)).thenReturn(60);
        final lastFetch = DateTime.now().subtract(const Duration(minutes: 30));

        final result = repository.needsRefresh(lastFetch);

        expect(result, isFalse);
      });
    });
  });
}
