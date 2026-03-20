import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cari_hesap.dart';
import '../models/fatura.dart';
import '../models/stok.dart';
import '../models/gelir_gider.dart';
import '../models/cari_islem.dart';
import '../models/project.dart';
import '../models/hakedis.dart';
import '../models/worker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'sync_manager.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late Box<String> _workersBox;
  late Box<String> _projectsBox;
  late Box<String> _carisBox;
  late Box<String> _faturasBox;
  late Box<String> _stoksBox;
  late Box<String> _gelirGiderBox;
  late Box<String> _cariIslemlerBox;
  late Box<String> _puantajBox;
  late Box<String> _hakedisBox;
  final Map<String, DateTime> _lastSyncTimes = {};

  String? _testUserId;
  void setTestUserId(String? id) => _testUserId = id;

  String? get currentUserId => _testUserId ?? _supabase.auth.currentUser?.id;

  DatabaseHelper._init();

  DateTime _getEffectiveDate(CariIslem islem) {
    if (_isSettlementTransaction(islem) && islem.vade != null) {
      return islem.vade!;
    }
    return islem.tarih;
  }

  bool _isSettlementTransaction(CariIslem islem) {
    final String descStr = islem.aciklama;
    final String descLower = descStr.toLowerCase();
    final String descLowerTr = descStr.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    
    return descLower.contains('hakediş tahsilatı') || descLowerTr.contains('hakediş tahsilatı') ||
           descLower.contains('maaş ödemesi') || descLowerTr.contains('maaş ödemesi') ||
           descLower.contains('avans') || descLowerTr.contains('avans') ||
           descLower.contains('işçi ödemesi') || descLowerTr.contains('işçi ödemesi') ||
           descStr.contains('#H:[') ||
           descStr == 'Hesap Kapatma';
  }

  Future<void> init() async {
    // Supabase main.dart'ta initialize edildiği için burada bir şey yapmaya gerek yok
    _workersBox = await Hive.openBox<String>('workers_box');
    _projectsBox = await Hive.openBox<String>('projects_box');
    _carisBox = await Hive.openBox<String>('caris_box');
    _faturasBox = await Hive.openBox<String>('faturas_box');
    _stoksBox = await Hive.openBox<String>('stoks_box');
    _gelirGiderBox = await Hive.openBox<String>('gelir_gider_box');
    _cariIslemlerBox = await Hive.openBox<String>('cari_islemler_box');
    _puantajBox = await Hive.openBox<String>('puantaj_box');
    _hakedisBox = await Hive.openBox<String>('hakedis_box');

    // Register sync callback
    SyncManager.instance.onTempIdResolved = resolveTempId;
  }

  Future<void> clearAllData() async {
    try {
      await Future.wait([
        _workersBox.clear(),
        _projectsBox.clear(),
        _carisBox.clear(),
        _faturasBox.clear(),
        _stoksBox.clear(),
        _gelirGiderBox.clear(),
        _cariIslemlerBox.clear(),
        _puantajBox.clear(),
        _hakedisBox.clear(),
      ]).timeout(const Duration(seconds: 3));
    } catch (e) {
      print('DatabaseHelper.clearAllData error: $e');
    }
  }

  Box<String>? _getBoxForTable(String table) {
    switch (table) {
      case 'cari_hesaplar': return _carisBox;
      case 'faturalar': return _faturasBox;
      case 'stoklar': return _stoksBox;
      case 'gelir_giderler': return _gelirGiderBox;
      case 'cari_islemler': return _cariIslemlerBox;
      case 'workers': return _workersBox;
      case 'projects': return _projectsBox;
      case 'puantaj': return _puantajBox;
      case 'hakedisler': return _hakedisBox;
      default: return null;
    }
  }

  /// Geçici ID ile kaydedilmiş yerel kaydı, sunucudan gelen gerçek ID ile günceller ve eskiyi siler.
  Future<void> resolveTempId(String table, int tempId, int realId) async {
    try {
      final box = _getBoxForTable(table);
      if (box == null) return;
      
      final val = box.get(tempId.toString());
      if (val != null) {
        final Map<String, dynamic> map = jsonDecode(val);
        map['id'] = realId;
        // Yeni ID ile ekle, eski geçici ID'liyi sil
        await box.put(realId.toString(), jsonEncode(map));
        await box.delete(tempId.toString());
        print('DEBUG: Resolved tempId $tempId to realId $realId in $table');
      }
    } catch (e) {
      print('DEBUG: Error in resolveTempId for $table ($tempId -> $realId): $e');
    }
  }

  bool _shouldSync(String table) {
    if (!SyncManager.instance.isOnline) return false;
    final lastSync = _lastSyncTimes[table];
    if (lastSync == null) return true;
    // En az 5 saniye geçmeden tekrar senkronize etme (flood önleme ve akıcılık)
    return DateTime.now().difference(lastSync).inSeconds > 5;
  }

  // ========== CARİ HESAP İŞLEMLERİ ==========
  Future<int> insertCariHesap(CariHesap cariHesap) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final int tempId = -DateTime.now().millisecondsSinceEpoch;
      final newCari = cariHesap.copyWith(id: tempId);

      final map = newCari.toMap();
      map['user_id'] = userId;

      // 1. Hive'a kaydet
      await _carisBox.put(tempId.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle
      final syncMap = Map<String, dynamic>.from(map);
      syncMap['temp_id'] = tempId;
      syncMap.remove('id');
      
      await SyncManager.instance.enqueueOperation('insert', 'cari_hesaplar', syncMap);

      return tempId;
    } catch (e) {
      print('DEBUG: insertCariHesap hatası: $e');
      rethrow;
    }
  }

  Future<List<CariHesap>> getAllCariHesaplar({bool ignoreThrottle = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    // 1. Önce Hive'dan oku
    List<CariHesap> localCaris = [];
    List<String> ghostKeys = [];
    
    for (var value in _carisBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(value);
        if (map['user_id'] == userId) {
            final item = CariHesap.fromMap(map);
            // Ghost detection: id < 0 but not in sync queue
            if (item.id! < 0 && !SyncManager.instance.isTempIdPending('cari_hesaplar', item.id!)) {
              ghostKeys.add(item.id.toString());
              continue;
            }
            localCaris.add(item);
        }
      } catch (e) {
        print('DEBUG: Error parsing localized cari JSON: $e');
      }
    }

    // Clean up ghosts from Hive
    if (ghostKeys.isNotEmpty) {
      for (var key in ghostKeys) {
        await _carisBox.delete(key);
      }
      print('DEBUG: Purged ${ghostKeys.length} ghost CariHesap entries');
    }

    // 2. Online isek senkronize et (Throttle ekle)
    if (ignoreThrottle || _shouldSync('cari_hesaplar')) {
      _lastSyncTimes['cari_hesaplar'] = DateTime.now();
      _syncCarisFromServer(userId, localCaris);
    }
    
    localCaris.sort((a, b) => a.unvan.compareTo(b.unvan));
    return localCaris;
  }
  
  Future<void> _syncCarisFromServer(String userId, List<CariHesap> initialList) async {
      print('DEBUG: _syncCarisFromServer starting...');
      try {
        final List<dynamic> data = await _supabase.from('cari_hesaplar').select().eq('user_id', userId);
        print('DEBUG: _syncCarisFromServer received ${data.length} records from Supabase');
        
        List<CariHesap> serverCaris = data.map((m) => CariHesap.fromMap(m)).toList();
        
        // SADECE silme sırasına alınmamış olanları ekle
        serverCaris = serverCaris.where((c) => !SyncManager.instance.isPendingDeletion('cari_hesaplar', c.id)).toList();
        
        // Eğer güncellenme sırasındaysa, sunucudan gelen eski veri yerine lokaldeki veriyi koru
        for (int i = 0; i < serverCaris.length; i++) {
          if (SyncManager.instance.isPendingUpdate('cari_hesaplar', serverCaris[i].id)) {
            final localMatch = initialList.where((l) => l.id == serverCaris[i].id);
            if (localMatch.isNotEmpty) {
               serverCaris[i] = localMatch.first;
            }
          }
        }
        
        List<CariHesap> tempList = initialList.where((c) => c.id! < 0 && SyncManager.instance.isTempIdPending('cari_hesaplar', c.id!)).toList();
        
        final allUpdatedCaris = [...serverCaris, ...tempList];
        print('DEBUG: _syncCarisFromServer - Updating Hive box with ${allUpdatedCaris.length} total caris');
        
        await _carisBox.clear();
        for (var c in allUpdatedCaris) {
           final map = c.toMap();
           map['user_id'] = userId;
           await _carisBox.put(c.id.toString(), jsonEncode(map));
        }
        SyncManager.instance.triggerSyncCompleted();
      } catch (e) {
         print('DEBUG: Background sync failed for caris: $e');
      }
  }

  Future<CariHesap?> getCariHesap(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    // Hive'dan hızlı cevap (Offline-first)
    final val = _carisBox.get(id.toString());
    if (val != null) {
      return CariHesap.fromMap(jsonDecode(val));
    }
    
    final data = await _supabase.from('cari_hesaplar').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? CariHesap.fromMap(data) : null;
  }

  Future<int> updateCariHesap(CariHesap cariHesap) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final map = cariHesap.toMap();
      map['user_id'] = userId;

      // 1. Hive'ı güncelle
      await _carisBox.put(cariHesap.id.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle (id > 0 ise)
      if (cariHesap.id! > 0) {
        await SyncManager.instance.enqueueOperation('update', 'cari_hesaplar', map);
      } else {
        await SyncManager.instance.updatePendingInsert('cari_hesaplar', cariHesap.id!, map);
      }
      return cariHesap.id!;
    } catch (e) {
      print('DEBUG: updateCariHesap hatası: $e');
      rethrow;
    }
  }

  Future<int> deleteCariHesap(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

      // 3. Cariyi Hive'dan sil
      await _carisBox.delete(id.toString());
      
      if (id > 0) {
         await SyncManager.instance.enqueueOperation('delete', 'cari_hesaplar', {'id': id});
         
         // TODO: Tam Offline-first mimari için buralar kuyruklanıp düzeltilmeli
         try {
             // 1. İlişkili Kayıtları Sil (Cascade Data - Onaylı)
             await _supabase.from('cari_islemler').delete().eq('cari_hesap_id', id).eq('user_id', userId);
             await _supabase.from('faturalar').delete().eq('cari_hesap_id', id).eq('user_id', userId);
             await _supabase.from('gelir_giderler').delete().eq('cari_hesap_id', id).eq('user_id', userId);

             // 2. Worker/Project Bağlantılarını temizle (Unlink Infrastructure - Koruma Altında)
             await _supabase.from('workers').update({'cari_hesap_id': null}).eq('cari_hesap_id', id).eq('user_id', userId);
             await _supabase.from('projects').update({'cari_hesap_id': null}).eq('cari_hesap_id', id).eq('user_id', userId);
         } catch(e) {
             print("Child cascade deletion failed offline. Wait for SyncManager to fix relations: $e");
         }
      }
      return id;
    } catch (e) {
      print('DEBUG: deleteCariHesap hatası: $id : $e');
      rethrow;
    }
  }

  Future<List<CariHesap>> searchCariHesaplar(String query) async {
    final allCariHesaplar = await getAllCariHesaplar();
    final lowerQuery = query.toLowerCase();
    return allCariHesaplar.where((cari) {
      return cari.unvan.toLowerCase().contains(lowerQuery) ||
          (cari.vergiNo != null &&
              cari.vergiNo!.toLowerCase().contains(lowerQuery)) ||
          (cari.telefon != null &&
              cari.telefon!.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  DateTime _normalizeDate(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  String _stripTimePrecision(DateTime d) {
    return d.toIso8601String().split('.').first;
  }

  // ========== FATURA İŞLEMLERİ ==========
  Future<int> insertFatura(Fatura fatura) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final int tempId = -DateTime.now().millisecondsSinceEpoch;
      final newFatura = fatura.copyWith(id: tempId);

      final map = newFatura.toMap();
      map['user_id'] = userId;

      // 1. Hive'a kaydet
      await _faturasBox.put(tempId.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle
      final syncMap = Map<String, dynamic>.from(map);
      syncMap['temp_id'] = tempId;
      syncMap.remove('id');
      
      await SyncManager.instance.enqueueOperation('insert', 'faturalar', syncMap);

      return tempId;
    } catch (e) {
      print('DEBUG: insertFatura hatası: $e');
      rethrow;
    }
  }

  Future<List<Fatura>> getAllFaturalar({DateTime? baslangic, DateTime? bitis, bool ignoreThrottle = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    // 1. Önce Hive'dan oku
    List<Fatura> localFaturas = [];
    List<String> ghostKeys = [];
    
    for (var value in _faturasBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(value);
        if (map['user_id'] == userId) {
            final f = Fatura.fromMap(map);
            
            // Ghost detection
            if (f.id! < 0 && !SyncManager.instance.isTempIdPending('faturalar', f.id!)) {
              ghostKeys.add(f.id.toString());
              continue;
            }
            
            bool match = true;
            if (baslangic != null && f.tarih.isBefore(DateTime(baslangic.year, baslangic.month, baslangic.day))) match = false;
            // The bitis filter in Supabase uses lte logic on stripped precision, so we include the whole day usually
            if (bitis != null && f.tarih.isAfter(DateTime(bitis.year, bitis.month, bitis.day, 23, 59, 59))) match = false;
            if (match) localFaturas.add(f);
        }
      } catch (e) {
        print('DEBUG: Error parsing localized fatura JSON: $e');
      }
    }

    // Clean up ghosts
    if (ghostKeys.isNotEmpty) {
      for (var key in ghostKeys) {
        await _faturasBox.delete(key);
      }
      print('DEBUG: Purged ${ghostKeys.length} ghost Fatura entries');
    }

    // 2. Online isek senkronize et (Throttle ekle)
    if (ignoreThrottle || _shouldSync('faturalar')) {
      _lastSyncTimes['faturalar'] = DateTime.now();
      _syncFaturasFromServer(userId, localFaturas, baslangic, bitis);
    }
    
    localFaturas.sort((a, b) => b.tarih.compareTo(a.tarih));
    return localFaturas;
  }
  
  Future<void> _syncFaturasFromServer(String userId, List<Fatura> initialList, DateTime? baslangic, DateTime? bitis) async {
      try {
        var query = _supabase.from('faturalar').select().eq('user_id', userId);
        if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(baslangic));
        if (bitis != null) query = query.lte('tarih', _stripTimePrecision(bitis));
        
        final List<dynamic> data = await query;
        List<Fatura> serverFaturas = data.map((m) => Fatura.fromMap(m)).toList();
        
        // SADECE silme sırasına alınmamış olanları ekle
        serverFaturas = serverFaturas.where((f) => !SyncManager.instance.isPendingDeletion('faturalar', f.id)).toList();
        
        // Eğer güncellenme sırasındaysa, sunucudan gelen eski veri yerine lokaldeki veriyi koru
        for (int i = 0; i < serverFaturas.length; i++) {
          if (SyncManager.instance.isPendingUpdate('faturalar', serverFaturas[i].id)) {
            final localMatch = initialList.where((l) => l.id == serverFaturas[i].id);
            if (localMatch.isNotEmpty) {
               serverFaturas[i] = localMatch.first;
            }
          }
        }
        
        List<Fatura> tempList = initialList.where((f) => f.id! < 0 && SyncManager.instance.isTempIdPending('faturalar', f.id!)).toList();
        
        final allUpdatedFaturas = [...serverFaturas, ...tempList];
        
        // Sadece ilgili filtre dekileri temizlersek karmaşıklık olur, tüm tablo listesini tazeleyelim (daha temiz)
        // Optimizasyon için sadece ekleneni güncellemek de mümkün ama şimdilik veriyi ezelim.
        // Ama dikkat! Filtreli bir çekimde filtre dışı offline veriyi silmemek lazım.
        // Burada basitçe cache'e append/update ediyoruz (Eğer filtreli ise sil-yaz yapmamak daha iyi).
        for (var f in allUpdatedFaturas) {
           final map = f.toMap();
           map['user_id'] = userId;
           await _faturasBox.put(f.id.toString(), jsonEncode(map));
        }
        SyncManager.instance.triggerSyncCompleted();
      } catch (e) {
         print('DEBUG: Background sync failed for faturas: $e');
      }
  }

  Future<List<Fatura>> getFaturalarByTipi(FaturaTipi tipi) async {
    final all = await getAllFaturalar();
    return all.where((f) => f.tipi == tipi).toList();
  }

  Future<Fatura?> getFatura(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    // Hive'dan hızlı cevap
    final val = _faturasBox.get(id.toString());
    if (val != null) {
      return Fatura.fromMap(jsonDecode(val));
    }
    
    final data = await _supabase.from('faturalar').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? Fatura.fromMap(data) : null;
  }

  Future<int> updateFatura(Fatura fatura) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final map = fatura.toMap();
      map['user_id'] = userId;

      // 1. Hive'ı güncelle
      await _faturasBox.put(fatura.id.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle (id > 0 ise)
      if (fatura.id! > 0) {
        await SyncManager.instance.enqueueOperation('update', 'faturalar', map);
      } else {
        await SyncManager.instance.updatePendingInsert('faturalar', fatura.id!, map);
      }
      return fatura.id!;
    } catch (e) {
      print('DEBUG: updateFatura hatası: $e');
      rethrow;
    }
  }

  Future<int> deleteFatura(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      // 3. Faturayı Hive'dan sil
      await _faturasBox.delete(id.toString());
      
      if (id > 0) {
         await SyncManager.instance.enqueueOperation('delete', 'faturalar', {'id': id});
      }
      return id;
    } catch (e) {
      print('DEBUG: deleteFatura hatası: $id : $e');
      rethrow;
    }
  }

  // ========== STOK İŞLEMLERİ ==========
  Future<int> insertStok(Stok stok) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final int tempId = -DateTime.now().millisecondsSinceEpoch;
      final newStok = stok.copyWith(id: tempId);

      final map = newStok.toMap();
      map['user_id'] = userId;

      // 1. Hive'a kaydet
      await _stoksBox.put(tempId.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle
      final syncMap = Map<String, dynamic>.from(map);
      syncMap['temp_id'] = tempId;
      syncMap.remove('id');
      
      await SyncManager.instance.enqueueOperation('insert', 'stoklar', syncMap);

      return tempId;
    } catch (e) {
      print('DEBUG: insertStok hatası: $e');
      rethrow;
    }
  }

  Future<List<Stok>> getAllStoklar({bool ignoreThrottle = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    // 1. Önce Hive'dan oku
    List<Stok> localStoks = [];
    List<String> ghostKeys = [];
    
    for (var value in _stoksBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(value);
        if (map['user_id'] == userId) {
            final item = Stok.fromMap(map);
            
            // Ghost detection
            if (item.id! < 0 && !SyncManager.instance.isTempIdPending('stoklar', item.id!)) {
              ghostKeys.add(item.id.toString());
              continue;
            }
            localStoks.add(item);
        }
      } catch (e) {
        print('DEBUG: Error parsing localized stok JSON: $e');
      }
    }

    // Clean up ghosts
    if (ghostKeys.isNotEmpty) {
      for (var key in ghostKeys) {
        await _stoksBox.delete(key);
      }
      print('DEBUG: Purged ${ghostKeys.length} ghost Stok entries');
    }

    // 2. Online isek senkronize et
    if (ignoreThrottle || _shouldSync('stoklar')) {
      _lastSyncTimes['stoklar'] = DateTime.now();
      _syncStoksFromServer(userId, localStoks);
    }
    
    localStoks.sort((a, b) => a.ad.compareTo(b.ad));
    return localStoks;
  }
  
  Future<void> _syncStoksFromServer(String userId, List<Stok> initialList) async {
      try {
        final List<dynamic> data = await _supabase.from('stoklar').select().eq('user_id', userId);
        
        List<Stok> serverStoks = data.map((m) => Stok.fromMap(m)).toList();
        
        // SADECE silme sırasına alınmamış olanları ekle
        serverStoks = serverStoks.where((s) => !SyncManager.instance.isPendingDeletion('stoks', s.id)).toList(); // Tablo adı stoklar mı dsoks mu? Orijinalinde 'stoks' olarak geçmiş. Ama db tablosu 'stoklar'.
        
        // Eğer güncellenme sırasındaysa, sunucudan gelen eski veri yerine lokaldeki veriyi koru
        for (int i = 0; i < serverStoks.length; i++) {
          if (SyncManager.instance.isPendingUpdate('stoklar', serverStoks[i].id) || SyncManager.instance.isPendingUpdate('stoks', serverStoks[i].id)) {
            final localMatch = initialList.where((l) => l.id == serverStoks[i].id);
            if (localMatch.isNotEmpty) {
               serverStoks[i] = localMatch.first;
            }
          }
        }
        
        List<Stok> tempList = initialList.where((s) => s.id! < 0 && SyncManager.instance.isTempIdPending('stoklar', s.id!)).toList();
        
        final allUpdatedStoks = [...serverStoks, ...tempList];
        
        await _stoksBox.clear();
        for (var s in allUpdatedStoks) {
           final map = s.toMap();
           map['user_id'] = userId;
           await _stoksBox.put(s.id.toString(), jsonEncode(map));
        }
        SyncManager.instance.triggerSyncCompleted();
      } catch (e) {
         print('DEBUG: Background sync failed for stoks: $e');
      }
  }

  Future<Stok?> getStok(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    final val = _stoksBox.get(id.toString());
    if (val != null) {
      return Stok.fromMap(jsonDecode(val));
    }
    
    final data = await _supabase.from('stoklar').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? Stok.fromMap(data) : null;
  }

  Future<int> updateStok(Stok stok) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final map = stok.toMap();
      map['user_id'] = userId;

      // 1. Hive'ı güncelle
      await _stoksBox.put(stok.id.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle (id > 0 ise)
      if (stok.id! > 0) {
        await SyncManager.instance.enqueueOperation('update', 'stoklar', map);
      } else {
        await SyncManager.instance.updatePendingInsert('stoklar', stok.id!, map);
      }
      return stok.id!;
    } catch (e) {
      print('DEBUG: updateStok hatası: $e');
      rethrow;
    }
  }

  Future<int> deleteStok(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      // 3. Stoku Hive'dan sil
      await _stoksBox.delete(id.toString());
      
      if (id > 0) {
         await SyncManager.instance.enqueueOperation('delete', 'stoklar', {'id': id});
      }
      return id;
    } catch (e) {
      print('DEBUG: deleteStok hatası: $id : $e');
      rethrow;
    }
  }

  Future<List<Stok>> searchStoklar(String query) async {
    final allStoklar = await getAllStoklar();
    final lowerQuery = query.toLowerCase();
    return allStoklar.where((stok) {
      return stok.ad.toLowerCase().contains(lowerQuery) ||
          stok.kod.toLowerCase().contains(lowerQuery) ||
          (stok.kategori != null &&
              stok.kategori!.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // ========== GELİR/GİDER İŞLEMLERİ ==========
  Future<int> insertGelirGider(GelirGider gelirGider) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final int tempId = -DateTime.now().millisecondsSinceEpoch;
      final newGelirGider = gelirGider.copyWith(id: tempId);

      final map = newGelirGider.toMap();
      map['user_id'] = userId;

      // 1. Hive'a kaydet
      await _gelirGiderBox.put(tempId.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle
      final syncMap = Map<String, dynamic>.from(map);
      syncMap['temp_id'] = tempId;
      syncMap.remove('id');
      
      await SyncManager.instance.enqueueOperation('insert', 'gelir_giderler', syncMap);

      return tempId;
    } catch (e) {
      print('DEBUG: insertGelirGider hatası: $e');
      rethrow;
    }
  }

  Future<List<GelirGider>> getAllGelirGider({DateTime? baslangic, DateTime? bitis, bool ignoreThrottle = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    // 1. Önce Hive'dan oku
    List<GelirGider> localData = [];
    List<String> ghostKeys = [];
    
    for (var value in _gelirGiderBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(value);
        if (map['user_id'] == userId) {
            final item = GelirGider.fromMap(map);
            
            // Ghost detection
            if (item.id! < 0 && !SyncManager.instance.isTempIdPending('gelir_giderler', item.id!)) {
              ghostKeys.add(item.id.toString());
              continue;
            }
            
            bool match = true;
            if (baslangic != null && item.tarih.isBefore(DateTime(baslangic.year, baslangic.month, baslangic.day))) match = false;
            if (bitis != null && item.tarih.isAfter(DateTime(bitis.year, bitis.month, bitis.day, 23, 59, 59))) match = false;
            if (match) localData.add(item);
        }
      } catch (e) {
        print('DEBUG: Error parsing localized gelirgider JSON: $e');
      }
    }

    // 2. Online isek senkronize et (Throttle ekle)
    if (ignoreThrottle || _shouldSync('gelir_giderler')) {
      _lastSyncTimes['gelir_giderler'] = DateTime.now();
      _syncGelirGiderFromServer(userId, localData, baslangic, bitis);
    }
    
    localData.sort((a, b) => b.tarih.compareTo(a.tarih));
    return localData;
  }
  
  Future<void> _syncGelirGiderFromServer(String userId, List<GelirGider> initialList, DateTime? baslangic, DateTime? bitis) async {
      try {
        var query = _supabase.from('gelir_giderler').select().eq('user_id', userId);
        if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(baslangic));
        if (bitis != null) query = query.lte('tarih', _stripTimePrecision(bitis));

        final List<dynamic> data = await query;
        List<GelirGider> serverData = data.map((m) => GelirGider.fromMap(m)).toList();
        
        // SADECE silme sırasına alınmamış olanları ekle
        serverData = serverData.where((g) => !SyncManager.instance.isPendingDeletion('gelir_giderler', g.id)).toList();
        
        // Eğer güncellenme sırasındaysa, sunucudan gelen eski veri yerine lokaldeki veriyi koru
        for (int i = 0; i < serverData.length; i++) {
          if (SyncManager.instance.isPendingUpdate('gelir_giderler', serverData[i].id)) {
            final localMatch = initialList.where((l) => l.id == serverData[i].id);
            if (localMatch.isNotEmpty) {
               serverData[i] = localMatch.first;
            }
          }
        }
        
        List<GelirGider> tempList = initialList.where((item) => item.id! < 0 && SyncManager.instance.isTempIdPending('gelir_giderler', item.id!)).toList();
        
        final allUpdatedData = [...serverData, ...tempList];
        
        for (var item in allUpdatedData) {
           final map = item.toMap();
           map['user_id'] = userId;
           await _gelirGiderBox.put(item.id.toString(), jsonEncode(map));
        }
        SyncManager.instance.triggerSyncCompleted();
      } catch (e) {
         print('DEBUG: Background sync failed for GelirGider: $e');
      }
  }

  Future<List<GelirGider>> getGelirGiderByTipi(GelirGiderTipi tipi) async {
    final all = await getAllGelirGider();
    return all.where((g) => g.tipi == tipi).toList();
  }

  Future<List<GelirGider>> getGelirGiderByProjectId(int projectId) async {
    final all = await getAllGelirGider();
    return all.where((g) => g.projectId == projectId).toList();
  }

  Future<GelirGider?> getGelirGider(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    final val = _gelirGiderBox.get(id.toString());
    if (val != null) {
      return GelirGider.fromMap(jsonDecode(val));
    }
    
    final data = await _supabase.from('gelir_giderler').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? GelirGider.fromMap(data) : null;
  }

  Future<int> updateGelirGider(GelirGider gelirGider) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final map = gelirGider.toMap();
      map['user_id'] = userId;

      // 1. Hive'ı güncelle
      await _gelirGiderBox.put(gelirGider.id.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle (id > 0 ise)
      if (gelirGider.id! > 0) {
        await SyncManager.instance.enqueueOperation('update', 'gelir_giderler', map);
      } else {
        await SyncManager.instance.updatePendingInsert('gelir_giderler', gelirGider.id!, map);
      }
      return gelirGider.id!;
    } catch (e) {
      print('DEBUG: updateGelirGider hatası: $e');
      rethrow;
    }
  }

  Future<int> deleteGelirGider(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      // 3. GelirGider'i Hive'dan sil
      await _gelirGiderBox.delete(id.toString());
      
      if (id > 0) {
         await SyncManager.instance.enqueueOperation('delete', 'gelir_giderler', {'id': id});
      }
      return id;
    } catch (e) {
      print('DEBUG: deleteGelirGider hatası: $id : $e');
      rethrow;
    }
  }

  // ========== RAPOR İŞLEMLERİ ==========
  Future<Map<String, double>> getToplamGelirGider(DateTime? baslangic, DateTime? bitis) async {
    final allGelirGider = await getAllGelirGider();
    double toplamGelir = 0.0;
    double toplamGider = 0.0;

    for (var item in allGelirGider) {
      if (baslangic != null && item.tarih.isBefore(baslangic)) continue;
      if (bitis != null && item.tarih.isAfter(bitis)) continue;

      if (item.tipi == GelirGiderTipi.gelir) {
        toplamGelir += item.tutar;
      } else {
        toplamGider += item.tutar;
      }
    }

    return {
      'gelir': toplamGelir,
      'gider': toplamGider,
      'kar': toplamGelir - toplamGider,
    };
  }

  Future<Map<String, double>> getGlobalFinancialSummary() async {
    final results = await Future.wait([
      getAllHakedisler(),
      getAllGelirGider(),
      getAllCariIslemler(),
      getAllPuantajlar(),
      getAllWorkers(),
      getAllCariHesaplar(),
    ]);

    final hakedisler = results[0] as List<Hakedis>;
    final gelirGiderler = results[1] as List<GelirGider>;
    final cariIslemler = results[2] as List<CariIslem>;
    final puantajlar = results[3] as List<Puantaj>;
    final workers = results[4] as List<Worker>;
    final cariler = results[5] as List<CariHesap>;

    final Map<int, int> cariToWorker = {for (var w in workers) if (w.cariHesapId != null) w.cariHesapId!: w.id!};
    final workerCariIds = cariToWorker.keys.toSet();
    final kasaCariIds = cariler.where((c) => c.isKasa).map((c) => c.id).where((id) => id != null).toSet();

    double realizedIncome = 0; // Kasa Giriş
    double realizedExpense = 0; // Kasa Çıkış

    // 1. Hakedişler (Realized Collections)
    for (var h in hakedisler) {
      if (h.durum == HakedisDurum.tahsilEdildi) {
        realizedIncome += h.netTutar;
      }
    }

    // 2. Gelir/Gider (Other Direct Cash items)
    for (var gg in gelirGiderler) {
      if (gg.tipi == GelirGiderTipi.gelir) {
        realizedIncome += gg.tutar;
      } else {
        realizedExpense += gg.tutar;
      }
    }

    // 3. Cari İşlemler (In/Out)
    Map<int, double> workerPayments = {};
    for (var islem in cariIslemler) {
      // Skip hakedis tahsilatlari (already in realizedIncome via hakedis table)
      bool isSettlement = islem.aciklama.toLowerCase().contains('hakediş tahsilatı') ||
                         islem.aciklama.toLowerCase().contains('tahsilat') ||
                         islem.aciklama.contains('#H:[');
      if (isSettlement) continue;

      bool isKasa = kasaCariIds.contains(islem.cariHesapId);

      // Expense Tracking
      if (islem.alacak > 0) {
        realizedExpense += islem.alacak;
        if (workerCariIds.contains(islem.cariHesapId)) {
          int wId = cariToWorker[islem.cariHesapId]!;
          workerPayments[wId] = (workerPayments[wId] ?? 0) + islem.alacak;
        }
      }

      // Income Tracking
      if (isKasa && islem.borc > 0) {
        realizedIncome += islem.borc;
      }
    }

    // 4. Puantaj & Sunday Bonuses (Work Produced)
    Map<int, double> workerAccruals = {};
    for (var p in puantajlar) {
      final worker = workers.firstWhere((w) => w.id == p.workerId, orElse: () => Worker(adSoyad: 'Bilinmeyen', baslangicTarihi: DateTime.now()));
      double cost = calculateLaborCost(p, worker);
      workerAccruals[p.workerId] = (workerAccruals[p.workerId] ?? 0) + cost;
    }

    for (var w in workers) {
      if (w.id == null) continue;
      final workerPuantaj = puantajlar.where((p) => p.workerId == w.id).toList();
      if (workerPuantaj.isEmpty) continue;

      DateTime minDate = workerPuantaj.map((p) => p.tarih).reduce((a, b) => a.isBefore(b) ? a : b);
      DateTime maxDate = DateTime.now();

      double bonus = await _calculateWorkerSundayBonuses(w, minDate, maxDate, workerPuantaj);
      if (bonus > 0) {
        workerAccruals[w.id!] = (workerAccruals[w.id!] ?? 0) + bonus;
      }
    }

    // 5. Final Calculations
    double totalWorkerAccrual = workerAccruals.values.fold(0, (a, b) => a + b);
    double totalWorkerPayment = workerPayments.values.fold(0, (a, b) => a + b);
    double pendingLaborDebt = totalWorkerAccrual > totalWorkerPayment ? (totalWorkerAccrual - totalWorkerPayment) : 0;

    return {
      'gelir': realizedIncome, // Gerçek Tahsilatlar
      'gider': pendingLaborDebt, // Bekleyen Borçlerimiz
      'kar': realizedIncome - realizedExpense, // Net Kasa (Real Cash)
    };
  }

  Future<List<Puantaj>> getAllPuantajlar({DateTime? baslangic, DateTime? bitis, bool ignoreThrottle = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    // 1. Önce Hive'dan oku
    List<Puantaj> localData = [];
    for (var value in _puantajBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(value);
        if (map['user_id'] == userId) {
          final item = Puantaj.fromMap(map);
          bool match = true;
          if (baslangic != null && item.tarih.isBefore(_normalizeDate(baslangic))) match = false;
          if (bitis != null && item.tarih.isAfter(_normalizeDate(bitis).add(const Duration(hours: 23, minutes: 59, seconds: 59)))) match = false;
          if (match) localData.add(item);
        }
      } catch (e) {
        print('DEBUG: Error parsing localized puantaj JSON: $e');
      }
    }

    // 2. Online isek senkronize et (Throttle ekle)
    if (ignoreThrottle || _shouldSync('puantajlar')) {
      _lastSyncTimes['puantajlar'] = DateTime.now();
      _syncPuantajlarFromServer(userId, localData, baslangic, bitis);
    }

    localData.sort((a, b) => b.tarih.compareTo(a.tarih));
    return localData;
  }

  Future<void> _syncPuantajlarFromServer(String userId, List<Puantaj> initialList, DateTime? baslangic, DateTime? bitis) async {
    try {
      var query = _supabase.from('puantajlar').select().eq('user_id', userId);
      if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(_normalizeDate(baslangic)));
      if (bitis != null) {
        final endNormalized = _normalizeDate(bitis).add(const Duration(hours: 23, minutes: 59, seconds: 59));
        query = query.lte('tarih', _stripTimePrecision(endNormalized));
      }

      final List<dynamic> data = await query;
      List<Puantaj> serverData = data.map((m) => Puantaj.fromMap(m)).toList();
      
      // SADECE silme sırasına alınmamış olanları ekle
      serverData = serverData.where((p) => !SyncManager.instance.isPendingDeletion('puantajlar', p.id)).toList();
      
      // Eğer güncellenme sırasındaysa, sunucudan gelen eski veri yerine lokaldeki veriyi koru
      for (int i = 0; i < serverData.length; i++) {
        if (SyncManager.instance.isPendingUpdate('puantajlar', serverData[i].id)) {
          final localMatch = initialList.where((l) => l.id == serverData[i].id);
          if (localMatch.isNotEmpty) {
             serverData[i] = localMatch.first;
          }
        }
      }
      
      List<Puantaj> tempList = initialList.where((item) => item.id! < 0).toList();

      final allUpdatedData = [...serverData, ...tempList];

      for (var item in allUpdatedData) {
        final map = item.toMap();
        map['user_id'] = userId;
        await _puantajBox.put(item.id.toString(), jsonEncode(map));
      }
      SyncManager.instance.triggerSyncCompleted();
    } catch (e) {
      print('DEBUG: Background sync failed for Puantajlar: $e');
    }
  }

  Future<List<CariIslem>> getUnifiedLedger({int? cariId, int? projectId, bool ignoreThrottle = false}) async {
    final List<CariIslem> ledger = [];

    // 1. Cari İşlemler
    final islemler = await getAllCariIslemler(ignoreThrottle: ignoreThrottle);
    final allCaris = await getAllCariHesaplar(ignoreThrottle: ignoreThrottle);
    final cariMap = {for (var c in allCaris) c.id!: c.unvan};

    for (var i in islemler) {
      if (cariId != null && i.cariHesapId != cariId) continue;
      if (projectId != null && i.projectId != projectId) continue;

      // Ensure unvan is present
      final updatedIslem = i.cariHesapUnvan == null || i.cariHesapUnvan!.isEmpty || i.cariHesapUnvan == '---'
        ? i.copyWith(cariHesapUnvan: cariMap[i.cariHesapId] ?? '---')
        : i;

      ledger.add(updatedIslem);
    }

    // Tarihe göre sırala (Yeni en üstte)
    ledger.sort((a, b) => b.tarih.compareTo(a.tarih));

    return ledger;
  }



  Future<Map<String, dynamic>> getDetailedFinancialAnalysis(DateTime start, DateTime end, {int? projectId}) async {
    final results = await Future.wait([
      getAllGelirGider(baslangic: start, bitis: end),
      getAllCariIslemler(), // Fetch all to allow matching by vade (effectiveDate)
      getAllPuantajlar(baslangic: start.subtract(const Duration(days: 6)), bitis: end),
      getAllWorkers(),
      getAllHakedisler(baslangic: start, bitis: end),
      getAllCariHesaplar(),
    ]);

    final gelirGiderler = (results[0] as List<GelirGider>).where((gg) => projectId == null || gg.projectId == projectId).toList();
    final cariIslemler = (results[1] as List<CariIslem>).where((i) => projectId == null || i.projectId == projectId).toList();
    final puantajlar = results[2] as List<Puantaj>;
    final workers = results[3] as List<Worker>;
    final hakedisler = results[4] as List<Hakedis>;
    final cariler = results[5] as List<CariHesap>;

    final workerCariIds = workers.map((w) => w.cariHesapId).where((id) => id != null).toSet();
    final kasaCariIds = cariler.where((c) => c.isKasa).map((c) => c.id).where((id) => id != null).toSet();
    final Map<int, int> cariToWorker = {for (var w in workers) if (w.cariHesapId != null) w.cariHesapId!: w.id!};

    double toplamGelir = 0;
    double toplamGider = 0;

    // Period tracking
    double odenenIscilikThisPeriod = 0;
    double workValueProducedThisPeriod = 0;

    Map<int, int> workedCounts = {};
    Map<int, int> leaveCounts = {};
    Map<int, int> sundayCounts = {};

    // Balance tracking (Historical)
    Map<int, double> cumulativeAccrualUntilEnd = {};
    Map<int, double> cumulativePaymentUntilEnd = {};
    Map<int, double> personPaymentInPeriod = {};
    double totalUnassignedLaborPaymentUntilEnd = 0;
    Map<String, double> giderKategorileri = {
      'Malzeme/Hizmet': 0,
      'İşçilik (Ödenen)': 0,
      'İşçilik (Bekleyen)': 0,
      'Cari Ödemeler': 0,
      'Kasa Çıkışları': 0,
    };

    // 1. Hakedişler ... [omitted for brevity in ReplacementChunk, will match target content]
    for (var h in hakedisler) {
      if (projectId != null && h.projectId != projectId) continue;

      if (h.durum == HakedisDurum.tahsilEdildi &&
          h.tarih.isAfter(start.subtract(const Duration(seconds: 1))) &&
          h.tarih.isBefore(end.add(const Duration(seconds: 1)))) {
        toplamGelir += h.netTutar;
      }
    }

    // 2. Gelir/Gider ...
    for (var gg in gelirGiderler) {
      bool isLabor = (gg.kategori?.contains('İşçi') ?? false) || (gg.kategori?.contains('Maaş') ?? false);
      if (gg.tarih.isBefore(end.add(const Duration(seconds: 1)))) {
        bool inPeriod = gg.tarih.isAfter(start.subtract(const Duration(seconds: 1)));
        if (inPeriod) {
          if (gg.tipi == GelirGiderTipi.gelir) {
            toplamGelir += gg.tutar;
          } else {
            if (isLabor) {
              odenenIscilikThisPeriod += gg.tutar;
              if (gg.cariHesapId != null && workerCariIds.contains(gg.cariHesapId)) {
                int wId = cariToWorker[gg.cariHesapId]!;
                personPaymentInPeriod[wId] = (personPaymentInPeriod[wId] ?? 0) + gg.tutar;
              }
            } else {
              toplamGider += gg.tutar;
              giderKategorileri['Malzeme/Hizmet'] = (giderKategorileri['Malzeme/Hizmet'] ?? 0) + gg.tutar;
            }
          }
        }
        if (isLabor && gg.tipi == GelirGiderTipi.gider) {
          totalUnassignedLaborPaymentUntilEnd += gg.tutar;
        }
      }
    }

    // 3. Cari İşlemler
    for (var islem in cariIslemler) {
      bool isWorker = workerCariIds.contains(islem.cariHesapId);
      bool isKasa = kasaCariIds.contains(islem.cariHesapId);
      DateTime effectiveDate = _getEffectiveDate(islem);

      if (effectiveDate.isBefore(end.add(const Duration(seconds: 1)))) {
        bool inPeriod = effectiveDate.isAfter(start.subtract(const Duration(seconds: 1)));
        if (inPeriod) {
          // Proje filtresi varsa, projesiz işlemleri dahil etme
          // (İşçi ödemeleri hariç - onlar genel/unassigned olabilir ve bakiye kapatabilir)
          if (projectId != null && islem.projectId == null) {
            bool isWorker = workerCariIds.contains(islem.cariHesapId);
            if (!isWorker) continue;
          }

          if (projectId != null && islem.projectId != null && islem.projectId != projectId) continue;

          // Hakediş tahsilatlarını geç (Çift saymamak için)
          bool isSettlement = islem.aciklama.toLowerCase().contains('hakediş tahsilatı') ||
                             islem.aciklama.toLowerCase().contains('tahsilat') ||
                             islem.aciklama.contains('#H:[');

          if (!isSettlement) {
            // Kasa hesabı ise para girişi (borç) gelirdir
            toplamGelir += islem.borc;
          }

          if (islem.alacak > 0) {
            if (isWorker) {
              odenenIscilikThisPeriod += islem.alacak;
              int wId = cariToWorker[islem.cariHesapId]!;
              personPaymentInPeriod[wId] = (personPaymentInPeriod[wId] ?? 0) + islem.alacak;
            } else if (isKasa) {
              // Kasa çıkışlarını gidere ekle
              toplamGider += islem.alacak;
              giderKategorileri['Kasa Çıkışları'] = (giderKategorileri['Kasa Çıkışları'] ?? 0) + islem.alacak;
            } else {
              // Maaş ödemelerini ve hesap kapatmaları giderden düş (İşçilik başlığında ayrıca sayılıyor)
            bool isLaborPayment = islem.aciklama.toLowerCase().contains('maaş ödemesi') ||
                                 islem.aciklama.toLowerCase().contains('avans') ||
                                 islem.aciklama.toLowerCase().contains('işçi ödemesi') ||
                                 islem.aciklama == 'Hesap Kapatma';

            if (!isLaborPayment) {
              toplamGider += islem.alacak;
              giderKategorileri['Cari Ödemeler'] = (giderKategorileri['Cari Ödemeler'] ?? 0) + islem.alacak;
            }
            }
          }
        }
        if (isWorker && islem.alacak > 0) {
          int wId = cariToWorker[islem.cariHesapId]!;
          cumulativePaymentUntilEnd[wId] = (cumulativePaymentUntilEnd[wId] ?? 0) + islem.alacak;
        }
      }
    }

    // 4. Puantaj
    for (var p in puantajlar) {
      if (projectId != null && p.projectId != projectId) continue;
      if (p.tarih.isBefore(end.add(const Duration(seconds: 1)))) {
        final worker = workers.firstWhere((w) => w.id == p.workerId, orElse: () => Worker(adSoyad: 'Bilinmeyen', baslangicTarihi: DateTime.now()));
        double cost = calculateLaborCost(p, worker);

        bool inPeriod = p.tarih.isAfter(start.subtract(const Duration(seconds: 1)));
        if (inPeriod) {
          workValueProducedThisPeriod += cost;
          if (p.status == PuantajStatus.normal) {
            workedCounts[p.workerId] = (workedCounts[p.workerId] ?? 0) + 1;
          } else if ([PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)) {
            leaveCounts[p.workerId] = (leaveCounts[p.workerId] ?? 0) + 1;
          }
        }
        cumulativeAccrualUntilEnd[p.workerId] = (cumulativeAccrualUntilEnd[p.workerId] ?? 0) + cost;
      }
    }

    // 5. Sunday Bonuses
    for (var worker in workers) {
      if (worker.id == null) continue;
      final workerPuantaj = puantajlar.where((p) => p.workerId == worker.id).toList();
      if (workerPuantaj.isEmpty) continue;

      // Calculate surpluses for the period to get the count
      int periodBonusCount = 0;
      DateTime current = DateTime(start.year, start.month, start.day);
      while (current.isBefore(end.add(const Duration(seconds: 1)))) {
        if (current.weekday == DateTime.sunday) {
          bool earnedBonus = true;
          Map<int, int> projectCounts = {};
          for (int i = 0; i <= 6; i++) {
            DateTime checkDate = current.subtract(Duration(days: i));
            final dayPuantajlar = workerPuantaj.where((p) =>
              p.tarih.year == checkDate.year && p.tarih.month == checkDate.month && p.tarih.day == checkDate.day
            ).toList();
            if (i > 0) {
              if (dayPuantajlar.isEmpty || dayPuantajlar.any((item) => item.status == PuantajStatus.izinsiz)) {
                earnedBonus = false;
                break;
              }
            }
            if (dayPuantajlar.isNotEmpty && dayPuantajlar.last.projectId != null) {
              int pid = dayPuantajlar.last.projectId!;
              projectCounts[pid] = (projectCounts[pid] ?? 0) + 1;
            }
          }
          
          if (earnedBonus) {
            // Find the project worked on the most during this week
            int? majorityProjectId;
            if (projectCounts.isNotEmpty) {
              majorityProjectId = projectCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
            }
            
            // Apply project filter to bonuses as well
            if (projectId != null && majorityProjectId != projectId) {
              earnedBonus = false;
            }
          }
          if (earnedBonus) {
            // Check if Sunday itself has a paid leave record (Izinli/Raporlu/Mazeretli)
            final sundayRecords = workerPuantaj.where((p) =>
              p.tarih.year == current.year && p.tarih.month == current.month && p.tarih.day == current.day
            ).toList();

            bool isPaidHolidayRecord = sundayRecords.any((p) =>
              [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)
            );

            if (!isPaidHolidayRecord) {
              periodBonusCount++;
            }
          }
        }
        current = current.add(const Duration(days: 1));
      }
      sundayCounts[worker.id!] = periodBonusCount;

      // Total bonus (from minDate to today) for debt calculation
      DateTime minDate = workerPuantaj.map((p) => p.tarih).reduce((a, b) => a.isBefore(b) ? a : b);
      DateTime maxDate = DateTime.now();
      double bonusAmount = await _calculateWorkerSundayBonuses(worker, minDate, maxDate, workerPuantaj);

      if (bonusAmount > 0) {
        // Add to period-specific gider if needed
        double dailyRate = _getDailyRate(worker);
        workValueProducedThisPeriod += periodBonusCount * dailyRate;

        cumulativeAccrualUntilEnd[worker.id!] = (cumulativeAccrualUntilEnd[worker.id!] ?? 0) + bonusAmount;
      }
    }

    // laborCostThisPeriod is calculated as the exact sum of paid and pending


    // Remove old totalPendingLabor calculation
    // double totalPendingLabor = workValueProducedThisPeriod - odenenIscilikThisPeriod;
    // if (totalPendingLabor < 0) totalPendingLabor = 0;

    // Worker breakdown for the period UI
    Map<String, Map<String, dynamic>> workerBreakdown = {};
    double sumOfWorkerPendingAmounts = 0;

    for (var wId in workedCounts.keys.toSet().union(sundayCounts.keys.toSet())) {
      final worker = workers.firstWhere((w) => w.id == wId, orElse: () => Worker(adSoyad: 'Bilinmeyen', baslangicTarihi: DateTime.now()));
      final name = worker.adSoyad;

      // Calculate individual accrual in period for breakdown
      double personAccrualInPeriod = 0;
      for (var p in puantajlar) {
        if (p.workerId == wId && (projectId == null || p.projectId == projectId)) {
          if (p.tarih.isAfter(start.subtract(const Duration(seconds: 1))) && p.tarih.isBefore(end.add(const Duration(seconds: 1)))) {
               personAccrualInPeriod += calculateLaborCost(p, worker);
          }
        }
      }

      // Add bonuses to breakdown accrual
      personAccrualInPeriod += (sundayCounts[wId] ?? 0) * _getDailyRate(worker);

      if (personAccrualInPeriod > 0) {
        double personPending = personAccrualInPeriod - (personPaymentInPeriod[wId] ?? 0);
        double finalPending = personPending < 0 ? 0.0 : personPending;
        
        sumOfWorkerPendingAmounts += finalPending;

        workerBreakdown[name] = {
          'amount': finalPending,
          'worked': workedCounts[wId] ?? 0,
          'leave': leaveCounts[wId] ?? 0,
          'sunday': sundayCounts[wId] ?? 0,
        };
      }
    }

    giderKategorileri['İşçilik (Ödenen)'] = odenenIscilikThisPeriod;
    
    // Set the category total to exactly match the sum of individual breakdowns
    giderKategorileri['İşçilik (Bekleyen)'] = sumOfWorkerPendingAmounts;

    // Final Gider = Non-Labor Expenses + exact sum of labor categories
    double laborCostThisPeriod = odenenIscilikThisPeriod + sumOfWorkerPendingAmounts;
    toplamGider += laborCostThisPeriod;

    return {
      'gelir': toplamGelir,
      'gider': toplamGider,
      'kar': toplamGelir - toplamGider,
      'kategoriler': giderKategorileri,
      'worker_breakdown': workerBreakdown,
    };
  }

  Future<List<Map<String, dynamic>>> getProjectReports({DateTime? start, DateTime? end, List<int>? projectIds}) async {
    final results = await Future.wait([
      getAllProjects(),
      getAllHakedisler(),
      getAllGelirGider(),
      getAllCariIslemler(), // Fetch all to allow matching by vade
      getAllPuantajlar(),
      getAllWorkers(),
    ]);

    final projects = results[0] as List<Project>;
    final hakedisler = results[1] as List<Hakedis>;
    final gelirGiderler = results[2] as List<GelirGider>;
    final islemler = results[3] as List<CariIslem>;
    final puantajlar = results[4] as List<Puantaj>;
    final workers = results[5] as List<Worker>;

    DateTime? rangeStart;
    DateTime? rangeEnd;
    if (start != null) rangeStart = DateTime(start.year, start.month, start.day);
    if (end != null) rangeEnd = end.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    bool inRange(DateTime d) {
      if (rangeStart != null && d.isBefore(rangeStart.subtract(const Duration(seconds: 1)))) return false;
      if (rangeEnd != null && d.isAfter(rangeEnd.add(const Duration(seconds: 1)))) return false;
      return true;
    }

    bool belongsToPeriod(CariIslem islem) => inRange(_getEffectiveDate(islem));

    final workerCariIds = workers.map((w) => w.cariHesapId).where((id) => id != null).toSet();
    final Map<int, int> cariToWorker = {for (var w in workers) if (w.cariHesapId != null) w.cariHesapId!: w.id!};

    List<Map<String, dynamic>> reports = [];

    // 0. Global Mutabakat: Tüm işçiler için dönem başı bakiyeleri hesapla
    Map<int, double> globalWorkerHistoricalBalance = {};
    if (rangeStart != null) {
      for (var w in workers) {
        if (w.id == null) continue;
        double hEarned = 0;
        final wPuantaj = puantajlar.where((p) => p.workerId == w.id).toList();
        for (var p in wPuantaj) {
          if (projectIds != null && !projectIds.contains(p.projectId)) continue;
          if (p.tarih.isBefore(rangeStart)) hEarned += calculateLaborCost(p, w);
        }
        
        DateTime bStart = DateTime(2024, 1, 1);
        if (w.baslangicTarihi.isAfter(bStart)) bStart = DateTime(w.baslangicTarihi.year, w.baslangicTarihi.month, w.baslangicTarihi.day);
        DateTime d = bStart;
        while (d.isBefore(rangeStart)) {
          if (d.weekday == DateTime.sunday) {
            bool earnedB = true;
            for (int i = 0; i <= 6; i++) {
              DateTime cD = d.subtract(Duration(days: i));
              final dayP = wPuantaj.where((p) => p.tarih.year == cD.year && p.tarih.month == cD.month && p.tarih.day == cD.day).toList();
              if (i > 0 && (dayP.isEmpty || dayP.any((item) => item.status == PuantajStatus.izinsiz))) { earnedB = false; break; }
            }
            if (earnedB) {
               Map<int, int> pC = {};
               for (int i = 0; i <= 6; i++) {
                 DateTime c = d.subtract(Duration(days: i));
                 final dP = wPuantaj.where((p) => p.tarih.year == c.year && p.tarih.month == c.month && p.tarih.day == c.day).toList();
                 if (dP.isNotEmpty && dP.last.projectId != null) {
                   int pid = dP.last.projectId!;
                   pC[pid] = (pC[pid] ?? 0) + 1;
                 }
               }
               int? mP;
               if (pC.isNotEmpty) mP = pC.entries.reduce((a, b) => a.value > b.value ? a : b).key;
               if (projectIds != null && (mP == null || !projectIds.contains(mP))) earnedB = false;
            }
            if (earnedB) {
              final sunR = wPuantaj.where((p) => p.tarih.year == d.year && p.tarih.month == d.month && p.tarih.day == d.day).toList();
              if (!sunR.any((p) => [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status))) hEarned += _getDailyRate(w);
            }
          }
          d = d.add(const Duration(days: 1));
        }

        double hPaid = 0;
        if (w.cariHesapId != null) {
          for (var islem in islemler) {
            if (islem.cariHesapId != w.cariHesapId) continue;
            if (projectIds != null && islem.projectId != null && !projectIds.contains(islem.projectId)) continue;
            DateTime eff = _getEffectiveDate(islem);
            if (eff.isBefore(rangeStart)) hPaid += (islem.alacak - islem.borc);
          }
        }
        globalWorkerHistoricalBalance[w.id!] = hEarned - hPaid;
      }
    }

    for (var project in projects) {
      if (projectIds != null && projectIds.isNotEmpty && !projectIds.contains(project.id)) {
        continue; // Skip if filter is set and this project is not in it
      }

      double gelir = 0;
      double nonLaborGider = 0;
      double projectLaborAccrual = 0;
      double projectLaborPayment = 0;
      Map<int, double> projectWorkerAccrual = {};
      Map<int, double> projectWorkerPayment = {};
      Map<int, Map<String, dynamic>> projectWorkerBreakdown = {};

      // Hakedişler
      for (var h in hakedisler) {
        if (h.projectId == project.id && h.durum == HakedisDurum.tahsilEdildi) {
          if (!inRange(h.tarih)) continue;
          gelir += h.netTutar;
        }
      }

      // Projeye bağlı Gelir/Gider (ve maaş kategorisindeki giderlerin işçi ödemesi olarak sayılması)
      for (var gg in gelirGiderler) {
        if (gg.projectId == project.id) {
          if (!inRange(gg.tarih)) continue;
          if (gg.tipi == GelirGiderTipi.gelir) gelir += gg.tutar;
          else {
            bool isLabor = (gg.kategori?.contains('İşçi') ?? false) || (gg.kategori?.contains('Maaş') ?? false);
            if (isLabor) projectLaborPayment += gg.tutar;
            else nonLaborGider += gg.tutar;
          }
        }
      }

      // Projeye bağlı Cari İşlemler
      for (var islem in islemler) {
        if (islem.projectId == project.id) {
          if (!belongsToPeriod(islem)) continue;
          
          // Hakediş tahsilatlarını geç (Çünkü hakedisler tablosundan zaten ekleniyor)
          bool isSettlement = islem.aciklama.toLowerCase().contains('hakediş tahsilatı') ||
                             islem.aciklama.contains('#H:[');
          if (!isSettlement) {
            gelir += islem.borc;
          }

          if (islem.alacak > 0) {
            bool isWorker = workerCariIds.contains(islem.cariHesapId);
            if (isWorker) {
              int wId = cariToWorker[islem.cariHesapId]!;
              projectWorkerPayment[wId] = (projectWorkerPayment[wId] ?? 0) + islem.alacak;
            } else {
              // Maaş ve avans ödemelerini projeye bağlıysa Labor Cost içinde max(Work, Paid) olarak sayıyoruz
              bool isLaborPayment = islem.aciklama.toLowerCase().contains('maaş ödemesi') ||
                                   islem.aciklama.toLowerCase().contains('avans') ||
                                   islem.aciklama.toLowerCase().contains('işçi ödemesi') ||
                                   islem.aciklama == 'Hesap Kapatma';

              if (!isLaborPayment) {
                nonLaborGider += islem.alacak;
              }
            }
          }
        }
      }

      Map<int, int> projectWorkedCounts = {};
      Map<int, int> projectLeaveCounts = {};
      Map<int, int> projectAbsentCounts = {};
      Map<int, int> projectSundayCounts = {};

      // Projeye bağlı İşçilik (Puantaj)
      for (var p in puantajlar) {
        if (p.projectId == project.id) {
          if (!inRange(p.tarih)) continue;
          final worker = workers.firstWhere((w) => w.id == p.workerId, orElse: () => Worker(adSoyad: 'Bilinmeyen', baslangicTarihi: DateTime.now()));
          double cost = calculateLaborCost(p, worker);
          projectWorkerAccrual[p.workerId] = (projectWorkerAccrual[p.workerId] ?? 0) + cost;

          // Update counts
          if (p.status == PuantajStatus.normal) {
            projectWorkedCounts[p.workerId] = (projectWorkedCounts[p.workerId] ?? 0) + 1;
          } else if ([PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)) {
            projectLeaveCounts[p.workerId] = (projectLeaveCounts[p.workerId] ?? 0) + 1;
          } else if (p.status == PuantajStatus.izinsiz) {
            projectAbsentCounts[p.workerId] = (projectAbsentCounts[p.workerId] ?? 0) + 1;
          }
        }
      }

      // Projeye bağlı Pazar Bonusları
      for (var w in workers) {
        if (w.id == null) continue;
        final workerPuantaj = puantajlar.where((p) => p.workerId == w.id).toList();
        if (workerPuantaj.isEmpty) continue;

        // start and end are already checked by inRange, but we need strictly bounded range for loop
        // We evaluate bonuses for the period between rangeStart and rangeEnd (if provided)
        DateTime loopStart = rangeStart ?? workerPuantaj.map((p) => p.tarih).reduce((a, b) => a.isBefore(b) ? a : b);
        DateTime loopEnd = rangeEnd ?? DateTime.now();

        DateTime current = DateTime(loopStart.year, loopStart.month, loopStart.day);
        while (current.isBefore(loopEnd.add(const Duration(seconds: 1)))) {
          if (current.weekday == DateTime.sunday) {
            bool earnedBonus = true;
            Map<int, int> projectCounts = {};
            for (int i = 0; i <= 6; i++) {
              DateTime checkDate = current.subtract(Duration(days: i));
              final dayPuantajlar = workerPuantaj.where((p) =>
                p.tarih.year == checkDate.year && p.tarih.month == checkDate.month && p.tarih.day == checkDate.day
              ).toList();

              if (i > 0) {
                if (dayPuantajlar.isEmpty || dayPuantajlar.any((item) => item.status == PuantajStatus.izinsiz)) {
                  earnedBonus = false;
                  break;
                }
              }
              if (dayPuantajlar.isNotEmpty && dayPuantajlar.last.projectId != null) {
                int pid = dayPuantajlar.last.projectId!;
                projectCounts[pid] = (projectCounts[pid] ?? 0) + 1;
              }
            }

            if (earnedBonus) {
              final sundayRecords = workerPuantaj.where((p) =>
                p.tarih.year == current.year && p.tarih.month == current.month && p.tarih.day == current.day
              ).toList();
              bool isPaidHolidayRecord = sundayRecords.any((p) =>
                [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)
              );
              
              int? majorityProjectId;
              if (projectCounts.isNotEmpty) {
                majorityProjectId = projectCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
              }

              if (!isPaidHolidayRecord && majorityProjectId == project.id) {
                double dailyRate = _getDailyRate(w);
                projectWorkerAccrual[w.id!] = (projectWorkerAccrual[w.id!] ?? 0) + dailyRate;
                projectSundayCounts[w.id!] = (projectSundayCounts[w.id!] ?? 0) + 1;
              }
            }
          }
          current = current.add(const Duration(days: 1));
        }
      }

      double periodEarned = 0;
      double periodPaid = projectLaborPayment;
      List<Map<String, dynamic>> laborItems = [];

      for (var w in workers) {
        if (w.id == null) continue;
        double acc = projectWorkerAccrual[w.id] ?? 0;
        double paid = projectWorkerPayment[w.id] ?? 0;
        double prev = globalWorkerHistoricalBalance[w.id] ?? 0.0;
        
        // Bu projede hakediş veya ödeme varsa listede göster
        double rAcc = acc.roundToDouble();
        double rPaid = paid.roundToDouble();
        double rPrev = prev.roundToDouble();

        if (rAcc > 0 || rPaid > 0 || rPrev.abs() > 0.1) {
          periodEarned += rAcc;
          periodPaid += rPaid;
          laborItems.add({
            'id': w.id,
            'name': w.adSoyad,
            'previous_balance': rPrev,
            'period_earned': rAcc,
            'period_paid': rPaid,
            'cumulative_balance': rPrev + rAcc - rPaid,
            'worked': projectWorkedCounts[w.id] ?? 0,
            'leave': projectLeaveCounts[w.id] ?? 0,
            'absent': projectAbsentCounts[w.id] ?? 0,
            'sunday': projectSundayCounts[w.id] ?? 0,
          });
        }
      }

      double finalLaborCost = periodEarned; // Kar hesabı için tahakkuk eden maliyeti kullanıyoruz

      reports.add({
        'projeId': project.id ?? 0,
        'projeAd': project.ad,
        'durum': project.durum.name,
        'gelir': gelir.roundToDouble(),
        'gider': (nonLaborGider + finalLaborCost).roundToDouble(),
        'kar': (gelir - (nonLaborGider + finalLaborCost)).roundToDouble(),
        'odenenIscilik': periodPaid.roundToDouble(),
        'bekleyenIscilik': periodEarned.roundToDouble() - periodPaid.roundToDouble(),
        'labor': {
          'previous_balance': globalWorkerHistoricalBalance.values.fold(0.0, (a, b) => a + b).roundToDouble(),
          'period_earned': periodEarned.roundToDouble(),
          'period_paid': periodPaid.roundToDouble(),
          'items': laborItems,
        }
      });
    }

    return reports;
  }


  // ========== CARİ İŞLEM İŞLEMLERİ ==========
  Future<int> insertCariIslem(CariIslem islem) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

      final int tempId = -DateTime.now().millisecondsSinceEpoch;
      final newIslem = islem.copyWith(id: tempId);

      final map = newIslem.toMap();
      map['user_id'] = userId;

      // 1. Hive'a kaydet
      await _cariIslemlerBox.put(tempId.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle
      final syncMap = Map<String, dynamic>.from(map);
      syncMap['temp_id'] = tempId;
      syncMap.remove('id');
      
      await SyncManager.instance.enqueueOperation('insert', 'cari_islemler', syncMap);

      // 3. Cari hesap bakiyesini güncelle (Offline-first updateCariHesap kullanır)
      final cari = await getCariHesap(islem.cariHesapId);
      if (cari != null) {
        final toplamlar = await getCariToplamlar(islem.cariHesapId);
        final yeniBakiye = toplamlar['bakiye'] ?? 0.0;
        await updateCariHesap(cari.copyWith(bakiye: yeniBakiye));
      }

      return tempId;
    } catch (e) {
      print('DEBUG: insertCariIslem hatası: $e');
      rethrow;
    }
  }

  Future<List<CariIslem>> getAllCariIslemler({DateTime? baslangic, DateTime? bitis, bool ignoreThrottle = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    // 1. Önce Hive'dan oku
    List<CariIslem> localData = [];
    List<String> ghostKeys = [];
    
    for (var value in _cariIslemlerBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(value);
        if (map['user_id'] == userId) {
          final item = CariIslem.fromMap(map);
          
          // Ghost detection
          if (item.id! < 0 && !SyncManager.instance.isTempIdPending('cari_islemler', item.id!)) {
            ghostKeys.add(item.id.toString());
            continue;
          }
          
          bool match = true;
          if (baslangic != null && item.tarih.isBefore(DateTime(baslangic.year, baslangic.month, baslangic.day))) match = false;
          if (bitis != null && item.tarih.isAfter(DateTime(bitis.year, bitis.month, bitis.day, 23, 59, 59))) match = false;
          if (match) localData.add(item);
        }
      } catch (e) {
        print('DEBUG: Error parsing localized cariislem JSON: $e');
      }
    }

    // Clean up ghosts
    if (ghostKeys.isNotEmpty) {
      for (var key in ghostKeys) {
        await _cariIslemlerBox.delete(key);
      }
      print('DEBUG: Purged ${ghostKeys.length} ghost CariIslem entries');
    }

    // 2. Online isek senkronize et (Throttle ekle)
    if (ignoreThrottle || _shouldSync('cari_islemler')) {
      _lastSyncTimes['cari_islemler'] = DateTime.now();
      _syncCariIslemlerFromServer(userId, localData, baslangic, bitis);
    }

    localData.sort((a, b) {
      final vadeCompare = (a.vade ?? DateTime(2099)).compareTo(b.vade ?? DateTime(2099));
      if (vadeCompare != 0) return vadeCompare;
      return a.id!.compareTo(b.id!);
    });
    return localData;
  }

  Future<void> _syncCariIslemlerFromServer(String userId, List<CariIslem> initialList, DateTime? baslangic, DateTime? bitis) async {
    try {
      var query = _supabase.from('cari_islemler').select().eq('user_id', userId);
      if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(baslangic));
      if (bitis != null) query = query.lte('tarih', _stripTimePrecision(bitis));

      final List<dynamic> data = await query;
      List<CariIslem> serverData = data.map((m) => CariIslem.fromMap(m)).toList();
      
      // SADECE silme sırasına alınmamış olanları ekle
      serverData = serverData.where((i) => !SyncManager.instance.isPendingDeletion('cari_islemler', i.id)).toList();
      
      // Eğer güncellenme sırasındaysa, sunucudan gelen eski veri yerine lokaldeki veriyi koru
      for (int i = 0; i < serverData.length; i++) {
        if (SyncManager.instance.isPendingUpdate('cari_islemler', serverData[i].id)) {
          final localMatch = initialList.where((l) => l.id == serverData[i].id);
          if (localMatch.isNotEmpty) {
             serverData[i] = localMatch.first;
          }
        }
      }
      
      List<CariIslem> tempList = initialList.where((item) => item.id! < 0 && SyncManager.instance.isTempIdPending('cari_islemler', item.id!)).toList();

      final allUpdatedData = [...serverData, ...tempList];

      for (var item in allUpdatedData) {
        final map = item.toMap();
        map['user_id'] = userId;
        await _cariIslemlerBox.put(item.id.toString(), jsonEncode(map));
      }
      SyncManager.instance.triggerSyncCompleted();
    } catch (e) {
      print('DEBUG: Background sync failed for CariIslemler: $e');
    }
  }

  Future<List<CariIslem>> getCariIslemlerByCariId(int cariId) async {
    final all = await getAllCariIslemler();
    return all.where((islem) => islem.cariHesapId == cariId).toList();
  }

  Future<List<CariIslem>> getCariIslemlerByProjectId(int projectId) async {
    final all = await getAllCariIslemler();
    return all.where((islem) => islem.projectId == projectId).toList();
  }

  Future<CariIslem?> getCariIslem(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final val = _cariIslemlerBox.get(id.toString());
    if (val != null) {
      return CariIslem.fromMap(jsonDecode(val));
    }

    final data = await _supabase.from('cari_islemler').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? CariIslem.fromMap(data) : null;
  }

  Future<int> updateCariIslem(CariIslem islem) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
    
    final map = islem.toMap();
    map['user_id'] = userId;

    // 1. Hive'ı güncelle
    await _cariIslemlerBox.put(islem.id.toString(), jsonEncode(map));

    // 2. SyncManager'a ekle (id > 0 ise)
    if (islem.id! > 0) {
      await SyncManager.instance.enqueueOperation('update', 'cari_islemler', map);
    } else {
      await SyncManager.instance.updatePendingInsert('cari_islemler', islem.id!, map);
    }

    // 3. Bakiye yeniden hesapla ve güncelle
    final cari = await getCariHesap(islem.cariHesapId);
    if (cari != null) {
      final toplamlar = await getCariToplamlar(islem.cariHesapId);
      final yeniBakiye = toplamlar['bakiye'] ?? 0.0;
      await updateCariHesap(cari.copyWith(bakiye: yeniBakiye));
    }

    return islem.id!;
  }

  Future<int> deleteCariIslem(int id) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    final islem = await getCariIslem(id);
    if (islem != null) {
      // 1. Hakediş Geri Alım Mantığı (TODO: Offline safety for hakedisler update)
      if (islem.aciklama.contains('#H:[')) {
        try {
          final start = islem.aciklama.indexOf('#H:[');
          final end = islem.aciklama.indexOf(']', start);
          if (start != -1 && end != -1) {
            final idsStr = islem.aciklama.substring(start + 4, end);
            if (idsStr.isNotEmpty) {
              final ids = idsStr.split(',').map((s) => int.parse(s.trim())).toList();
              // Bu kısım şimdilik online kalabilir veya hakedisler offline olduktan sonra düzeltilir
              if (SyncManager.instance.isOnline) {
                await _supabase
                    .from('hakedisler')
                    .update({'durum': HakedisDurum.bekliyor.name})
                    .filter('id', 'in', ids)
                    .eq('user_id', userId);
              }
            }
          }
        } catch (e) {
          print('DEBUG: Hakedis geri alım hatası: $e');
        }
      }
      
      // 2. Hive'dan sil
      await _cariIslemlerBox.delete(id.toString());
      
      // 3. Bakiyeyi yeniden hesapla ve güncelle
      final cari = await getCariHesap(islem.cariHesapId);
      if (cari != null) {
        final toplamlar = await getCariToplamlar(islem.cariHesapId);
        final yeniBakiye = toplamlar['bakiye'] ?? 0.0;
        await updateCariHesap(cari.copyWith(bakiye: yeniBakiye));
      }

      // 4. SyncManager'a ekle
      if (id > 0) {
        await SyncManager.instance.enqueueOperation('delete', 'cari_islemler', {'id': id});
      }
    }

    return id;
  }

  Future<Map<String, double>> getCariToplamlar(int? cariId) async {
    final islemler = cariId == null
        ? await getAllCariIslemler()
        : await getCariIslemlerByCariId(cariId);

    double toplamBorc = 0.0;
    double toplamAlacak = 0.0;

    for (var islem in islemler) {
      toplamBorc += islem.borc;
      toplamAlacak += islem.alacak;
    }

    return {
      'borc': toplamBorc,
      'alacak': toplamAlacak,
      'bakiye': toplamBorc - toplamAlacak,
    };
  }

  Future<void> close() async {
    // Supabase bağlantısını kapatmaya gerek yok
  }

  // ========== PROJE İŞLEMLERİ ==========
  Future<int> insertProject(Project project) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final int tempId = -DateTime.now().millisecondsSinceEpoch;
      final newProject = project.copyWith(id: tempId);
      
      final map = newProject.toMap();
      map['user_id'] = userId;

      print('DEBUG: Proje Hive\'a kaydediliyor, map: $map');

      // 1. Hive'a kaydet
      await _projectsBox.put(tempId.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle
      final syncMap = Map<String, dynamic>.from(map);
      syncMap['temp_id'] = tempId;
      syncMap.remove('id');
      
      await SyncManager.instance.enqueueOperation('insert', 'projects', syncMap);

      return tempId;
    } catch (e) {
      print('DEBUG: insertProject hatası: $e');
      rethrow;
    }
  }

  Future<List<Project>> getAllProjects({bool ignoreThrottle = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    // 1. Önce Hive'dan oku
    List<Project> localProjects = [];
    List<String> ghostKeys = [];
    
    for (var value in _projectsBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(value);
        if (map['user_id'] == userId) {
            final item = Project.fromMap(map);
            
            // Ghost detection
            if (item.id! < 0 && !SyncManager.instance.isTempIdPending('projects', item.id!)) {
              ghostKeys.add(item.id.toString());
              continue;
            }
            localProjects.add(item);
        }
      } catch (e) {
        print('DEBUG: Error parsing localized project JSON: $e');
      }
    }

    // Clean up ghosts
    if (ghostKeys.isNotEmpty) {
      for (var key in ghostKeys) {
        await _projectsBox.delete(key);
      }
      print('DEBUG: Purged ${ghostKeys.length} ghost Project entries');
    }

    // 2. Online isek senkronize et
    if (ignoreThrottle || _shouldSync('projects')) {
      _lastSyncTimes['projects'] = DateTime.now();
      _syncProjectsFromServer(userId, localProjects);
    }
    
    localProjects.sort((a, b) => a.ad.compareTo(b.ad));
    return localProjects;
  }
  
  Future<void> _syncProjectsFromServer(String userId, List<Project> initialList) async {
      try {
        final List<dynamic> data = await _supabase.from('projects').select().eq('user_id', userId);
        
        List<Project> serverProjects = data.map((m) => Project.fromMap(m)).toList();
        
        // SADECE silme sırasına alınmamış olanları ekle
        serverProjects = serverProjects.where((p) => !SyncManager.instance.isPendingDeletion('projects', p.id)).toList();
        
        // Eğer güncellenme sırasındaysa, sunucudan gelen eski veri yerine lokaldeki veriyi koru
        for (int i = 0; i < serverProjects.length; i++) {
          if (SyncManager.instance.isPendingUpdate('projects', serverProjects[i].id)) {
            final localMatch = initialList.where((l) => l.id == serverProjects[i].id);
            if (localMatch.isNotEmpty) {
               serverProjects[i] = localMatch.first;
            }
          }
        }
        
        List<Project> tempList = initialList.where((p) => p.id! < 0).toList();
        
        final allUpdatedProjects = [...serverProjects, ...tempList];
        
        await _projectsBox.clear();
        for (var p in allUpdatedProjects) {
           final map = p.toMap();
           map['user_id'] = userId;
           await _projectsBox.put(p.id.toString(), jsonEncode(map));
        }
        SyncManager.instance.triggerSyncCompleted();
      } catch (e) {
         print('DEBUG: Background sync failed for projects: $e');
      }
  }

  Future<Project?> getProject(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    final val = _projectsBox.get(id.toString());
    if (val != null) {
      return Project.fromMap(jsonDecode(val));
    }
    
    final data = await _supabase.from('projects').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? Project.fromMap(data) : null;
  }

  Future<int> updateProject(Project project) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final map = project.toMap();
      map['user_id'] = userId;

      // 1. Hive'ı güncelle
      await _projectsBox.put(project.id.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle (id > 0 ise)
      if (project.id! > 0) {
        await SyncManager.instance.enqueueOperation('update', 'projects', map);
      } else {
        await SyncManager.instance.updatePendingInsert('projects', project.id!, map);
      }
      
      return project.id!;
    } catch (e) {
      print('DEBUG: updateProject hatası: $e');
      rethrow;
    }
  }

  Future<int> deleteProject(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

      // 1. İlişkili Cari İşlemleri al ve Cari Bakiyelerini güncelle
      final projectIslemler = await getCariIslemlerByProjectId(id);
      for (var islem in projectIslemler) {
        final cari = await getCariHesap(islem.cariHesapId);
        if (cari != null) {
          final yeniBakiye = (cari.bakiye ?? 0.0) - islem.bakiye;
          await updateCariHesap(cari.copyWith(bakiye: yeniBakiye));
        }
      }

      // 3. Projeyi lokal'den sil
      await _projectsBox.delete(id.toString());
      
      // 4. Supabase veya Sync Queue'ya gönder
      if (id > 0) {
         // Silme işlemlerinde cascade için supabase tarafında da silme komutunu SyncManager'a gönderebiliriz.
         // Veya direkt supabase çağrıları yapabiliriz (Çünkü çocukları da silmek gerekiyor).
         // Çocuk kayıtları silebilmek için çevrimiçi olduğumuz bir an işlem yapılması gerektiğinden 
         // Bu kısımdaki diğer tabloları da offline silmek/queue'ya eklemek gerekebilir.
         // Şimdilik ana objeyi sadece: 
         await SyncManager.instance.enqueueOperation('delete', 'projects', {'id': id});
         
         // TODO: İleride diğer tablolar da tam hive-first olduğunda buralar değiştirilecek.
         // Şu an internet varken alt tablolar silinir, yoksa havada kalır ve hata verebilir. (Kapsamlı offline support)
         try {
             await _supabase.from('hakedisler').delete().eq('project_id', id);
             await _supabase.from('puantajlar').delete().eq('project_id', id);
             await _supabase.from('gelir_giderler').delete().eq('project_id', id);
             await _supabase.from('cari_islemler').delete().eq('project_id', id);
         } catch(e) {
             print("Child cascade deletion failed offline. Wait for SyncManager to fix relations: $e");
         }
      }
      return id;
    } catch (e) {
      print('DEBUG: deleteProject hatası: $id : $e');
      rethrow;
    }
  }

  // ========== HAKEDİŞ İŞLEMLERİ ==========
  Future<int> insertHakedis(Hakedis hakedis) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final int tempId = -DateTime.now().millisecondsSinceEpoch;
      final newHakedis = hakedis.copyWith(id: tempId);

      final map = newHakedis.toMap();
      map['user_id'] = userId;

      // 1. Hive'a kaydet
      await _hakedisBox.put(tempId.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle
      final syncMap = Map<String, dynamic>.from(map);
      syncMap['temp_id'] = tempId;
      syncMap.remove('id');
      
      await SyncManager.instance.enqueueOperation('insert', 'hakedisler', syncMap);

      return tempId;
    } catch (e) {
      print('DEBUG: insertHakedis hatası: $e');
      rethrow;
    }
  }

  Future<List<Hakedis>> getAllHakedisler({DateTime? baslangic, DateTime? bitis, bool ignoreThrottle = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    // 1. Önce Hive'dan oku
    List<Hakedis> localHakedisler = [];
    List<String> ghostKeys = [];
    
    for (var value in _hakedisBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(value);
        if (map['user_id'] == userId) {
            final h = Hakedis.fromMap(map);
            
            // Ghost detection
            if (h.id! < 0 && !SyncManager.instance.isTempIdPending('hakedisler', h.id!)) {
              ghostKeys.add(h.id.toString());
              continue;
            }
            
            bool match = true;
            if (baslangic != null && h.tarih.isBefore(DateTime(baslangic.year, baslangic.month, baslangic.day))) match = false;
            if (bitis != null && h.tarih.isAfter(DateTime(bitis.year, bitis.month, bitis.day, 23, 59, 59))) match = false;
            if (match) localHakedisler.add(h);
        }
      } catch (e) {
        print('DEBUG: Error parsing localized hakedis JSON: $e');
      }
    }

    // Clean up ghosts
    if (ghostKeys.isNotEmpty) {
      for (var key in ghostKeys) {
        await _hakedisBox.delete(key);
      }
      print('DEBUG: Purged ${ghostKeys.length} ghost Hakedis entries');
    }

    // 2. Online isek senkronize et (Throttle ekle)
    if (ignoreThrottle || _shouldSync('hakedisler')) {
      _lastSyncTimes['hakedisler'] = DateTime.now();
      _syncHakedislerFromServer(userId, localHakedisler, baslangic, bitis);
    }
    
    localHakedisler.sort((a, b) => b.tarih.compareTo(a.tarih));
    return localHakedisler;
  }
  
  Future<void> _syncHakedislerFromServer(String userId, List<Hakedis> initialList, DateTime? baslangic, DateTime? bitis) async {
      try {
        var query = _supabase.from('hakedisler').select().eq('user_id', userId);
        if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(baslangic));
        if (bitis != null) query = query.lte('tarih', _stripTimePrecision(bitis));
        
        final List<dynamic> data = await query;
        List<Hakedis> serverHakedisler = data.map((m) => Hakedis.fromMap(m)).toList();
        
        // SADECE silme sırasına alınmamış olanları ekle
        serverHakedisler = serverHakedisler.where((h) => !SyncManager.instance.isPendingDeletion('hakedisler', h.id)).toList();
        
        // Eğer güncellenme sırasındaysa, sunucudan gelen eski veri yerine lokaldeki veriyi koru
        for (int i = 0; i < serverHakedisler.length; i++) {
          if (SyncManager.instance.isPendingUpdate('hakedisler', serverHakedisler[i].id)) {
            final localMatch = initialList.where((l) => l.id == serverHakedisler[i].id);
            if (localMatch.isNotEmpty) {
               serverHakedisler[i] = localMatch.first;
            }
          }
        }
        
        List<Hakedis> tempList = initialList.where((h) => h.id! < 0 && SyncManager.instance.isTempIdPending('hakedisler', h.id!)).toList();
        
        final allUpdatedHakedisler = [...serverHakedisler, ...tempList];
        
        for (var h in allUpdatedHakedisler) {
           final map = h.toMap();
           map['user_id'] = userId;
           await _hakedisBox.put(h.id.toString(), jsonEncode(map));
        }
        SyncManager.instance.triggerSyncCompleted();
      } catch (e) {
         print('DEBUG: Background sync failed for hakedisler: $e');
      }
  }

  Future<List<Hakedis>> getHakedisByProjectId(int projectId) async {
    final all = await getAllHakedisler();
    return all.where((h) => h.projectId == projectId).toList();
  }

  Future<int> deleteHakedis(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      // 1. Hive'dan sil
      await _hakedisBox.delete(id.toString());
      
      // 2. SyncManager'a ekle
      if (id > 0) {
         await SyncManager.instance.enqueueOperation('delete', 'hakedisler', {'id': id});
      }
      return id;
    } catch (e) {
      print('DEBUG: deleteHakedis hatası: $id : $e');
      rethrow;
    }
  }

  Future<void> updateHakedis(Hakedis hakedis) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final map = hakedis.toMap();
      map['user_id'] = userId;

      // 1. Hive'ı güncelle
      await _hakedisBox.put(hakedis.id.toString(), jsonEncode(map));

      // 2. SyncManager'a ekle
      if (hakedis.id! > 0) {
        await SyncManager.instance.enqueueOperation('update', 'hakedisler', map);
      } else {
        await SyncManager.instance.updatePendingInsert('hakedisler', hakedis.id!, map);
      }
    } catch (e) {
      print('DEBUG: updateHakedis hatası: $e');
      rethrow;
    }
  }

  // ========== İŞÇİ VE PUANTAJ İŞLEMLERİ ==========
  Future<int> insertWorker(Worker worker) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      // Offline-first: Geçici negatif ID oluştur
      final int tempId = -DateTime.now().millisecondsSinceEpoch;
      final newWorker = worker.copyWith(id: tempId);
      
      final map = newWorker.toMap();
      map['user_id'] = userId;

      // 1. Hive'a kaydet
      await _workersBox.put(tempId.toString(), jsonEncode(map));

      // 2. SyncManager'a "insert" işlemi olarak ekle
      final syncMap = Map<String, dynamic>.from(map);
      syncMap['temp_id'] = tempId; // Senkronizasyon sonrası düzeltme için
      syncMap.remove('id'); // Supabase kendi üretecek
      
      await SyncManager.instance.enqueueOperation('insert', 'workers', syncMap);

      return tempId;
    } catch (e) {
      print('DEBUG: insertWorker hatası: $e');
      rethrow;
    }
  }

  Future<int> updateWorker(Worker worker) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      final map = worker.toMap();
      map['user_id'] = userId;

      // 1. Hive'ı güncelle
      await _workersBox.put(worker.id.toString(), jsonEncode(map));

      // Geçici bir ID ise sadece local'de güncelliyoruz, zaten insert kuyruğunda
      if (worker.id! > 0) {
        // 2. SyncManager'a ekle
        await SyncManager.instance.enqueueOperation('update', 'workers', map);
      } else {
        await SyncManager.instance.updatePendingInsert('workers', worker.id!, map);
      }

      return worker.id!;
    } catch (e) {
      print('DEBUG: updateWorker hatası: $e');
      rethrow;
    }
  }

  Future<void> dismissWorker(int workerId, DateTime dismissalDate) async {
    try {
      final worker = await getWorker(workerId);
      if (worker != null) {
        if (worker.cariHesapId != null) {
          try {
            await deleteCariHesap(worker.cariHesapId!);
          } catch (e) {
            print('DEBUG: Cari hesap silinemedi (muhtemelen geçmiş işlemler var), devam ediliyor: $e');
          }
        }
        final updatedWorker = worker.copyWith(
          aktif: false,
          istenCikisTarihi: dismissalDate,
        );
        await updateWorker(updatedWorker);
      }
    } catch (e) {
      print('DEBUG: dismissWorker hatası: $e');
      rethrow;
    }
  }

  Future<int> deleteWorker(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      
      await deletePuantajByWorkerId(id);
      
      // 1. Hive'dan sil
      await _workersBox.delete(id.toString());
      
      // Geçici ID ise Supabase'e göndermeye gerek yok
      if (id > 0) {
        // 2. SyncManager'a gönder
        await SyncManager.instance.enqueueOperation('delete', 'workers', {'id': id});
      }

      return id;
    } catch (e) {
      print('DEBUG: deleteWorker hatası: $id : $e');
      rethrow;
    }
  }

  Future<void> deletePuantajByWorkerId(int workerId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      await _supabase.from('puantajlar').delete().eq('worker_id', workerId).eq('user_id', userId);
    } catch (e) {
      print('DEBUG: deletePuantajByWorkerId hatası: $workerId : $e');
      rethrow;
    }
  }

  Future<List<Worker>> getAllWorkers({bool ignoreThrottle = false}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    
    // 1. Önce Hive'dan lokal verileri oku
    List<Worker> localWorkers = [];
    List<String> ghostKeys = [];
    
    for (var value in _workersBox.values) {
      try {
        final Map<String, dynamic> map = jsonDecode(value);
        if (map['user_id'] == userId) {
            final item = Worker.fromMap(map);
            
            // Ghost detection
            if (item.id! < 0 && !SyncManager.instance.isTempIdPending('workers', item.id!)) {
              ghostKeys.add(item.id.toString());
              continue;
            }
            localWorkers.add(item);
        }
      } catch (e) {
        print('DEBUG: Error parsing localized worker JSON: $e');
      }
    }

    // Clean up ghosts
    if (ghostKeys.isNotEmpty) {
      for (var key in ghostKeys) {
        await _workersBox.delete(key);
      }
      print('DEBUG: Purged ${ghostKeys.length} ghost Worker entries');
    }

    // 2. Eğer online isek, Supabase'den güncel veriyi çek ve Hive'ı eşle (Throttle ekle)
    if (ignoreThrottle || _shouldSync('workers')) {
      _lastSyncTimes['workers'] = DateTime.now();
      _syncWorkersFromServer(userId, localWorkers);
    }
    
    return localWorkers;
  }

  Future<void> _syncWorkersFromServer(String userId, List<Worker> initialList) async {
      try {
        final List<dynamic> data = await _supabase.from('workers').select().eq('user_id', userId);
        
        // Sadece server'dan gelen verileri veya geçici (id < 0) olanları saklıyoruz.
        // Server'dan silinmiş ama lokalde ID'si > 0 olanlar kaldırılacak.
        
        // Yeni listeyi oluştur
        List<Worker> serverWorkers = data.map((m) => Worker.fromMap(m)).toList();
        
        // SADECE silme sırasına alınmamış olanları ekle
        serverWorkers = serverWorkers.where((w) => !SyncManager.instance.isPendingDeletion('workers', w.id)).toList();
        
        // Eğer güncelleme sırasındaysa, sunucudan gelen eski veriyi değil, lokaldeki güncel veriyi kullan
        for (int i = 0; i < serverWorkers.length; i++) {
           if (SyncManager.instance.isPendingUpdate('workers', serverWorkers[i].id)) {
              final localMatch = initialList.where((l) => l.id == serverWorkers[i].id);
              if (localMatch.isNotEmpty) {
                 serverWorkers[i] = localMatch.first;
              }
           }
        }
        
        // Geçiçi id'ye sahip (henüz senkronize edilmemiş) kayıtları ekle
        List<Worker> tempList = initialList.where((w) => w.id! < 0).toList();
        
        // Birleştir ve kutuya yaz
        final allUpdatedWorkers = [...serverWorkers, ...tempList];
        
        // Kutuyu tamamen tazelemek için temizle ve tekrar ekle
        await _workersBox.clear();
        for (var w in allUpdatedWorkers) {
           final map = w.toMap();
           map['user_id'] = userId;
           await _workersBox.put(w.id.toString(), jsonEncode(map));
        }
        SyncManager.instance.triggerSyncCompleted();
      } catch (e) {
         print('DEBUG: Background sync failed for workers: $e');
      }
  }

  Future<Worker?> getWorker(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    final val = _workersBox.get(id.toString());
    if (val != null) {
      return Worker.fromMap(jsonDecode(val));
    }
    
    final data = await _supabase.from('workers').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? Worker.fromMap(data) : null;
  }

  Future<Worker?> getWorkerByCariId(int cariId) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final data = await _supabase.from('workers').select().eq('cari_hesap_id', cariId).eq('user_id', userId).maybeSingle();
    return data != null ? Worker.fromMap(data) : null;
  }


  Future<int> insertPuantaj(Puantaj puantaj) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

      final normalizedDate = _normalizeDate(puantaj.tarih);
      
      // 1. Mükerrer önleme kontrolü (Aynı gün ve işçi için kayıt var mı?)
      final dayStart = normalizedDate;
      final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      
      // Lokalden kontrol et
      int? existingId;
      for (var value in _puantajBox.values) {
         final m = jsonDecode(value);
         if (m['user_id'] == userId && m['worker_id'] == puantaj.workerId) {
            final t = DateTime.parse(m['tarih']);
            if (t.isAtSameMomentAs(dayStart) || (t.isAfter(dayStart) && t.isBefore(dayEnd))) {
               existingId = int.tryParse(m['id'].toString());
               break;
            }
         }
      }

      final idToUse = puantaj.id ?? existingId ?? (-DateTime.now().millisecondsSinceEpoch);
      final newPuantaj = puantaj.copyWith(id: idToUse, tarih: normalizedDate);
      
      final map = newPuantaj.toMap();
      map['user_id'] = userId;

      // 2. Hive'a kaydet
      await _puantajBox.put(idToUse.toString(), jsonEncode(map));

      // 3. SyncManager'a ekle
      final syncMap = Map<String, dynamic>.from(map);
      bool isNewOffline = (puantaj.id == null && existingId == null);
      if (idToUse < 0) {
        if (isNewOffline) {
          syncMap['temp_id'] = idToUse;
          syncMap.remove('id');
          await SyncManager.instance.enqueueOperation('insert', 'puantajlar', syncMap);
        } else {
          await SyncManager.instance.updatePendingInsert('puantajlar', idToUse, map);
        }
      } else {
        await SyncManager.instance.enqueueOperation('update', 'puantajlar', syncMap);
      }

      return idToUse;
    } catch (e) {
      print('DEBUG: insertPuantaj hatası: $e');
      rethrow;
    }
  }

  Future<List<Puantaj>> getPuantajByWorkerId(int workerId, DateTime? baslangic, DateTime? bitis) async {
    final all = await getAllPuantajlar(baslangic: baslangic, bitis: bitis);
    return all.where((p) => p.workerId == workerId).toList();
  }

  Future<List<Puantaj>> getPuantajByProjectId(int projectId) async {
    final all = await getAllPuantajlar();
    return all.where((p) => p.projectId == projectId).toList();
  }

  Future<int> deletePuantaj(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

      // 1. Hive'dan sil
      await _puantajBox.delete(id.toString());

      // 2. SyncManager'a ekle
      if (id > 0) {
        await SyncManager.instance.enqueueOperation('delete', 'puantajlar', {'id': id});
      }
      return id;
    } catch (e) {
      print('DEBUG: deletePuantaj hatası: $id : $e');
      rethrow;
    }
  }

  double calculateLaborCost(Puantaj p, Worker w) {
    if (p.status == PuantajStatus.izinsiz) return 0;

    double hourlyRate = 0;
    if (w.maasTuru == WorkerSalaryType.saatlik) {
      hourlyRate = w.maasTutari;
    } else if (w.maasTuru == WorkerSalaryType.gunluk) {
      hourlyRate = w.maasTutari / 8;
    } else if (w.maasTuru == WorkerSalaryType.aylik) {
      hourlyRate = w.maasTutari / 240; // 30 gün * 8 saat = 240 saat
    }

    // Normal çalışma normal ücret, fazla mesai 1.5 katı ücret
    return (p.saat * hourlyRate) + (p.mesai * hourlyRate * 1.5);
  }

  double _getDailyRate(Worker w) {
    if (w.maasTuru == WorkerSalaryType.gunluk) return w.maasTutari;
    if (w.maasTuru == WorkerSalaryType.saatlik) return w.maasTutari * 8;
    if (w.maasTuru == WorkerSalaryType.aylik) return w.maasTutari / 30;
    return 0;
  }

  Future<double> _calculateWorkerSundayBonuses(Worker w, DateTime start, DateTime end, List<Puantaj> allWorkerPuantaj) async {
    double totalBonus = 0;
    double dailyRate = _getDailyRate(w);
    if (dailyRate <= 0) return 0;

    // Find all Sundays in the range [start, end]
    DateTime current = DateTime(start.year, start.month, start.day);
    while (current.isBefore(end.add(const Duration(seconds: 1)))) {
      if (current.weekday == DateTime.sunday) {
        // Found a Sunday, check the 6 days before it (Mon-Sat)
        bool earnedBonus = true;
        for (int i = 0; i <= 6; i++) {
          DateTime checkDate = current.subtract(Duration(days: i));
          // Check if there is a puantaj for this date
          final dayPuantajlar = allWorkerPuantaj.where((p) =>
            p.tarih.year == checkDate.year &&
            p.tarih.month == checkDate.month &&
            p.tarih.day == checkDate.day
          ).toList();

          if (i > 0) {
            if (dayPuantajlar.isEmpty || dayPuantajlar.any((item) => item.status == PuantajStatus.izinsiz)) {
              earnedBonus = false;
              break;
            }
          }
        }

        if (earnedBonus) {
          // Rule: If sunday itself has a paid leave record, bonus is not added (record is the bonus).
          final sundayRecords = allWorkerPuantaj.where((p) =>
            p.tarih.year == current.year && p.tarih.month == current.month && p.tarih.day == current.day
          ).toList();

          bool isPaidHolidayRecord = sundayRecords.any((p) =>
            [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)
          );

          if (!isPaidHolidayRecord) {
            totalBonus += dailyRate;
          }
        }
      }
      current = current.add(const Duration(days: 1));
    }
    return totalBonus;
  }

  Future<Map<String, dynamic>> getPersonnelSummary() async {
    final workers = await getAllWorkers();
    final puantajlar = await getAllPuantajlar();
    final cariIslemler = await getAllCariIslemler();

    int totalWorkers = workers.length;
    int activeWorkers = workers.where((w) => w.aktif).length;
    int dismissedWorkers = totalWorkers - activeWorkers;

    double totalAccrued = 0;
    double totalPaid = 0;

    final workerCariIds = workers.map((w) => w.cariHesapId).whereType<int>().toSet();
    final Map<int, Worker> workerMap = {for (var w in workers) w.id!: w};

    for (var p in puantajlar) {
      final w = workerMap[p.workerId];
      if (w != null) {
        totalAccrued += calculateLaborCost(p, w);
      }
    }

    // Add Sunday bonuses to totalAccrued
    for (var w in workers) {
      final workerPuantaj = puantajlar.where((p) => p.workerId == w.id).toList();
      if (workerPuantaj.isEmpty) continue;

      final firstDate = workerPuantaj.map((p) => p.tarih).reduce((a, b) => a.isBefore(b) ? a : b);
      // We check until today or the last puantaj date
      final lastDate = DateTime.now();

      double bonus = await _calculateWorkerSundayBonuses(w, firstDate, lastDate, workerPuantaj);
      totalAccrued += bonus;
    }

    for (var islem in cariIslemler) {
      if (workerCariIds.contains(islem.cariHesapId)) {
        totalPaid += islem.alacak;
      }
    }

    return {
      'total': totalWorkers,
      'active': activeWorkers,
      'dismissed': dismissedWorkers,
      'accrued': totalAccrued,
      'paid': totalPaid,
      'balance': totalAccrued - totalPaid,
    };
  }

  Future<Map<String, dynamic>> getSettlementReport(DateTime start, DateTime end, {List<int>? projectIds}) async {
    final rangeEnd = end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    final rangeStart = DateTime(start.year, start.month, start.day);

    final results = await Future.wait<List<dynamic>>([
      getAllPuantajlar(), // Fetch all for historical reconciliation
      getAllWorkers(),
      getAllFaturalar(baslangic: rangeStart, bitis: rangeEnd),
      getAllGelirGider(baslangic: rangeStart, bitis: rangeEnd),
      getAllCariIslemler(), // Fetch all to allow matching by vade
      getAllHakedisler(baslangic: rangeStart, bitis: rangeEnd),
      getAllProjects(),
    ]);

    final puantajlar = results[0] as List<Puantaj>;
    final workers = results[1] as List<Worker>;
    final faturalar = results[2] as List<Fatura>;
    final gelirGiderler = results[3] as List<GelirGider>;
    final cariIslemler = results[4] as List<CariIslem>;
    final hakedisler = results[5] as List<Hakedis>;
    final projects = results[6] as List<Project>;

    // Helper to check if a date is within range
    bool inRange(DateTime d) {
      return d.isAfter(rangeStart.subtract(const Duration(seconds: 1))) &&
             d.isBefore(rangeEnd.add(const Duration(seconds: 1)));
    }

    bool belongsToPeriod(CariIslem islem) => inRange(_getEffectiveDate(islem));

    // 0. Mutabakat: Tüm Zamanlar Verisi Üzerinden Bakiye Hesaplama
    Map<int, double> workerHistoricalBalance = {};
    Map<int, double> workerCumulativeBalance = {};
    
    for (var w in workers) {
      if (w.id == null) continue;
      
      final workerPuantaj = puantajlar.where((p) => p.workerId == w.id).toList();
      double histEarned = 0;
      double totalEarned = 0;
      
      // Puantaj ve Bonuslar
      for (var p in workerPuantaj) {
        if (projectIds != null && !projectIds.contains(p.projectId)) continue;
        double cost = calculateLaborCost(p, w);
        if (p.tarih.isBefore(rangeStart)) histEarned += cost;
        totalEarned += cost;
      }
      
      // Pazar Bonusları (Kümülatif hesaplama için basitleştirilmiş döngü)
      DateTime bonusStart = DateTime(2024, 1, 1);
      if (w.baslangicTarihi.isAfter(bonusStart)) bonusStart = DateTime(w.baslangicTarihi.year, w.baslangicTarihi.month, w.baslangicTarihi.day);
      
      DateTime d = bonusStart;
      while (d.isBefore(rangeEnd.add(const Duration(seconds: 1)))) {
        if (d.weekday == DateTime.sunday) {
          bool earnedBonus = true;
          Map<int, int> pCounts = {};
          for (int i = 0; i <= 6; i++) {
            DateTime checkDate = d.subtract(Duration(days: i));
            final dayPuantajlar = workerPuantaj.where((p) => p.tarih.year == checkDate.year && p.tarih.month == checkDate.month && p.tarih.day == checkDate.day).toList();
            if (i > 0 && (dayPuantajlar.isEmpty || dayPuantajlar.any((item) => item.status == PuantajStatus.izinsiz))) { earnedBonus = false; break; }
            if (dayPuantajlar.isNotEmpty && dayPuantajlar.last.projectId != null) {
              int pid = dayPuantajlar.last.projectId!;
              pCounts[pid] = (pCounts[pid] ?? 0) + 1;
            }
          }
          if (earnedBonus) {
             int? majPid;
             if (pCounts.isNotEmpty) majPid = pCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
             if (projectIds != null && (majPid == null || !projectIds.contains(majPid))) earnedBonus = false;
          }
          if (earnedBonus) {
            final sundayRecords = workerPuantaj.where((p) => p.tarih.year == d.year && p.tarih.month == d.month && p.tarih.day == d.day).toList();
            if (!sundayRecords.any((p) => [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status))) {
              double bonus = _getDailyRate(w);
              if (d.isBefore(rangeStart)) histEarned += bonus;
              totalEarned += bonus;
            }
          }
        }
        d = d.add(const Duration(days: 1));
      }

      // Cari İşlemler (Ödemeler Alacak, Ekstra Haklar Borç)
      double histPaid = 0;
      double totalPaid = 0;
      if (w.cariHesapId != null) {
        for (var islem in cariIslemler) {
          if (islem.cariHesapId != w.cariHesapId) continue;
          if (projectIds != null && islem.projectId != null && !projectIds.contains(islem.projectId)) continue;
          
          DateTime effectiveDate = _getEffectiveDate(islem);
          
          if (effectiveDate.isBefore(rangeStart)) {
            histPaid += (islem.alacak - islem.borc);
          }
          totalPaid += (islem.alacak - islem.borc);
        }
      }
      
      workerHistoricalBalance[w.id!] = histEarned - histPaid;
      workerCumulativeBalance[w.id!] = totalEarned - totalPaid;
    }

    // 1. Personel / Maaş Hesaplama Logic Cleanup (Already calculated globally, just populate breakdowns)
    double totalPreviousBalance = 0;
    double periodEarnedTotal = 0;
    double periodPaidTotal = 0;
    Map<int, Map<String, dynamic>> workerBreakdownMap = {};
    final workerCariIds = workers.map((w) => w.cariHesapId).whereType<int>().toSet();

    for (var w in workers) {
      if (w.id == null) continue;
      double prev = workerHistoricalBalance[w.id!] ?? 0.0;
      double cumulative = workerCumulativeBalance[w.id!] ?? 0.0;
      
      // Dönem İçi Hak ve Öde (Basit Çıkarma)
      // Ancak proje filtresi varsa burayı tekrar süzmemiz gerekebilir.
      // Şimdilik global bakiyeyi esas alıyoruz çünkü kullanıcı "0 TL yazıcak" dedi.
      
      double pEarned = 0;
      double pPaid = 0;
      int workedCount = 0;
      int leaveCount = 0;
      int absentCount = 0;
      int sundayCount = 0;
      
      final workerPuantaj = puantajlar.where((p) => p.workerId == w.id).toList();
      for (var p in workerPuantaj) {
        if (inRange(p.tarih)) {
          if (projectIds != null && !projectIds.contains(p.projectId)) continue;
          pEarned += calculateLaborCost(p, w);
          
          if (p.status == PuantajStatus.normal) {
            workedCount++;
          } else if ([PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)) {
            leaveCount++;
          } else if (p.status == PuantajStatus.izinsiz) {
            absentCount++;
          }
        }
      }
      
      // Sunday Bonuses in period
      DateTime d = rangeStart;
      while (d.isBefore(rangeEnd.add(const Duration(seconds: 1)))) {
        if (d.weekday == DateTime.sunday) {
          bool earnedBonus = true;
          Map<int, int> pCounts = {};
          for (int i = 0; i <= 6; i++) {
            DateTime cD = d.subtract(Duration(days: i));
            final dayP = workerPuantaj.where((p) => p.tarih.year == cD.year && p.tarih.month == cD.month && p.tarih.day == cD.day).toList();
            if (i > 0 && (dayP.isEmpty || dayP.any((item) => item.status == PuantajStatus.izinsiz))) { earnedBonus = false; break; }
            if (dayP.isNotEmpty && dayP.last.projectId != null) {
              int pid = dayP.last.projectId!;
              pCounts[pid] = (pCounts[pid] ?? 0) + 1;
            }
          }
          if (earnedBonus) {
             int? majPid;
             if (pCounts.isNotEmpty) majPid = pCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
             if (projectIds != null && (majPid == null || !projectIds.contains(majPid))) earnedBonus = false;
          }
          if (earnedBonus) {
            final sunR = workerPuantaj.where((p) => p.tarih.year == d.year && p.tarih.month == d.month && p.tarih.day == d.day).toList();
            if (!sunR.any((p) => [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status))) {
              pEarned += _getDailyRate(w);
              sundayCount++;
            }
          }
        }
        d = d.add(const Duration(days: 1));
      }
      
      if (w.cariHesapId != null) {
        for (var islem in cariIslemler) {
          if (islem.cariHesapId != w.cariHesapId) continue;
          if (belongsToPeriod(islem)) {
            if (projectIds != null && islem.projectId != null && !projectIds.contains(islem.projectId)) continue;
            pPaid += islem.alacak;
            pEarned += islem.borc;
          }
        }
      }

      // Consistently round for visual and mathematical integrity
      double roundedEarned = pEarned.roundToDouble();
      double roundedPaid = pPaid.roundToDouble();
      double roundedPrev = prev.roundToDouble();

      periodEarnedTotal += roundedEarned;
      periodPaidTotal += roundedPaid;
      totalPreviousBalance += roundedPrev;
      
      workerBreakdownMap[w.id!] = {
        'id': w.id, 'name': w.adSoyad, 'cariId': w.cariHesapId,
        'previous_balance': roundedPrev, 
        'period_earned': roundedEarned, 
        'period_paid': roundedPaid,
        'period_balance': roundedEarned - roundedPaid,
        'cumulative_balance': roundedPrev + roundedEarned - roundedPaid,
        'worked': workedCount,
        'leave': leaveCount,
        'absent': absentCount,
        'sunday': sundayCount,
      };
    }

    workerBreakdownMap.removeWhere((id, data) => (data['period_earned'] as double) == 0 && (data['period_paid'] as double) == 0 && (data['previous_balance'] as double).abs() < 0.1);
    for (var item in workerBreakdownMap.values) {
      item['amount'] = item['cumulative_balance']; 
      item['net_debt'] = item['cumulative_balance'];
    }

    // 2. Fatura ve KDV Analizi
    double toplamSatis = 0;
    double toplamAlis = 0;
    double satisKdv = 0;
    double alisKdv = 0;
    Map<int, Map<String, dynamic>> invoiceBalances = {};

    for (var f in faturalar) {
      if (inRange(f.tarih)) {
        // Faturalarda şu an proje ID'si yok, bu yüzden bir proje seçiliyse faturaları dahil etmiyoruz
        if (projectIds != null && projectIds.isNotEmpty) continue;

        if (f.tipi == FaturaTipi.satis) {
          toplamSatis += f.toplamTutar;
          satisKdv += f.kdvTutari;
          if (f.cariHesapId != null) {
            if (!invoiceBalances.containsKey(f.cariHesapId)) {
              invoiceBalances[f.cariHesapId!] = {'name': f.cariHesapUnvan ?? 'Bilinmeyen', 'cariId': f.cariHesapId, 'amount': 0.0};
            }
            invoiceBalances[f.cariHesapId!]!['amount'] += f.genelToplam;
          }
        } else {
          toplamAlis += f.toplamTutar;
          alisKdv += f.kdvTutari;
          if (f.cariHesapId != null) {
            if (!invoiceBalances.containsKey(f.cariHesapId)) {
              invoiceBalances[f.cariHesapId!] = {'name': f.cariHesapUnvan ?? 'Bilinmeyen', 'cariId': f.cariHesapId, 'amount': 0.0};
            }
            invoiceBalances[f.cariHesapId!]!['amount'] -= f.genelToplam;
          }
        }
      }
    }

    // 3. Genel Gelir / Gider
    double extraGelir = 0;
    double extraGider = 0;
    for (var gg in gelirGiderler) {
      if (inRange(gg.tarih)) {
        if (projectIds != null && gg.projectId != null && !projectIds.contains(gg.projectId)) continue;
        if (gg.tipi == GelirGiderTipi.gelir) {
          extraGelir += gg.tutar;
        } else {
          bool isLabor = (gg.kategori?.contains('İşçi') ?? false) || (gg.kategori?.contains('Maaş') ?? false);
          if (!isLabor) {
            extraGider += gg.tutar;
          }
        }
      }
    }

    // 4. Cari Bakiyeler
    double toplamCariBorcValue = 0;
    double toplamCariAlacakValue = 0;
    Map<int, Map<String, dynamic>> cariBalances = {};
    final cariHesapMap = {for (var c in await getAllCariHesaplar()) c.id!: c};

    double manuallyEnteredGelir = 0;
    double manuallyEnteredGider = 0;

    for (var islem in cariIslemler) {
      if (belongsToPeriod(islem)) {
        // Fix: Ensure unassigned (projesiz) transactions are excluded ONLY for non-worker items
        if (projectIds != null && (islem.projectId == null || !projectIds.contains(islem.projectId))) {
           bool isWorker = workerCariIds.contains(islem.cariHesapId);
           if (!isWorker) continue;
        }

        if (!workerCariIds.contains(islem.cariHesapId)) {
          toplamCariBorcValue += islem.borc;
          toplamCariAlacakValue += islem.alacak;

          if (!cariBalances.containsKey(islem.cariHesapId)) {
            cariBalances[islem.cariHesapId] = {
              'name': cariHesapMap[islem.cariHesapId]?.unvan ?? 'Bilinmeyen',
              'cariId': islem.cariHesapId,
              'balance': 0.0
            };
          }
          cariBalances[islem.cariHesapId]!['balance'] += (islem.borc - islem.alacak);

          // Kar/Zarar hesabı için manuel girişleri say (Maaş ve Hakediş ödemelerini geç)
          final String descStr = islem.aciklama;
          final String descLower = descStr.toLowerCase();
          final String descLowerTr = descStr.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
          
          if (!_isSettlementTransaction(islem)) {
            manuallyEnteredGelir += islem.borc;
            manuallyEnteredGider += islem.alacak;
          }
        }
      }
    }

    double toplamHakedisNetValue = 0; // Sadece Tahsil Edilenler (Finansal Özet için)
    double producedHakedisTotal = 0; // Tümü (Hakediş Bölümü için)
    double tahsilEdilenHakedisValue = 0;
    double bekleyenHakedisValue = 0;
    Map<int, Map<String, dynamic>> projectHakedisMap = {};

    for (var h in hakedisler) {
      if (inRange(h.tarih)) {
        // Proje filtresi kontrolü
        if (projectIds != null && !projectIds.contains(h.projectId)) continue;

        if (h.durum != HakedisDurum.iptal) {
          producedHakedisTotal += h.netTutar;
        }

        if (h.durum == HakedisDurum.tahsilEdildi) {
          toplamHakedisNetValue += h.netTutar;
        }

        final project = projects.firstWhere((p) => p.id == h.projectId, orElse: () => Project(ad: 'Bilinmeyen', baslangicTarihi: DateTime.now()));
        if (!projectHakedisMap.containsKey(h.projectId)) {
          projectHakedisMap[h.projectId] = {
            'projectId': h.projectId,
            'name': project.ad,
            'cariId': project.cariHesapId,
            'cariName': project.cariHesapUnvan,
            'amount': 0.0,
            'hakedisIds': <int>[],
          };
        }

        if (h.durum == HakedisDurum.tahsilEdildi) {
          tahsilEdilenHakedisValue += h.netTutar;
        } else if (h.durum == HakedisDurum.bekliyor) {
          bekleyenHakedisValue += h.netTutar;
          projectHakedisMap[h.projectId]!['amount'] += h.netTutar;
          (projectHakedisMap[h.projectId]!['hakedisIds'] as List<int>).add(h.id!);
        }
      }
    }

    return {
      'period_start': rangeStart,
      'period_end': rangeEnd,
      'labor': {
        'previous_balance': totalPreviousBalance.roundToDouble(),
        'period_earned': periodEarnedTotal.roundToDouble(),
        'period_paid': periodPaidTotal.roundToDouble(),
        'period_net': periodEarnedTotal.roundToDouble() - periodPaidTotal.roundToDouble(),
        'total_earned': periodEarnedTotal.roundToDouble(),
        'total_paid': periodPaidTotal.roundToDouble(),
        'net_debt': totalPreviousBalance.roundToDouble() + (periodEarnedTotal.roundToDouble() - periodPaidTotal.roundToDouble()),
        'cumulative_balance': totalPreviousBalance.roundToDouble() + (periodEarnedTotal.roundToDouble() - periodPaidTotal.roundToDouble()),
        'items': workerBreakdownMap.values.toList(),
      },
      'invoices': {
        'sales': toplamSatis.roundToDouble(),
        'purchases': toplamAlis.roundToDouble(),
        'sales_vat': satisKdv.roundToDouble(),
        'purchase_vat': alisKdv.roundToDouble(),
        'vat_balance': (satisKdv - alisKdv).roundToDouble(),
        'items': invoiceBalances.values.toList(),
      },
      'financials': {
        'total_revenue': (toplamSatis + extraGelir + manuallyEnteredGelir + tahsilEdilenHakedisValue).roundToDouble(),
        'total_cost': (toplamAlis + extraGider + manuallyEnteredGider + periodEarnedTotal).roundToDouble(),
        'net_profit': ((toplamSatis + extraGelir + manuallyEnteredGelir + tahsilEdilenHakedisValue) - (toplamAlis + extraGider + manuallyEnteredGider + periodEarnedTotal)).roundToDouble(),
        'extra_expense': (extraGider + manuallyEnteredGider).roundToDouble(),
      },
      'ledger': {
        'total_receivable': toplamCariBorcValue,
        'total_payable': toplamCariAlacakValue,
        'net_balance': toplamCariBorcValue - toplamCariAlacakValue,
        'items': cariBalances.values.toList(),
      },
      'hakedis': {
        'total_net': producedHakedisTotal,
        'collected': tahsilEdilenHakedisValue,
        'pending': bekleyenHakedisValue,
        'items': projectHakedisMap.values.where((item) => item['amount'] > 0).toList(),
      }
    };
  }

  Future<void> bulkInsertCariIslemler(List<CariIslem> islemler) async {
    for (var islem in islemler) {
      await insertCariIslem(islem);
    }
  }

  Future<void> bulkUpdateHakedisStatusByProject(List<int> projectIds, DateTime start, DateTime end, HakedisDurum newStatus) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

      final rangeStart = DateTime(start.year, start.month, start.day);
      final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

      // 1. Hive'da yerel olarak güncelle (Arayüzün anında güncellenmesi için kritik)
      final List<String> updatedKeys = [];
      for (var key in _hakedisBox.keys) {
        try {
          final value = _hakedisBox.get(key);
          if (value == null) continue;
          
          final Map<String, dynamic> map = jsonDecode(value);
          if (map['user_id'] == userId && projectIds.contains(map['project_id'])) {
            final hDate = DateTime.parse(map['tarih']);
            if (hDate.isAfter(rangeStart.subtract(const Duration(seconds: 1))) && 
                hDate.isBefore(rangeEnd.add(const Duration(seconds: 1))) &&
                map['durum'] == HakedisDurum.bekliyor.name) {
              
              map['durum'] = newStatus.name;
              await _hakedisBox.put(key, jsonEncode(map));
              updatedKeys.add(key);
            }
          }
        } catch (e) {
          print('DEBUG: bulkUpdateHakedis Hive error for key $key: $e');
        }
      }

      // 2. Supabase'i güncelle
      await _supabase
          .from('hakedisler')
          .update({'durum': newStatus.name})
          .filter('project_id', 'in', projectIds)
          .eq('durum', HakedisDurum.bekliyor.name)
          .eq('user_id', userId)
          .gte('tarih', rangeStart.toIso8601String())
          .lte('tarih', rangeEnd.toIso8601String());
          
      print('DEBUG: bulkUpdateHakedis completed. Locally updated ${updatedKeys.length} entries.');
    } catch (e) {
      print('DEBUG: bulkUpdateHakedisStatusByProject hatası: $e');
      rethrow;
    }
  }
}

