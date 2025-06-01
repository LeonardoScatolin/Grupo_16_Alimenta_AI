import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

// Serviço de cache em memória para testes internos
class CacheService {
  final Map<String, CacheEntry> _cache = {};
  final int _maxSize;
  final Duration _defaultTtl;
  Timer? _cleanupTimer;
  
  CacheService({int maxSize = 100, Duration defaultTtl = const Duration(minutes: 30)})
      : _maxSize = maxSize,
        _defaultTtl = defaultTtl {
    _startCleanupTimer();
  }
  
  // Método interno para iniciar timer de limpeza
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredEntries();
    });
  }
  
  // Método interno para limpeza de entradas expiradas
  void _cleanupExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.isExpired(now)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }
  
  // Método interno para aplicar política LRU
  void _applyLruPolicy() {
    if (_cache.length <= _maxSize) return;
    
    // Ordena por último acesso e remove os mais antigos
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
    
    final toRemove = sortedEntries.length - _maxSize;
    for (int i = 0; i < toRemove; i++) {
      _cache.remove(sortedEntries[i].key);
    }
  }
  
  // Método interno para gerar estatísticas
  CacheStats _generateStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    int totalSize = 0;
    DateTime? oldestEntry;
    DateTime? newestEntry;
    
    for (final entry in _cache.values) {
      if (entry.isExpired(now)) expiredCount++;
      totalSize += entry.data.toString().length;
      
      if (oldestEntry == null || entry.createdAt.isBefore(oldestEntry)) {
        oldestEntry = entry.createdAt;
      }
      if (newestEntry == null || entry.createdAt.isAfter(newestEntry)) {
        newestEntry = entry.createdAt;
      }
    }
    
    return CacheStats(
      totalEntries: _cache.length,
      expiredEntries: expiredCount,
      totalSize: totalSize,
      oldestEntry: oldestEntry,
      newestEntry: newestEntry,
    );
  }
  
  // Método interno para validar chave
  bool _isValidKey(String key) {
    return key.isNotEmpty && key.length <= 255 && !key.contains('\n');
  }
  
  // Métodos públicos
  void put(String key, dynamic data, {Duration? ttl}) {
    if (!_isValidKey(key)) {
      throw ArgumentError('Chave inválida: $key');
    }
    
    final entry = CacheEntry(
      data: data,
      ttl: ttl ?? _defaultTtl,
      createdAt: DateTime.now(),
    );
    
    _cache[key] = entry;
    _applyLruPolicy();
  }
  
  T? get<T>(String key) {
    if (!_isValidKey(key)) return null;
    
    final entry = _cache[key];
    if (entry == null || entry.isExpired(DateTime.now())) {
      _cache.remove(key);
      return null;
    }
    
    entry.updateLastAccessed();
    return entry.data as T?;
  }
  
  bool containsKey(String key) {
    if (!_isValidKey(key)) return false;
    
    final entry = _cache[key];
    if (entry == null || entry.isExpired(DateTime.now())) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }
  
  void remove(String key) {
    _cache.remove(key);
  }
  
  void clear() {
    _cache.clear();
  }
  
  CacheStats getStats() {
    return _generateStats();
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

class CacheEntry {
  final dynamic data;
  final Duration ttl;
  final DateTime createdAt;
  DateTime lastAccessed;
  
  CacheEntry({
    required this.data,
    required this.ttl,
    required this.createdAt,
  }) : lastAccessed = createdAt;
  
  bool isExpired(DateTime now) {
    return now.difference(createdAt) > ttl;
  }
  
  void updateLastAccessed() {
    lastAccessed = DateTime.now();
  }
}

class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int totalSize;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;
  
  CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.totalSize,
    this.oldestEntry,
    this.newestEntry,
  });
}

void main() {
  group('💾 Cache Memory Management White-box Tests', () {
    late CacheService cacheService;
    
    setUp(() {
      print('🧪 [${DateTime.now().toIso8601String()}] Setting up cache tests');
      cacheService = CacheService(maxSize: 5, defaultTtl: const Duration(seconds: 1));
    });
    
    tearDown(() {
      print('🧹 [${DateTime.now().toIso8601String()}] Cleaning up cache tests');
      cacheService.dispose();
    });
    
    group('Timer de Limpeza Interno', () {
      test('deve iniciar timer de limpeza automática', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing cleanup timer initialization');
        
        final cacheWithTimer = CacheService();
        expect(cacheWithTimer._cleanupTimer, isNotNull);
        expect(cacheWithTimer._cleanupTimer!.isActive, isTrue);
        
        cacheWithTimer.dispose();
        print('✅ Cleanup timer properly initialized and active');
      });
      
      test('deve cancelar timer na disposição', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing timer disposal');
        
        final cacheWithTimer = CacheService();
        final timer = cacheWithTimer._cleanupTimer;
        
        cacheWithTimer.dispose();
        expect(timer!.isActive, isFalse);
        
        print('✅ Timer properly cancelled on disposal');
      });
    });
    
    group('Limpeza de Entradas Expiradas Interna', () {
      test('deve remover entradas expiradas automaticamente', () async {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing expired entries cleanup');
        
        // Adiciona entradas com TTL curto
        cacheService.put('key1', 'value1', ttl: const Duration(milliseconds: 100));
        cacheService.put('key2', 'value2', ttl: const Duration(milliseconds: 100));
        cacheService.put('key3', 'value3', ttl: const Duration(seconds: 10));
        
        expect(cacheService._cache.length, equals(3));
        
        // Espera expiração
        await Future.delayed(const Duration(milliseconds: 150));
        
        // Força limpeza manual
        cacheService._cleanupExpiredEntries();
        
        expect(cacheService._cache.length, equals(1));
        expect(cacheService.containsKey('key3'), isTrue);
        expect(cacheService.containsKey('key1'), isFalse);
        expect(cacheService.containsKey('key2'), isFalse);
        
        print('✅ Expired entries properly cleaned up');
      });
      
      test('deve preservar entradas não expiradas na limpeza', () async {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing preservation of non-expired entries');
        
        cacheService.put('valid1', 'data1', ttl: const Duration(hours: 1));
        cacheService.put('valid2', 'data2', ttl: const Duration(hours: 1));
        cacheService.put('expired', 'data', ttl: const Duration(milliseconds: 50));
        
        await Future.delayed(const Duration(milliseconds: 100));
        cacheService._cleanupExpiredEntries();
        
        expect(cacheService.containsKey('valid1'), isTrue);
        expect(cacheService.containsKey('valid2'), isTrue);
        expect(cacheService.containsKey('expired'), isFalse);
        
        print('✅ Non-expired entries preserved during cleanup');
      });
    });
    
    group('Política LRU Interna', () {
      test('deve aplicar política LRU quando cache excede tamanho máximo', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing LRU policy application');
        
        // Preenche cache até o limite
        for (int i = 0; i < 5; i++) {
          cacheService.put('key$i', 'value$i');
        }
        expect(cacheService._cache.length, equals(5));
        
        // Adiciona mais uma entrada
        cacheService.put('key5', 'value5');
        
        // Verifica se LRU foi aplicado
        expect(cacheService._cache.length, equals(5));
        expect(cacheService.containsKey('key0'), isFalse); // Primeira entrada removida
        expect(cacheService.containsKey('key5'), isTrue); // Nova entrada preservada
        
        print('✅ LRU policy properly applied');
      });
      
      test('deve considerar último acesso na política LRU', () async {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing LRU last access consideration');
        
        // Adiciona entradas
        cacheService.put('old1', 'value1');
        cacheService.put('old2', 'value2');
        cacheService.put('old3', 'value3');
        cacheService.put('old4', 'value4');
        cacheService.put('old5', 'value5');
        
        // Simula delay para diferenciação de timestamps
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Acessa algumas entradas para atualizar lastAccessed
        cacheService.get('old1');
        cacheService.get('old3');
        
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Adiciona nova entrada que deve remover as menos recentemente acessadas
        cacheService.put('new1', 'newValue');
        
        expect(cacheService.containsKey('old1'), isTrue); // Acessada recentemente
        expect(cacheService.containsKey('old3'), isTrue); // Acessada recentemente
        expect(cacheService.containsKey('new1'), isTrue); // Nova entrada
        
        print('✅ LRU considers last access time');
      });
    });
    
    group('Geração de Estatísticas Interna', () {
      test('deve gerar estatísticas precisas do cache', () async {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing cache statistics generation');
        
        // Adiciona entradas variadas
        cacheService.put('data1', 'small');
        cacheService.put('data2', 'medium data string');
        cacheService.put('data3', 'large data string with more content');
        cacheService.put('expired', 'temp', ttl: const Duration(milliseconds: 50));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        final stats = cacheService._generateStats();
        
        expect(stats.totalEntries, equals(4));
        expect(stats.expiredEntries, equals(1));
        expect(stats.totalSize, greaterThan(0));
        expect(stats.oldestEntry, isNotNull);
        expect(stats.newestEntry, isNotNull);
        
        print('📊 Cache stats: ${stats.totalEntries} entries, ${stats.expiredEntries} expired, ${stats.totalSize} bytes');
        print('✅ Cache statistics generated accurately');
      });
      
      test('deve calcular tamanho total correto', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing total size calculation');
        
        cacheService.put('key1', 'a');      // 1 byte
        cacheService.put('key2', 'ab');     // 2 bytes
        cacheService.put('key3', 'abc');    // 3 bytes
        
        final stats = cacheService._generateStats();
        expect(stats.totalSize, equals(6));
        
        print('✅ Total size calculated correctly');
      });
    });
    
    group('Validação de Chave Interna', () {
      test('deve validar chaves corretas', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing valid key validation');
        
        final validKeys = [
          'simple',
          'key_with_underscore',
          'key-with-dash',
          'key123',
          'Key.with.dots',
          'a' * 255, // máximo permitido
        ];
        
        for (final key in validKeys) {
          expect(cacheService._isValidKey(key), isTrue, reason: 'Key "$key" should be valid');
        }
        
        print('✅ Valid keys properly validated');
      });
      
      test('deve rejeitar chaves inválidas', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing invalid key rejection');
        
        final invalidKeys = [
          '',                    // vazia
          'key\nwith\nnewline', // contém quebra de linha
          'a' * 256,            // muito longa
        ];
        
        for (final key in invalidKeys) {
          expect(cacheService._isValidKey(key), isFalse, reason: 'Key "$key" should be invalid');
        }
        
        print('✅ Invalid keys properly rejected');
      });
    });
    
    group('Operações Públicas de Cache', () {
      test('deve armazenar e recuperar dados corretamente', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing basic cache operations');
        
        const key = 'test-key';
        const value = 'test-value';
        
        cacheService.put(key, value);
        final retrieved = cacheService.get<String>(key);
        
        expect(retrieved, equals(value));
        expect(cacheService.containsKey(key), isTrue);
        
        print('✅ Basic cache operations work correctly');
      });      test('deve lidar com diferentes tipos de dados', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing different data types');
        
        // Usar um cache maior para este teste específico
        final largeCacheService = CacheService(maxSize: 10, defaultTtl: const Duration(minutes: 30));
        
        largeCacheService.put('string', 'text');
        largeCacheService.put('int', 42);
        largeCacheService.put('double', 3.14);
        largeCacheService.put('bool', true);
        largeCacheService.put('list', [1, 2, 3]);
        largeCacheService.put('map', {'key': 'value'});
        
        expect(largeCacheService.get<String>('string'), equals('text'));
        expect(largeCacheService.get<int>('int'), equals(42));
        expect(largeCacheService.get<double>('double'), equals(3.14));
        expect(largeCacheService.get<bool>('bool'), equals(true));
        expect(largeCacheService.get<List>('list'), equals([1, 2, 3]));
        expect(largeCacheService.get<Map>('map'), equals({'key': 'value'}));
        
        largeCacheService.dispose();
        print('✅ Different data types handled correctly');
      });
      
      test('deve remover entradas expiradas no acesso', () async {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing expired entry removal on access');
        
        cacheService.put('temp', 'data', ttl: const Duration(milliseconds: 100));
        
        expect(cacheService.containsKey('temp'), isTrue);
        
        await Future.delayed(const Duration(milliseconds: 150));
        
        expect(cacheService.get('temp'), isNull);
        expect(cacheService.containsKey('temp'), isFalse);
        
        print('✅ Expired entries removed on access');
      });
      
      test('deve lançar erro para chaves inválidas', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing invalid key error handling');
        
        expect(() => cacheService.put('', 'value'), throwsArgumentError);
        expect(() => cacheService.put('key\nwith\nnewline', 'value'), throwsArgumentError);
        
        print('✅ Invalid key errors properly thrown');
      });
    });
    
    group('Testes de Performance e Concorrência', () {
      test('deve ter performance adequada para operações básicas', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing basic operation performance');
        
        final stopwatch = Stopwatch()..start();
        
        // Teste de inserção
        for (int i = 0; i < 1000; i++) {
          cacheService.put('key$i', 'value$i');
        }
        
        final insertTime = stopwatch.elapsedMicroseconds;
        stopwatch.reset();
        
        // Teste de recuperação
        for (int i = 0; i < 1000; i++) {
          cacheService.get('key$i');
        }
        
        final retrieveTime = stopwatch.elapsedMicroseconds;
        stopwatch.stop();
        
        print('📊 Insert time: ${insertTime / 1000} microseconds per operation');
        print('📊 Retrieve time: ${retrieveTime / 1000} microseconds per operation');
        
        expect(insertTime / 1000, lessThan(100)); // Menos de 100 microseconds por inserção
        expect(retrieveTime / 1000, lessThan(50)); // Menos de 50 microseconds por recuperação
        
        print('✅ Cache performance is adequate');
      });
      
      test('deve aplicar LRU eficientemente em cache grande', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing LRU efficiency with large cache');
        
        final largeCacheService = CacheService(maxSize: 1000);
        final stopwatch = Stopwatch()..start();
        
        // Preenche o cache até o limite
        for (int i = 0; i < 1000; i++) {
          largeCacheService.put('key$i', 'value$i');
        }
        
        // Adiciona mais entradas para forçar LRU
        for (int i = 1000; i < 1100; i++) {
          largeCacheService.put('key$i', 'value$i');
        }
        
        stopwatch.stop();
        
        expect(largeCacheService._cache.length, equals(1000));
        
        final avgLruTime = stopwatch.elapsedMicroseconds / 100;
        print('📊 Average LRU application time: ${avgLruTime.toStringAsFixed(2)} microseconds');
        
        expect(avgLruTime, lessThan(10000)); // Menos de 10ms por aplicação LRU
        
        largeCacheService.dispose();
        print('✅ LRU application is efficient');
      });
      
      test('deve gerar estatísticas rapidamente', () {
        print('🧪 [${DateTime.now().toIso8601String()}] Testing statistics generation performance');
        
        // Popula cache com muitos dados
        for (int i = 0; i < 100; i++) {
          cacheService.put('key$i', 'value$i' * (i % 10 + 1));
        }
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 10; i++) {
          cacheService._generateStats();
        }
        
        stopwatch.stop();
        
        final avgStatsTime = stopwatch.elapsedMicroseconds / 10;
        print('📊 Average stats generation time: ${avgStatsTime.toStringAsFixed(2)} microseconds');
        
        expect(avgStatsTime, lessThan(5000)); // Menos de 5ms por geração
        
        print('✅ Statistics generation is fast');
      });
    });
  });
}
