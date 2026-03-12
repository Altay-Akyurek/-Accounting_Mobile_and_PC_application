import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._init();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late Box _syncQueueBox;
  StreamSubscription<InternetStatus>? _connectivitySubscription;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Sync olaylarını dinlemek için StreamController (mesela WorkerProvider için)
  final StreamController<void> _syncCompletedController = StreamController<void>.broadcast();
  Stream<void> get onSyncCompleted => _syncCompletedController.stream;

  /// Callback to resolve temporary IDs in the local database
  Future<void> Function(String table, int tempId, int realId)? onTempIdResolved;

  SyncManager._init();

  Future<void> init() async {
    // Open the sync queue box
    _syncQueueBox = await Hive.openBox('sync_queue_box');

    // Check initial connection status
    _isOnline = await InternetConnection().hasInternetAccess;

    // Listen to connection changes
    _connectivitySubscription = InternetConnection().onStatusChange.listen((InternetStatus status) {
      _isOnline = status == InternetStatus.connected;
      if (_isOnline) {
        _syncData();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Belirli bir işlemi çevrimdışı kuyruğa ekler
  Future<void> enqueueOperation(String action, String table, Map<String, dynamic> data) async {
    final operation = {
      'action': action, // 'insert', 'update', 'delete'
      'table': table,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _syncQueueBox.add(operation);
    
    // Eğer o an online isek hemen senkronize etmeyi dener
    if (_isOnline) {
      _syncData();
    }
  }

  /// Belirli bir kaydın silinme sırasına alınıp alınmadığını kontrol eder
  bool isPendingDeletion(String table, dynamic id) {
    if (_syncQueueBox.isEmpty) return false;
    
    for (var operation in _syncQueueBox.values) {
      if (operation is Map) {
        final action = operation['action'];
        final opTable = operation['table'];
        final opData = operation['data'];
        
        if (action == 'delete' && opTable == table && opData['id'] == id) {
          return true;
        }
      }
    }
    return false;
  }

  /// Belirli bir kaydın güncellenme sırasına alınıp alınmadığını kontrol eder
  bool isPendingUpdate(String table, dynamic id) {
    if (_syncQueueBox.isEmpty) return false;
    
    for (var operation in _syncQueueBox.values) {
      if (operation is Map) {
        final action = operation['action'];
        final opTable = operation['table'];
        final opData = operation['data'];
        
        if (action == 'update' && opTable == table && opData['id'] == id) {
          return true;
        }
      }
    }
    return false;
  }

  /// Geçici bir ID'nin hala kuyrukta bekleyip beklemediğini kontrol eder
  bool isTempIdPending(String table, int tempId) {
    if (_syncQueueBox.isEmpty) return false;
    for (var operation in _syncQueueBox.values) {
      if (operation is Map && operation['action'] == 'insert' && operation['table'] == table) {
        final opData = operation['data'];
        if (opData != null && opData['temp_id'] == tempId) {
          return true;
        }
      }
    }
    return false;
  }

  /// Belirli bir işlemin kuyruktaki verisini günceller (özellikle offline iken eklenen kaydın offline iken güncellenmesi için)
  Future<void> updatePendingInsert(String table, int tempId, Map<String, dynamic> newData) async {
    final Map<dynamic, dynamic> operations = _syncQueueBox.toMap();
    for (var entry in operations.entries) {
      final key = entry.key;
      final op = entry.value as Map;
      if (op['action'] == 'insert' && op['table'] == table) {
         final opData = op['data'];
         if (opData != null && opData['temp_id'] == tempId) {
            final syncMap = Map<String, dynamic>.from(newData);
            syncMap['temp_id'] = tempId;
            syncMap.remove('id');
            op['data'] = syncMap;
            await _syncQueueBox.put(key, op);
            return;
         }
      }
    }
  }

  bool _isSyncing = false;

  /// Kuyruktaki işlemleri sırayla Supabase'e gönderir
  Future<void> _syncData() async {
    if (_isSyncing || _syncQueueBox.isEmpty) return;
    
    _isSyncing = true;

    try {
      while (_syncQueueBox.isNotEmpty && _isOnline) {
        final operations = _syncQueueBox.toMap();
        final keysToDelete = [];
        
        // Geçici ID'lerin yeni veritabanı ID'leriyle eşleşmesi
        // temp_id -> real_id
        Map<int, int> idMapping = {};

        for (var entry in operations.entries) {
          final key = entry.key;
          final op = entry.value as Map;

      final action = op['action'] as String;
      final table = op['table'] as String;
      Map<String, dynamic> data = Map<String, dynamic>.from(op['data']);

      // Eğer önceki bir işlemde oluşturulmuş ve ID'si değişmiş bir Foreign Key veya kendi ID'si varsa, düzelt
      if (data.containsKey('id') && idMapping.containsKey(data['id'])) {
         data['id'] = idMapping[data['id']];
      }
      
      // Foreign keys düzeltmeleri (cari_hesap_id, worker_id, project_id vs.)
      if (data.containsKey('worker_id') && idMapping.containsKey(data['worker_id'])) {
         data['worker_id'] = idMapping[data['worker_id']];
      }
      // TODO: Diğer tablolar için de foreign key düzeltmeleri eklenebilir

      try {
        if (action == 'insert') {
            final tempId = data.remove('temp_id'); // Sunucuya gitmemesi gereken alan
            final response = await _supabase.from(table).insert(data).select().single();
            
            // Eğer geçici bir ID ile eklendiyse, gerçek ID ile eşleştir
            if (tempId != null && tempId is int && tempId < 0) {
               final realId = response['id'] as int;
               idMapping[tempId] = realId;
               
               // Lokal Hive cache'i de güncelle (Mükerrer kaydı önlemek için kritik)
               if (onTempIdResolved != null) {
                 try {
                   await onTempIdResolved!(table, tempId, realId);
                 } catch (e) {
                   debugPrint('SyncManager: resolveTempId callback failed: $e');
                 }
               }
            }
        } else if (action == 'update') {
            final id = data.remove('id');
            data.remove('temp_id'); // Just in case temp_id is inside
            if (id != null) {
                // select() is appended to check if the row was actually updated
                final response = await _supabase.from(table).update(data).eq('id', id).select();
                if (response.isEmpty) {
                   // If empty, it means no rows were updated (e.g., ID mismatch or RLS issue)
                   throw Exception('Update failed: No rows matched or RLS blocked the update.');
                }
            }
        } else if (action == 'delete') {
            final id = data['id'];
            if (id != null) {
                await _supabase.from(table).delete().eq('id', id);
            }
        }
        
        // Başarılı olursa silinmek üzere işaretle
        keysToDelete.add(key);
      } catch (e) {
        debugPrint('Sync failed for operation ${op['action']} on ${op['table']} (key: $key): $e');
        // Eğer geçiçi ID çakışması veya validation hatası ise, işlemi atlamak gerekebilir
        // Şimdilik sadece başarısız olanı kuyrukta tutuyoruz ve senkronizasyonu kesiyoruz.
        break; // Bir hata olursa sıradaki işlemleri de durdur ki sıralama bozulmasın
      }
    }

        // Başarılı olanları kuyruktan sil
        if (keysToDelete.isNotEmpty) {
          await _syncQueueBox.deleteAll(keysToDelete);
          // Dışarıya sync tamamlandı olayı gönder ki Provider'lar refresh yapsın (Örn: temp_id -> real_id dönüşümü için)
          _syncCompletedController.add(null);
        }
        
        // Eğer hiçbir şey silinmediyse (hata oldu ve break dendi), döngüden çık
        if (keysToDelete.isEmpty) break;
      }
    } finally {
      _isSyncing = false;
    }
  }
}
