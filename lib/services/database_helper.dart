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

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _testUserId;
  void setTestUserId(String? id) => _testUserId = id;

  String? get currentUserId => _testUserId ?? _supabase.auth.currentUser?.id;

  DatabaseHelper._init();

  Future<void> init() async {
    // Supabase main.dart'ta initialize edildiği için burada bir şey yapmaya gerek yok
  }

  // ========== CARİ HESAP İŞLEMLERİ ==========
  Future<int> insertCariHesap(CariHesap cariHesap) async {
    try {
      final userId = currentUserId;
      final map = cariHesap.toMap()..remove('id');
      if (userId != null) map['user_id'] = userId;

      final response = await _supabase
          .from('cari_hesaplar')
          .insert(map)
          .select()
          .single();
      return response['id'] as int;
    } catch (e) {
      print('DEBUG: insertCariHesap hatası: $e');
      rethrow;
    }
  }

  Future<List<CariHesap>> getAllCariHesaplar() async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase.from('cari_hesaplar').select().eq('user_id', userId);
    return data.map((map) => CariHesap.fromMap(map)).toList()
      ..sort((a, b) => a.unvan.compareTo(b.unvan));
  }

  Future<CariHesap?> getCariHesap(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final data = await _supabase.from('cari_hesaplar').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? CariHesap.fromMap(data) : null;
  }

  Future<int> updateCariHesap(CariHesap cariHesap) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      await _supabase
          .from('cari_hesaplar')
          .update(cariHesap.toMap())
          .eq('id', cariHesap.id!)
          .eq('user_id', userId);
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

      // 1. İlişkili Kayıtları Sil (Cascade Data - Onaylı)
      await _supabase.from('cari_islemler').delete().eq('cari_hesap_id', id).eq('user_id', userId);
      await _supabase.from('faturalar').delete().eq('cari_hesap_id', id).eq('user_id', userId);
      await _supabase.from('gelir_giderler').delete().eq('cari_hesap_id', id).eq('user_id', userId);

      // 2. Worker/Project Bağlantılarını temizle (Unlink Infrastructure - Koruma Altında)
      await _supabase.from('workers').update({'cari_hesap_id': null}).eq('cari_hesap_id', id).eq('user_id', userId);
      await _supabase.from('projects').update({'cari_hesap_id': null}).eq('cari_hesap_id', id).eq('user_id', userId);

      // 3. Cariyi sil
      await _supabase.from('cari_hesaplar').delete().eq('id', id).eq('user_id', userId);
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
      final map = fatura.toMap()..remove('id');
      if (userId != null) map['user_id'] = userId;

      final response = await _supabase
          .from('faturalar')
          .insert(map)
          .select()
          .single();
      return response['id'] as int;
    } catch (e) {
      print('DEBUG: insertFatura hatası: $e');
      rethrow;
    }
  }

  Future<List<Fatura>> getAllFaturalar({DateTime? baslangic, DateTime? bitis}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    var query = _supabase.from('faturalar').select().eq('user_id', userId);
    if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(baslangic));
    if (bitis != null) query = query.lte('tarih', _stripTimePrecision(bitis));

    final List<dynamic> data = await query;
    return data.map((map) => Fatura.fromMap(map)).toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));
  }

  Future<List<Fatura>> getFaturalarByTipi(FaturaTipi tipi) async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase
        .from('faturalar')
        .select()
        .eq('user_id', userId)
        .eq('tipi', tipi.name);
    return data.map((map) => Fatura.fromMap(map)).toList();
  }

  Future<Fatura?> getFatura(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final data = await _supabase.from('faturalar').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? Fatura.fromMap(data) : null;
  }

  Future<int> updateFatura(Fatura fatura) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      await _supabase
          .from('faturalar')
          .update(fatura.toMap())
          .eq('id', fatura.id!)
          .eq('user_id', userId);
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
      await _supabase.from('faturalar').delete().eq('id', id).eq('user_id', userId);
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
      final map = stok.toMap()..remove('id');
      if (userId != null) map['user_id'] = userId;

      final response = await _supabase
          .from('stoklar')
          .insert(map)
          .select()
          .single();
      return response['id'] as int;
    } catch (e) {
      print('DEBUG: insertStok hatası: $e');
      rethrow;
    }
  }

  Future<List<Stok>> getAllStoklar() async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase.from('stoklar').select().eq('user_id', userId);
    return data.map((map) => Stok.fromMap(map)).toList()
      ..sort((a, b) => a.ad.compareTo(b.ad));
  }

  Future<Stok?> getStok(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final data = await _supabase.from('stoklar').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? Stok.fromMap(data) : null;
  }

  Future<int> updateStok(Stok stok) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      await _supabase
          .from('stoklar')
          .update(stok.toMap())
          .eq('id', stok.id!)
          .eq('user_id', userId);
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
      await _supabase.from('stoklar').delete().eq('id', id).eq('user_id', userId);
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
      final map = gelirGider.toMap()..remove('id');
      if (userId != null) map['user_id'] = userId;

      final response = await _supabase
          .from('gelir_giderler')
          .insert(map)
          .select()
          .single();
      return response['id'] as int;
    } catch (e) {
      print('DEBUG: insertGelirGider hatası: $e');
      rethrow;
    }
  }

  Future<List<GelirGider>> getAllGelirGider({DateTime? baslangic, DateTime? bitis}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    var query = _supabase.from('gelir_giderler').select().eq('user_id', userId);
    if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(baslangic));
    if (bitis != null) query = query.lte('tarih', _stripTimePrecision(bitis));

    final List<dynamic> data = await query;
    return data.map((map) => GelirGider.fromMap(map)).toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));
  }

  Future<List<GelirGider>> getGelirGiderByTipi(GelirGiderTipi tipi) async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase
        .from('gelir_giderler')
        .select()
        .eq('user_id', userId)
        .eq('tipi', tipi.name);
    return data.map((map) => GelirGider.fromMap(map)).toList();
  }

  Future<List<GelirGider>> getGelirGiderByProjectId(int projectId) async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase
        .from('gelir_giderler')
        .select()
        .eq('user_id', userId)
        .eq('project_id', projectId);
    return data.map((map) => GelirGider.fromMap(map)).toList();
  }

  Future<GelirGider?> getGelirGider(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final data = await _supabase.from('gelir_giderler').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? GelirGider.fromMap(data) : null;
  }

  Future<int> updateGelirGider(GelirGider gelirGider) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      await _supabase
          .from('gelir_giderler')
          .update(gelirGider.toMap())
          .eq('id', gelirGider.id!)
          .eq('user_id', userId);
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
      await _supabase.from('gelir_giderler').delete().eq('id', id).eq('user_id', userId);
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

  Future<List<Puantaj>> getAllPuantajlar({DateTime? baslangic, DateTime? bitis}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    var query = _supabase.from('puantajlar').select().eq('user_id', userId);

    if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(_normalizeDate(baslangic)));
    if (bitis != null) {
      final endNormalized = _normalizeDate(bitis).add(const Duration(hours: 23, minutes: 59, seconds: 59));
      query = query.lte('tarih', _stripTimePrecision(endNormalized));
    }

    final List<dynamic> data = await query;
    return data.map((map) => Puantaj.fromMap(map)).toList();
  }

  Future<List<CariIslem>> getUnifiedLedger({int? cariId, int? projectId}) async {
    final List<CariIslem> ledger = [];

    // 1. Cari İşlemler
    final islemler = await getAllCariIslemler();
    final allCaris = await getAllCariHesaplar();
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
      getAllCariIslemler(baslangic: start, bitis: end),
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
          h.tarih.isAfter(start.subtract(const Duration(days: 1))) &&
          h.tarih.isBefore(end.add(const Duration(days: 1)))) {
        toplamGelir += h.netTutar;
      }
    }

    // 2. Gelir/Gider ...
    for (var gg in gelirGiderler) {
      bool isLabor = (gg.kategori?.contains('İşçi') ?? false) || (gg.kategori?.contains('Maaş') ?? false);
      if (gg.tarih.isBefore(end.add(const Duration(days: 1)))) {
        bool inPeriod = gg.tarih.isAfter(start.subtract(const Duration(days: 1)));
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

      if (islem.tarih.isBefore(end.add(const Duration(days: 1)))) {
        bool inPeriod = islem.tarih.isAfter(start.subtract(const Duration(days: 1)));
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
      if (p.tarih.isBefore(end.add(const Duration(days: 1)))) {
        final worker = workers.firstWhere((w) => w.id == p.workerId, orElse: () => Worker(adSoyad: 'Bilinmeyen', baslangicTarihi: DateTime.now()));
        double cost = calculateLaborCost(p, worker);

        bool inPeriod = p.tarih.isAfter(start.subtract(const Duration(days: 1)));
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

    // Bekleyen hesapla (Dönem içi hak edilen vs Ödenen)
    double laborCostThisPeriod = workValueProducedThisPeriod > odenenIscilikThisPeriod
        ? workValueProducedThisPeriod
        : odenenIscilikThisPeriod;

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
          if (p.tarih.isAfter(start.subtract(const Duration(days: 1))) && p.tarih.isBefore(end.add(const Duration(days: 1)))) {
               personAccrualInPeriod += calculateLaborCost(p, worker);
          }
        }
      }

      // Add bonuses to breakdown accrual
      personAccrualInPeriod += (sundayCounts[wId] ?? 0) * _getDailyRate(worker);

      if (personAccrualInPeriod > 0) {
        double personPending = personAccrualInPeriod - (personPaymentInPeriod[wId] ?? 0);
        workerBreakdown[name] = {
          'amount': personPending < 0 ? 0.0 : personPending,
          'worked': workedCounts[wId] ?? 0,
          'leave': leaveCounts[wId] ?? 0,
          'sunday': sundayCounts[wId] ?? 0,
        };
      }
    }

    giderKategorileri['İşçilik (Ödenen)'] = odenenIscilikThisPeriod;
    
    // Restore the original totalPendingLabor calculation
    double totalPendingLabor = workValueProducedThisPeriod - odenenIscilikThisPeriod;
    if (totalPendingLabor < 0) totalPendingLabor = 0;
    giderKategorileri['İşçilik (Bekleyen)'] = totalPendingLabor;

    // Final Gider = Non-Labor Expenses + max(Accruals, Payments)
    toplamGider += laborCostThisPeriod;

    return {
      'gelir': toplamGelir,
      'gider': toplamGider,
      'kar': toplamGelir - toplamGider,
      'kategoriler': giderKategorileri,
      'worker_breakdown': workerBreakdown,
    };
  }

  Future<List<Map<String, dynamic>>> getProjectReports() async {
    final results = await Future.wait([
      getAllProjects(),
      getAllHakedisler(),
      getAllGelirGider(),
      getAllCariIslemler(),
      getAllPuantajlar(),
      getAllWorkers(),
    ]);

    final projects = results[0] as List<Project>;
    final hakedisler = results[1] as List<Hakedis>;
    final gelirGiderler = results[2] as List<GelirGider>;
    final islemler = results[3] as List<CariIslem>;
    final puantajlar = results[4] as List<Puantaj>;
    final workers = results[5] as List<Worker>;

    final workerCariIds = workers.map((w) => w.cariHesapId).where((id) => id != null).toSet();
    final Map<int, int> cariToWorker = {for (var w in workers) if (w.cariHesapId != null) w.cariHesapId!: w.id!};

    List<Map<String, dynamic>> reports = [];

    for (var project in projects) {
      double gelir = 0;
      double nonLaborGider = 0;

      Map<int, double> projectWorkerAccrual = {};
      Map<int, double> projectWorkerPayment = {};
      double unassignedLaborPayment = 0;

      // Hakedişler (Sadece tahsil edilenleri gelire ekle)
      for (var h in hakedisler) {
        if (h.projectId == project.id && h.durum == HakedisDurum.tahsilEdildi) {
          gelir += h.netTutar;
        }
      }

      // Projeye bağlı Gelir/Gider
      for (var gg in gelirGiderler) {
        if (gg.projectId == project.id) {
          if (gg.tipi == GelirGiderTipi.gelir) gelir += gg.tutar;
          if (gg.tipi == GelirGiderTipi.gider) {
            bool isLabor = (gg.kategori?.contains('İşçi') ?? false) || (gg.kategori?.contains('Maaş') ?? false);
            if (isLabor) {
              unassignedLaborPayment += gg.tutar;
            } else {
              nonLaborGider += gg.tutar;
            }
          }
        }
      }

      // Projeye bağlı Cari İşlemler
      for (var islem in islemler) {
        if (islem.projectId == project.id) {
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

      // Projeye bağlı İşçilik (Puantaj)
      for (var p in puantajlar) {
        if (p.projectId == project.id) {
          final worker = workers.firstWhere((w) => w.id == p.workerId, orElse: () => Worker(adSoyad: 'Bilinmeyen', baslangicTarihi: DateTime.now()));
          double cost = calculateLaborCost(p, worker);
          projectWorkerAccrual[p.workerId] = (projectWorkerAccrual[p.workerId] ?? 0) + cost;
        }
      }

      // Projeye bağlı Pazar Bonusları
      // Eğer işçi o hafta bu projede çalıştıysa ve Pazar hak ettiyse bu projeye yansıtılır.
      for (var w in workers) {
        if (w.id == null) continue;
        final workerPuantaj = puantajlar.where((p) => p.workerId == w.id).toList();
        if (workerPuantaj.isEmpty) continue;

        DateTime minDate = workerPuantaj.map((p) => p.tarih).reduce((a, b) => a.isBefore(b) ? a : b);
        DateTime maxDate = DateTime.now();

        DateTime current = DateTime(minDate.year, minDate.month, minDate.day);
        while (current.isBefore(maxDate.add(const Duration(seconds: 1)))) {
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
              }
            }
          }
          current = current.add(const Duration(days: 1));
        }
      }

      // Proje Labor Cost = Sum per worker Max(Accrual, Paid) + unassigned
      double projectLaborCost = unassignedLaborPayment;
      double totalPaidLabor = unassignedLaborPayment;
      double totalAccruedLabor = 0;

      for (var w in workers) {
        double acc = projectWorkerAccrual[w.id] ?? 0;
        double paid = projectWorkerPayment[w.id] ?? 0;
        totalAccruedLabor += acc;
        totalPaidLabor += paid;
        projectLaborCost += acc > paid ? acc : paid;
      }

      double totalBekleyen = projectLaborCost - totalPaidLabor;
      if (totalBekleyen < 0) totalBekleyen = 0;

      reports.add({
        'projeId': project.id,
        'projeAd': project.ad,
        'durum': project.durum.name,
        'gelir': gelir,
        'gider': nonLaborGider + projectLaborCost,
        'kar': gelir - (nonLaborGider + projectLaborCost),
        'odenenIscilik': totalPaidLabor,
        'bekleyenIscilik': totalBekleyen,
      });
    }

    return reports;
  }


  // ========== CARİ İŞLEM İŞLEMLERİ ==========
  Future<int> insertCariIslem(CariIslem islem) async {
    try {
      final userId = currentUserId;
      final map = islem.toMap()..remove('id');
      if (userId != null) map['user_id'] = userId;

      final response = await _supabase
          .from('cari_islemler')
          .insert(map)
          .select()
          .single();
      final id = response['id'] as int;

      // Cari hesap bakiyesini güncelle
      final cari = await getCariHesap(islem.cariHesapId);
      if (cari != null) {
        final yeniBakiye = (cari.bakiye ?? 0.0) + islem.bakiye;
        await updateCariHesap(cari.copyWith(bakiye: yeniBakiye));
      }

      return id;
    } catch (e) {
      print('DEBUG: insertCariIslem hatası: $e');
      rethrow;
    }
  }

  Future<List<CariIslem>> getAllCariIslemler({DateTime? baslangic, DateTime? bitis}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    var query = _supabase.from('cari_islemler').select().eq('user_id', userId);
    if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(baslangic));
    if (bitis != null) query = query.lte('tarih', _stripTimePrecision(bitis));

    final List<dynamic> data = await query;
    return data.map((map) => CariIslem.fromMap(map)).toList()
      ..sort((a, b) {
        final vadeCompare = (a.vade ?? DateTime(2099)).compareTo(b.vade ?? DateTime(2099));
        if (vadeCompare != 0) return vadeCompare;
        return a.id!.compareTo(b.id!);
      });
  }

  Future<List<CariIslem>> getCariIslemlerByCariId(int cariId) async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase
        .from('cari_islemler')
        .select()
        .eq('user_id', userId)
        .eq('cari_hesap_id', cariId);
    return data.map((map) => CariIslem.fromMap(map)).toList();
  }

  Future<List<CariIslem>> getCariIslemlerByProjectId(int projectId) async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase
        .from('cari_islemler')
        .select()
        .eq('user_id', userId)
        .eq('project_id', projectId);
    return data.map((map) => CariIslem.fromMap(map)).toList();
  }

  Future<CariIslem?> getCariIslem(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final data = await _supabase.from('cari_islemler').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? CariIslem.fromMap(data) : null;
  }

  Future<int> updateCariIslem(CariIslem islem) async {
    // Eski işlemi al ve bakiyeyi geri al
    final eskiIslem = await getCariIslem(islem.id!);
    if (eskiIslem != null) {
      final cari = await getCariHesap(eskiIslem.cariHesapId);
      if (cari != null) {
        final yeniBakiye = (cari.bakiye ?? 0.0) - eskiIslem.bakiye;
        await updateCariHesap(cari.copyWith(bakiye: yeniBakiye));
      }
    }

    final userId = currentUserId;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
    await _supabase
        .from('cari_islemler')
        .update(islem.toMap())
        .eq('id', islem.id!)
        .eq('user_id', userId);

    // Yeni bakiyeyi ekle
    final cari = await getCariHesap(islem.cariHesapId);
    if (cari != null) {
      final yeniBakiye = (cari.bakiye ?? 0.0) + islem.bakiye;
      await updateCariHesap(cari.copyWith(bakiye: yeniBakiye));
    }

    return islem.id!;
  }

  Future<int> deleteCariIslem(int id) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    final islem = await getCariIslem(id);
    if (islem != null) {
      final cari = await getCariHesap(islem.cariHesapId);
      if (cari != null) {
        final yeniBakiye = (cari.bakiye ?? 0.0) - islem.bakiye;
        await updateCariHesap(cari.copyWith(bakiye: yeniBakiye));
      }

      // Hakediş Geri Alım Mantığı
      if (islem.aciklama.contains('#H:[')) {
        try {
          final start = islem.aciklama.indexOf('#H:[');
          final end = islem.aciklama.indexOf(']', start);
          if (start != -1 && end != -1) {
            final idsStr = islem.aciklama.substring(start + 4, end);
            if (idsStr.isNotEmpty) {
              final ids = idsStr.split(',').map((s) => int.parse(s.trim())).toList();
              await _supabase
                  .from('hakedisler')
                  .update({'durum': HakedisDurum.bekliyor.name})
                  .filter('id', 'in', ids)
                  .eq('user_id', userId);
            }
          }
        } catch (e) {
          print('DEBUG: Hakedis geri alım hatası: $e');
        }
      }
    }

    await _supabase.from('cari_islemler').delete().eq('id', id).eq('user_id', userId);
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
      final map = project.toMap()..remove('id');
      if (userId != null) map['user_id'] = userId;

      print('DEBUG: Proje kaydediliyor, map: $map');

      final response = await _supabase
          .from('projects')
          .insert(map)
          .select()
          .single();
      return response['id'] as int;
    } catch (e) {
      print('DEBUG: insertProject hatası: $e');
      rethrow;
    }
  }

  Future<List<Project>> getAllProjects() async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase.from('projects').select().eq('user_id', userId);
    return data.map((map) => Project.fromMap(map)).toList()
      ..sort((a, b) => a.ad.compareTo(b.ad));
  }

  Future<Project?> getProject(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final data = await _supabase.from('projects').select().eq('id', id).eq('user_id', userId).maybeSingle();
    return data != null ? Project.fromMap(data) : null;
  }

  Future<int> updateProject(Project project) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      await _supabase
          .from('projects')
          .update(project.toMap())
          .eq('id', project.id!)
          .eq('user_id', userId);
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

      // 2. İlişkili kayıtları sil (Cascade)
      // Çocuk kayıtlardan user_id filtresini kaldırıyoruz çünkü projenin sahibi bizsek çocuklarını temizleyebilmeliyiz.
      // RLS zaten yetkimiz olmayan satırları silemememizi sağlayacaktır.
      await _supabase.from('hakedisler').delete().eq('project_id', id);
      await _supabase.from('puantajlar').delete().eq('project_id', id);
      await _supabase.from('gelir_giderler').delete().eq('project_id', id);
      await _supabase.from('cari_islemler').delete().eq('project_id', id);

      // 3. Projeyi sil - Burada user_id kontrolü şart! Sadece kendi projemizi silebiliriz.
      await _supabase.from('projects').delete().eq('id', id).eq('user_id', userId);
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
      final map = hakedis.toMap()..remove('id');
      if (userId != null) map['user_id'] = userId;

      final response = await _supabase
          .from('hakedisler')
          .insert(map)
          .select()
          .single();
      return response['id'] as int;
    } catch (e) {
      print('DEBUG: insertHakedis hatası: $e');
      rethrow;
    }
  }

  Future<List<Hakedis>> getAllHakedisler({DateTime? baslangic, DateTime? bitis}) async {
    final userId = currentUserId;
    if (userId == null) return [];
    var query = _supabase.from('hakedisler').select().eq('user_id', userId);
    if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(baslangic));
    if (bitis != null) query = query.lte('tarih', _stripTimePrecision(bitis));

    final List<dynamic> data = await query;
    return data.map((map) => Hakedis.fromMap(map)).toList();
  }

  Future<List<Hakedis>> getHakedisByProjectId(int projectId) async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase
        .from('hakedisler')
        .select()
        .eq('user_id', userId)
        .eq('project_id', projectId);
    return data.map((map) => Hakedis.fromMap(map)).toList();
  }

  Future<int> deleteHakedis(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      await _supabase.from('hakedisler').delete().eq('id', id).eq('user_id', userId);
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
      await _supabase
          .from('hakedisler')
          .update(hakedis.toMap())
          .eq('id', hakedis.id!)
          .eq('user_id', userId);
    } catch (e) {
      print('DEBUG: updateHakedis hatası: $e');
      rethrow;
    }
  }

  // ========== İŞÇİ VE PUANTAJ İŞLEMLERİ ==========
  Future<int> insertWorker(Worker worker) async {
    try {
      final userId = currentUserId;
      final map = worker.toMap()..remove('id');
      if (userId != null) map['user_id'] = userId;

      final response = await _supabase
          .from('workers')
          .insert(map)
          .select()
          .single();
      return response['id'] as int;
    } catch (e) {
      print('DEBUG: insertWorker hatası: $e');
      rethrow;
    }
  }

  Future<int> updateWorker(Worker worker) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      await _supabase
          .from('workers')
          .update(worker.toMap())
          .eq('id', worker.id!)
          .eq('user_id', userId);
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
      await _supabase.from('workers').delete().eq('id', id).eq('user_id', userId);
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

  Future<List<Worker>> getAllWorkers() async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase.from('workers').select().eq('user_id', userId);
    return data.map((map) => Worker.fromMap(map)).toList();
  }

  Future<Worker?> getWorker(int id) async {
    final userId = currentUserId;
    if (userId == null) return null;
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
      final map = puantaj.toMap();
      map['user_id'] = userId;
      map['tarih'] = normalizedDate.toIso8601String();

      // 1. Eğer ID zaten varsa direkt update yap
      if (puantaj.id != null) {
        await _supabase
            .from('puantajlar')
            .update(map)
            .eq('id', puantaj.id!)
            .eq('user_id', userId);
        return puantaj.id!;
      }

      // 2. ID yoksa, aynı gün ve işçi için kayıt var mı kontrol et (Mükerrer önleme)
      // Tarih aralığı kullanarak (o günün başı ve sonu) daha güvenli arama yapıyoruz
      final dayStart = normalizedDate;
      final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));

      final existing = await _supabase
          .from('puantajlar')
          .select('id')
          .eq('worker_id', puantaj.workerId)
          .gte('tarih', dayStart.toIso8601String())
          .lte('tarih', dayEnd.toIso8601String())
          .eq('user_id', userId);

      if (existing != null && (existing as List).isNotEmpty) {
        final List existingList = existing;
        final existingId = existingList.first['id'] as int;

        // Eğer birden fazla varsa (mükerrer), ilkini güncelle diğerlerini sil
        await _supabase
            .from('puantajlar')
            .update(map)
            .eq('id', existingId)
            .eq('user_id', userId);

        if (existingList.length > 1) {
          for (int i = 1; i < existingList.length; i++) {
            await _supabase.from('puantajlar').delete().eq('id', existingList[i]['id']).eq('user_id', userId);
          }
        }
        return existingId;
      }

      // 3. Hiç kayıt yoksa yeni ekle
      map.remove('id');
      final response = await _supabase
          .from('puantajlar')
          .insert(map)
          .select()
          .single();
      return response['id'] as int;
    } catch (e) {
      print('DEBUG: insertPuantaj hatası: $e');
      rethrow;
    }
  }

  Future<List<Puantaj>> getPuantajByWorkerId(int workerId, DateTime? baslangic, DateTime? bitis) async {
    final userId = currentUserId;
    if (userId == null) return [];
    var query = _supabase.from('puantajlar').select().eq('user_id', userId).eq('worker_id', workerId);
    if (baslangic != null) query = query.gte('tarih', _stripTimePrecision(_normalizeDate(baslangic)));
    if (bitis != null) {
      final endNormalized = _normalizeDate(bitis).add(const Duration(hours: 23, minutes: 59, seconds: 59));
      query = query.lte('tarih', _stripTimePrecision(endNormalized));
    }

    final List<dynamic> data = await query;
    return data.map((map) => Puantaj.fromMap(map)).toList();
  }

  Future<List<Puantaj>> getPuantajByProjectId(int projectId) async {
    final userId = currentUserId;
    if (userId == null) return [];
    final List<dynamic> data = await _supabase
        .from('puantajlar')
        .select()
        .eq('user_id', userId)
        .eq('project_id', projectId);
    return data.map((map) => Puantaj.fromMap(map)).toList();
  }

  Future<int> deletePuantaj(int id) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');
      await _supabase.from('puantajlar').delete().eq('id', id).eq('user_id', userId);
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
      getAllPuantajlar(baslangic: rangeStart.subtract(const Duration(days: 6)), bitis: rangeEnd),
      getAllWorkers(),
      getAllFaturalar(baslangic: rangeStart, bitis: rangeEnd),
      getAllGelirGider(baslangic: rangeStart, bitis: rangeEnd),
      getAllCariIslemler(baslangic: rangeStart, bitis: rangeEnd),
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

    // 1. Personel / Maaş Hesaplama
    double toplamIscilikHakedis = 0;
    double toplamIscilikOdeme = 0;
    Map<int, Map<String, dynamic>> workerDuesMap = {};

    final workerMap = {for (var w in workers) w.id!: w};
    final workerCariIds = workers.map((w) => w.cariHesapId).whereType<int>().toSet();
    final cariToWorkerName = {for (var w in workers) if (w.cariHesapId != null) w.cariHesapId!: w.adSoyad};

    // Standard puantaj calculation
    for (var p in puantajlar) {
      if (inRange(p.tarih)) {
        if (projectIds != null && !projectIds.contains(p.projectId)) continue;
        final w = workerMap[p.workerId];
        if (w != null) {
          double cost = calculateLaborCost(p, w);
          toplamIscilikHakedis += cost;
          if (!workerDuesMap.containsKey(w.id)) {
            workerDuesMap[w.id!] = {
              'name': w.adSoyad,
              'cariId': w.cariHesapId,
              'amount': 0.0,
              'worked': 0,
              'leave': 0,
              'sunday': 0,
            };
          }
          workerDuesMap[w.id!]!['amount'] += cost;
          if (p.status == PuantajStatus.normal) {
            workerDuesMap[w.id!]!['worked'] = (workerDuesMap[w.id!]!['worked'] as int) + 1;
          } else if ([PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)) {
            workerDuesMap[w.id!]!['leave'] = (workerDuesMap[w.id!]!['leave'] as int) + 1;
          }
        }
      }
    }

    // Sunday Bonus calculation
    for (var w in workers) {
      final workerPuantaj = puantajlar.where((p) => p.workerId == w.id).toList();

      // Calculate bonuses for the range specifically to get count
      int bonusCount = 0;
      DateTime current = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      while (current.isBefore(rangeEnd.add(const Duration(seconds: 1)))) {
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
            int? majorityProjectId;
            if (projectCounts.isNotEmpty) {
              majorityProjectId = projectCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
            }
            
            // Project filter check for bonus
            if (projectIds != null && (majorityProjectId == null || !projectIds.contains(majorityProjectId))) {
              earnedBonus = false;
            }
          }
          if (earnedBonus) {
            // Rule check for double counting on Sunday itself
            final sundayRecords = workerPuantaj.where((p) =>
              p.tarih.year == current.year && p.tarih.month == current.month && p.tarih.day == current.day
            ).toList();

            bool isPaidHolidayRecord = sundayRecords.any((p) =>
              [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)
            );

            if (!isPaidHolidayRecord) {
              bonusCount++;
            }
          }
        }
        current = current.add(const Duration(days: 1));
      }

      if (bonusCount > 0) {
        double dailyRate = _getDailyRate(w);
        double bonusTotal = bonusCount * dailyRate;
        toplamIscilikHakedis += bonusTotal;
        if (!workerDuesMap.containsKey(w.id)) {
          workerDuesMap[w.id!] = {
            'name': w.adSoyad,
            'cariId': w.cariHesapId,
            'amount': 0.0,
            'worked': 0,
            'leave': 0,
            'sunday': 0,
          };
        }
        workerDuesMap[w.id!]!['amount'] += bonusTotal;
        workerDuesMap[w.id!]!['sunday'] = (workerDuesMap[w.id!]!['sunday'] ?? 0) + bonusCount;
      }
    }

    for (var islem in cariIslemler) {
      if (inRange(islem.tarih)) {
        // Fix: Ensure we include unassigned (projectId == null) worker payments even when filtering by project
        // This ensures settlements made in the general account offset project-specific labor costs.
        if (projectIds != null && islem.projectId != null && !projectIds.contains(islem.projectId)) continue;
        if (projectIds != null && islem.projectId == null) {
          bool isWorker = workerCariIds.contains(islem.cariHesapId);
          if (!isWorker) continue;
        }

        if (workerCariIds.contains(islem.cariHesapId)) {
          toplamIscilikOdeme += islem.alacak;
          // Find worker for this cariId
          final w = workers.firstWhere((w) => w.cariHesapId == islem.cariHesapId);
          if (!workerDuesMap.containsKey(w.id)) {
            workerDuesMap[w.id!] = {'name': w.adSoyad, 'cariId': w.cariHesapId, 'amount': 0.0};
          }
          workerDuesMap[w.id!]!['amount'] -= islem.alacak;
        }
      }
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
      if (inRange(islem.tarih)) {
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
          bool isSettlement = islem.aciklama.toLowerCase().contains('hakediş tahsilatı') ||
                             islem.aciklama.toLowerCase().contains('maaş ödemesi') ||
                             islem.aciklama.toLowerCase().contains('avans') ||
                             islem.aciklama.toLowerCase().contains('işçi ödemesi') ||
                             islem.aciklama.contains('#H:[') ||
                             islem.aciklama == 'Hesap Kapatma';

          if (!isSettlement) {
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
        'total_earned': toplamIscilikHakedis,
        'total_paid': toplamIscilikOdeme,
        'net_debt': toplamIscilikHakedis - toplamIscilikOdeme,
        'items': workerDuesMap.values.toList(),
      },
      'invoices': {
        'sales': toplamSatis,
        'purchases': toplamAlis,
        'sales_vat': satisKdv,
        'purchase_vat': alisKdv,
        'vat_balance': satisKdv - alisKdv,
        'items': invoiceBalances.values.toList(),
      },
      'financials': {
        'extra_income': extraGelir + manuallyEnteredGelir,
        'extra_expense': extraGider + manuallyEnteredGider,
        'total_revenue': toplamSatis + extraGelir + manuallyEnteredGelir + toplamHakedisNetValue,
        'total_cost': toplamAlis + extraGider + manuallyEnteredGider + toplamIscilikHakedis,
        'net_profit': (toplamSatis + extraGelir + manuallyEnteredGelir + toplamHakedisNetValue) -
                      (toplamAlis + extraGider + manuallyEnteredGider + toplamIscilikHakedis),
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

      await _supabase
          .from('hakedisler')
          .update({'durum': newStatus.name})
          .filter('project_id', 'in', projectIds)
          .eq('durum', HakedisDurum.bekliyor.name)
          .eq('user_id', userId)
          .gte('tarih', rangeStart.toIso8601String())
          .lte('tarih', rangeEnd.toIso8601String());
    } catch (e) {
      print('DEBUG: bulkUpdateHakedisStatusByProject hatası: $e');
      rethrow;
    }
  }
}

