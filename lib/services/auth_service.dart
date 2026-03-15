import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mevcut kullanıcıyı al
  User? get currentUser => _supabase.auth.currentUser;

  // Giriş yapmış mı kontrol et
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  // E-posta ve şifre ile kayıt ol
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Giriş yap
  Future<void> signIn(String email, String password) async {
    debugPrint('DEBUG: Giriş denemesi yapılıyor: $email');
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userResponse = await _supabase.auth.getUser();
    final user = userResponse.user;
    
    if (user != null) {
      final metadata = user.userMetadata ?? {};
      debugPrint('DEBUG: Giriş yapan kullanıcı metadatası: $metadata');
      
      bool isDeleted = metadata['account_deleted'] == true || 
                       metadata['account_deleted'].toString().toLowerCase() == 'true';
      
      // IKINCI KONTROL: Metadata güncellenmemiş olabilir (loglarda hata vardı)
      // SQL tablosuna bakalım
      if (!isDeleted) {
        debugPrint('DEBUG: Metadata temiz, SQL tablosu kontrol ediliyor...');
        try {
          final sqlCheck = await _supabase
              .from('user_deletion_requests')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle()
              .timeout(const Duration(seconds: 3));
          
          if (sqlCheck != null) {
            debugPrint('DEBUG: SQL tablosunda silme talebi bulundu! Giriş engelleniyor.');
            isDeleted = true;
          }
        } catch (e) {
          debugPrint('DEBUG: SQL kontrolü yapılamadı (Normal olabilir): $e');
        }
      }

      if (isDeleted) {
        debugPrint('DEBUG: SONUÇ - HESAP SİLİNMİŞ! Çıkış yapılıyor.');
        await signOut();
        throw Exception('ACCOUNT_DELETED_ERROR');
      }
      debugPrint('DEBUG: Giriş başarılı, hesap aktif.');
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> resetPassword(String email) async {
    // Hem Telefon (Mobil) hem de Masaüstü (Windows) için aynı global protokol kullanılır.
    // Windows tarafında bu protokol ProtocolService ile otomatik olarak kaydedilir.
    final String redirectTo = kIsWeb 
        ? Uri.base.origin 
        : 'io.supabase.flutter://reset-password';

    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  // Şifre güncelle
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Hesabı sil (Veri silme talebi ve çıkış)
  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('DEBUG: Silinecek kullanıcı bulunamadı (Session yok).');
      return;
    }

    try {
      debugPrint('DEBUG: SİLME BAŞLADI - User ID: ${user.id}');

      // 1. Önce sunucuda işaretleme yap (En hızlı ve en garanti kanıt)
      // Bu adım başarısız olursa diğerleri de anlamsızlaşır.
      try {
        debugPrint('DEBUG: Sunucu metadatası güncelleniyor...');
        await _supabase.auth.updateUser(
          UserAttributes(data: {
            'account_deleted': true, 
            'deletion_request_date': DateTime.now().toIso8601String(),
            'status': 'pending_deletion'
          }),
        ).timeout(const Duration(seconds: 4));
        debugPrint('DEBUG: Sunucu metadatası BAŞARIYLA güncellendi.');
      } catch (e) {
        debugPrint('DEBUG: Sunucu metadatası güncellenemedi! Hata: $e');
        // Devam edelim, belki SQL tablosu veya yerel silme işe yarar.
      }

      // 2. SQL Tablosuna kayıt (Admin için) - Await ederek garantiye alalım
      try {
        debugPrint('DEBUG: SQL Kaydı yapılıyor...');
        await _supabase.from('user_deletion_requests').insert({
          'user_id': user.id,
          'email': user.email,
          'requested_at': DateTime.now().toIso8601String(),
          'status': 'pending'
        }).timeout(const Duration(seconds: 4));
        debugPrint('DEBUG: SQL Kaydı başarılı.');
      } catch (e) {
        debugPrint('DEBUG: SQL Kaydı başarısız (Tablo olmayabilir): $e');
      }

      // 3. Yerel verileri temizle
      debugPrint('DEBUG: Yerel veriler (Hive) temizleniyor...');
      await DatabaseHelper.instance.clearAllData();
      debugPrint('DEBUG: Yerel veri temizliği bitti.');

      debugPrint('DEBUG: Tüm silme hazırlıkları tamamlandı.');
    } catch (e) {
      debugPrint('DEBUG: deleteAccount içinde beklenmedik hata: $e');
    }
  }
}
