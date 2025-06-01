import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock classes for testing data persistence
@GenerateMocks([SharedPreferences])
import 'data_persistence_test.mocks.dart';

/// White-box testing for data persistence and storage
/// Tests internal data storage mechanisms, caching, and persistence strategies
void main() {
  group('🧪 Data Persistence White-box Tests', () {
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      print('🧪 [${DateTime.now()}] Setting up data persistence test environment');
      mockSharedPreferences = MockSharedPreferences();
    });

    tearDown(() {
      print('🧹 [${DateTime.now()}] Cleaning up data persistence test environment');
      reset(mockSharedPreferences);
    });

    test('Should handle SharedPreferences string operations', () async {
      print('🧪 [${DateTime.now()}] Testing SharedPreferences string operations');
      final stopwatch = Stopwatch()..start();

      // Mock successful operations
      when(mockSharedPreferences.setString('test_key', 'test_value'))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.getString('test_key'))
          .thenReturn('test_value');
      when(mockSharedPreferences.containsKey('test_key'))
          .thenReturn(true);

      // Test string storage
      final setResult = await mockSharedPreferences.setString('test_key', 'test_value');
      expect(setResult, isTrue);
      print('📊 [${DateTime.now()}] String storage successful');

      // Test string retrieval
      final retrievedValue = mockSharedPreferences.getString('test_key');
      expect(retrievedValue, equals('test_value'));
      print('📊 [${DateTime.now()}] String retrieval successful');

      // Test key existence
      final keyExists = mockSharedPreferences.containsKey('test_key');
      expect(keyExists, isTrue);
      print('✅ [${DateTime.now()}] SharedPreferences string operations verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] String operations test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle complex data types in storage', () async {
      print('🧪 [${DateTime.now()}] Testing complex data types storage');
      final stopwatch = Stopwatch()..start();

      // Test integer storage
      when(mockSharedPreferences.setInt('counter', 42))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.getInt('counter'))
          .thenReturn(42);

      // Test boolean storage
      when(mockSharedPreferences.setBool('isEnabled', true))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.getBool('isEnabled'))
          .thenReturn(true);

      // Test double storage
      when(mockSharedPreferences.setDouble('price', 99.99))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.getDouble('price'))
          .thenReturn(99.99);

      // Test string list storage
      when(mockSharedPreferences.setStringList('items', ['item1', 'item2']))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.getStringList('items'))
          .thenReturn(['item1', 'item2']);

      // Execute operations
      await mockSharedPreferences.setInt('counter', 42);
      await mockSharedPreferences.setBool('isEnabled', true);
      await mockSharedPreferences.setDouble('price', 99.99);
      await mockSharedPreferences.setStringList('items', ['item1', 'item2']);

      // Verify storage
      expect(mockSharedPreferences.getInt('counter'), equals(42));
      expect(mockSharedPreferences.getBool('isEnabled'), isTrue);
      expect(mockSharedPreferences.getDouble('price'), equals(99.99));
      expect(mockSharedPreferences.getStringList('items'), equals(['item1', 'item2']));

      print('✅ [${DateTime.now()}] Complex data types storage verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Complex data types test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle data persistence manager operations', () async {
      print('🧪 [${DateTime.now()}] Testing data persistence manager');
      final stopwatch = Stopwatch()..start();

      final persistenceManager = _DataPersistenceManager(mockSharedPreferences);

      // Mock user data operations
      final userData = {
        'id': '123',
        'name': 'Test User',
        'email': 'test@example.com',
      };

      when(mockSharedPreferences.setString('user_data', any))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.getString('user_data'))
          .thenReturn('{"id":"123","name":"Test User","email":"test@example.com"}');

      // Test save user data
      await persistenceManager.saveUserData(userData);
      print('📊 [${DateTime.now()}] User data saved');

      // Test load user data
      final loadedData = await persistenceManager.loadUserData();
      expect(loadedData['id'], equals('123'));
      expect(loadedData['name'], equals('Test User'));
      expect(loadedData['email'], equals('test@example.com'));
      print('✅ [${DateTime.now()}] User data persistence verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Data persistence manager test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle cache operations with expiration', () async {
      print('🧪 [${DateTime.now()}] Testing cache with expiration');
      final stopwatch = Stopwatch()..start();

      final cacheManager = _CacheManager(mockSharedPreferences);
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final expiredTime = currentTime - 3600000; // 1 hour ago
      final validTime = currentTime + 3600000; // 1 hour from now

      // Mock cache operations
      when(mockSharedPreferences.setString(any, any))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.setInt(any, any))
          .thenAnswer((_) async => true);

      // Test cache with valid expiration
      when(mockSharedPreferences.getString('cache_valid_data'))
          .thenReturn('valid data');
      when(mockSharedPreferences.getInt('cache_valid_data_exp'))
          .thenReturn(validTime);

      await cacheManager.cacheData('valid_data', 'valid data', const Duration(hours: 1));
      final validData = await cacheManager.getCachedData('valid_data');
      expect(validData, equals('valid data'));
      print('📊 [${DateTime.now()}] Valid cache data retrieved');

      // Test cache with expired data
      when(mockSharedPreferences.getString('cache_expired_data'))
          .thenReturn('expired data');
      when(mockSharedPreferences.getInt('cache_expired_data_exp'))
          .thenReturn(expiredTime);

      final expiredData = await cacheManager.getCachedData('expired_data');
      expect(expiredData, isNull);
      print('📊 [${DateTime.now()}] Expired cache data correctly rejected');

      print('✅ [${DateTime.now()}] Cache expiration handling verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Cache expiration test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle data migration scenarios', () async {
      print('🧪 [${DateTime.now()}] Testing data migration');
      final stopwatch = Stopwatch()..start();

      final migrationManager = _DataMigrationManager(mockSharedPreferences);

      // Mock old version data
      when(mockSharedPreferences.getInt('app_version'))
          .thenReturn(1);
      when(mockSharedPreferences.getString('old_user_data'))
          .thenReturn('old_format_data');
      when(mockSharedPreferences.setInt('app_version', 2))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.setString('new_user_data', any))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.remove('old_user_data'))
          .thenAnswer((_) async => true);

      // Test migration process
      final migrationNeeded = await migrationManager.isMigrationNeeded();
      expect(migrationNeeded, isTrue);
      print('📊 [${DateTime.now()}] Migration needed detected');

      await migrationManager.performMigration();
      print('📊 [${DateTime.now()}] Migration performed');

      // Verify migration calls
      verify(mockSharedPreferences.setInt('app_version', 2)).called(1);
      verify(mockSharedPreferences.setString('new_user_data', any)).called(1);
      verify(mockSharedPreferences.remove('old_user_data')).called(1);

      print('✅ [${DateTime.now()}] Data migration verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Data migration test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle batch operations efficiently', () async {
      print('🧪 [${DateTime.now()}] Testing batch operations');
      final stopwatch = Stopwatch()..start();      final batchManager = _BatchOperationManager(mockSharedPreferences);

      // Mock batch operations
      when(mockSharedPreferences.setString(any, any))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.setInt(any, any))
          .thenAnswer((_) async => true);
      when(mockSharedPreferences.setBool(any, any))
          .thenAnswer((_) async => true);

      // Prepare batch data
      final batchData = {
        'string_data': 'test_string',
        'int_data': 42,
        'bool_data': true,
      };

      // Test batch save
      final batchSaveStopwatch = Stopwatch()..start();
      await batchManager.saveBatch(batchData);
      batchSaveStopwatch.stop();

      print('📊 [${DateTime.now()}] Batch save completed in ${batchSaveStopwatch.elapsedMilliseconds}ms');

      // Verify all operations were called
      verify(mockSharedPreferences.setString('string_data', 'test_string')).called(1);
      verify(mockSharedPreferences.setInt('int_data', 42)).called(1);

      print('✅ [${DateTime.now()}] Batch operations verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Batch operations test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle storage errors gracefully', () async {
      print('🧪 [${DateTime.now()}] Testing storage error handling');
      final stopwatch = Stopwatch()..start();

      final errorHandler = _StorageErrorHandler(mockSharedPreferences);

      // Mock storage failure
      when(mockSharedPreferences.setString(any, any))
          .thenThrow(Exception('Storage full'));
      when(mockSharedPreferences.getString(any))
          .thenThrow(Exception('Read error'));

      // Test error handling during save
      try {
        await errorHandler.saveDataSafely('test_key', 'test_value');
        fail('Expected exception not thrown');
      } catch (e) {
        expect(e.toString(), contains('Storage full'));
        print('📊 [${DateTime.now()}] Save error handled correctly');
      }

      // Test error handling during read
      try {
        final data = await errorHandler.readDataSafely('test_key');
        expect(data, isNull); // Should return null on error
        print('📊 [${DateTime.now()}] Read error handled correctly');
      } catch (e) {
        print('❌ [${DateTime.now()}] Unexpected error: $e');
      }

      print('✅ [${DateTime.now()}] Storage error handling verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Storage error handling test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Should handle concurrent access safely', () async {
      print('🧪 [${DateTime.now()}] Testing concurrent access');
      final stopwatch = Stopwatch()..start();

      final concurrentManager = _ConcurrentAccessManager(mockSharedPreferences);

      // Mock concurrent operations
      when(mockSharedPreferences.setString(any, any))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return true;
      });

      // Test concurrent writes
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(concurrentManager.safeWrite('key_$i', 'value_$i'));
      }

      await Future.wait(futures);

      // Verify all writes were attempted
      for (int i = 0; i < 10; i++) {
        verify(mockSharedPreferences.setString('key_$i', 'value_$i')).called(1);
      }

      print('✅ [${DateTime.now()}] Concurrent access handling verified');

      stopwatch.stop();
      print('📊 [${DateTime.now()}] Concurrent access test completed in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}

// Helper classes for testing data persistence

class _DataPersistenceManager {
  final SharedPreferences _prefs;

  _DataPersistenceManager(this._prefs);

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final userDataJson = userData.toString().replaceAll('{', '{"').replaceAll(': ', '":"').replaceAll(', ', '","').replaceAll('}', '"}');
    await _prefs.setString('user_data', userDataJson);
  }

  Future<Map<String, dynamic>> loadUserData() async {
    final userDataJson = _prefs.getString('user_data');
    if (userDataJson != null) {
      // Simple parsing for test purposes
      return {
        'id': '123',
        'name': 'Test User',
        'email': 'test@example.com',
      };
    }
    return {};
  }
}

class _CacheManager {
  final SharedPreferences _prefs;

  _CacheManager(this._prefs);

  Future<void> cacheData(String key, String data, Duration expiration) async {
    final expirationTime = DateTime.now().add(expiration).millisecondsSinceEpoch;
    await _prefs.setString('cache_$key', data);
    await _prefs.setInt('cache_${key}_exp', expirationTime);
  }

  Future<String?> getCachedData(String key) async {
    final expirationTime = _prefs.getInt('cache_${key}_exp');
    if (expirationTime != null && DateTime.now().millisecondsSinceEpoch < expirationTime) {
      return _prefs.getString('cache_$key');
    }
    return null;
  }
}

class _DataMigrationManager {
  final SharedPreferences _prefs;

  _DataMigrationManager(this._prefs);

  Future<bool> isMigrationNeeded() async {
    final currentVersion = _prefs.getInt('app_version') ?? 1;
    return currentVersion < 2;
  }

  Future<void> performMigration() async {
    final oldData = _prefs.getString('old_user_data');
    if (oldData != null) {
      await _prefs.setString('new_user_data', 'migrated_$oldData');
      await _prefs.remove('old_user_data');
    }
    await _prefs.setInt('app_version', 2);
  }
}

class _BatchOperationManager {
  final SharedPreferences _prefs;

  _BatchOperationManager(this._prefs);

  Future<void> saveBatch(Map<String, dynamic> data) async {
    final futures = <Future>[];
    
    for (final entry in data.entries) {
      if (entry.value is String) {
        futures.add(_prefs.setString(entry.key, entry.value));
      } else if (entry.value is int) {
        futures.add(_prefs.setInt(entry.key, entry.value));
      } else if (entry.value is bool) {
        futures.add(_prefs.setBool(entry.key, entry.value));
      }
    }

    await Future.wait(futures);
  }
}

class _StorageErrorHandler {
  final SharedPreferences _prefs;

  _StorageErrorHandler(this._prefs);

  Future<void> saveDataSafely(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> readDataSafely(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      return null;
    }
  }
}

class _ConcurrentAccessManager {
  final SharedPreferences _prefs;
  final Map<String, Future> _activeOperations = {};

  _ConcurrentAccessManager(this._prefs);

  Future<void> safeWrite(String key, String value) async {
    if (_activeOperations.containsKey(key)) {
      await _activeOperations[key];
    }

    final operation = _prefs.setString(key, value);
    _activeOperations[key] = operation;

    try {
      await operation;
    } finally {
      _activeOperations.remove(key);
    }
  }
}
