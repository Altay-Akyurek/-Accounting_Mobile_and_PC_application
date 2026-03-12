import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'Bilinmeyen bir hata oluştu.';

    // 1. Ağ Bağlantı Hataları (Network & Connection)
    if (error is SocketException) {
      return 'Network Error – İnternet bağlantısı bulunamadı';
    }

    if (error is TimeoutException) {
      return 'Timeout Error – Bağlantı zaman aşımına uğradı';
    }

    // 2. Supabase / Veritabanı Hataları
    if (error is PostgrestException) {
      if (error.code == 'PGRST301' || error.code == 'PGRST116') {
        return 'Data Save Error – Veri kaydedilemedi veya bulunamadı';
      }
      return 'Server Error – Sunucu hatası oluştu';
    }

    if (error is AuthException) {
      return 'Server Error – Yetkilendirme hatası (Oturum süresi dolmuş olabilir)';
    }

    // 3. String Mesaj Kontrolleri (Throw Exception('') vb.)
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') || 
        errorString.contains('failed host lookup') || 
        errorString.contains('internet')) {
      return 'Network Error – İnternet bağlantısı bulunamadı';
    }

    if (errorString.contains('timeout')) {
      return 'Timeout Error – Bağlantı zaman aşımına uğradı';
    }

    if (errorString.contains('connection refused') || 
        errorString.contains('server error') || 
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return 'Connection Error – Sunucuya bağlanılamadı';
    }

    if (errorString.contains('postgrest') || 
        errorString.contains('database') || 
        errorString.contains('insert') || 
        errorString.contains('update') || 
        errorString.contains('delete')) {
      return 'Data Save Error – Veri kaydedilemedi';
    }

    // VarsayılanFallback Mesaj (Yine de formatlayıp gösterelim)
    // Eğer bilmediğimiz ham bir metinse sadece onu formatlıyoruz.
    if (error is Exception) {
      final msg = error.toString().replaceFirst('Exception: ', '');
      if (msg.isNotEmpty) {
          return 'Sistem Hatası – $msg';
      }
    }

    return 'Bilinmeyen Hata – Şimdilik işleme devam edilemiyor: $error';
  }
}
