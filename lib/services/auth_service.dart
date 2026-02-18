import 'package:supabase_flutter/supabase_flutter.dart';

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
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutter://reset-password',
    );
  }

  // Şifre güncelle
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
