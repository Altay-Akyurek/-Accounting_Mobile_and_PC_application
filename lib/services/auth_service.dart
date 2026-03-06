import 'package:flutter/foundation.dart' show kIsWeb;
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

  // E-posta ve şifre ile giriş yap
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
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
    if (user != null) {
      try {
        // 1. Supabase metadata güncellemesi (Google Play silme talebi için yeterlidir)
        await _supabase.auth.updateUser(
          UserAttributes(data: {
            'account_deleted': true, 
            'deletion_request_date': DateTime.now().toIso8601String(),
            'status': 'pending_deletion'
          }),
        );

        // 2. Yerel verileri temizle (Hive)
        await DatabaseHelper.instance.clearAllData();

        // NOT: Çıkış işlemini UI tarafında loader'ı kapattıktan sonra yapacağız.
      } catch (e) {
        print('Hesap silme hatası: $e');
        rethrow;
      }
    }
  }
}
