import 'dart:io';
import 'package:flutter/foundation.dart';

class ProtocolService {
  static const String protocolName = 'io.supabase.flutter';

  /// Windows üzerinde uygulamayı protokol için kaydeder.
  static Future<void> register() async {
    if (kIsWeb || !Platform.isWindows) return;

    try {
      final String exePath = Platform.resolvedExecutable;
      
      // HKEY_CURRENT_USER kullanarak yönetici izni gerekmeden kayıt yapalım
      final String rootKey = 'HKCU\\Software\\Classes\\$protocolName';
      
      // 1. Protokol anahtarını oluştur
      await _runRegCommand(['add', rootKey, '/ve', '/d', 'URL:Muhasebe Pro Protocol', '/f']);
      await _runRegCommand(['add', rootKey, '/v', 'URL Protocol', '/d', '', '/f']);
      
      // 2. Açma komutunu (exe yolunu) kaydet
      await _runRegCommand([
        'add', 
        '$rootKey\\shell\\open\\command', 
        '/ve', 
        '/d', 
        '"$exePath" "%1"', 
        '/f'
      ]);
      
      // debugPrint('Deep Link Kaydı Başarılı (HKCU): $exePath');
    } catch (e) {
      // debugPrint('Deep Link Kaydı Başarısız: $e');
    }
  }

  static Future<void> _runRegCommand(List<String> args) async {
    // Komutu doğrudan reg içinden çalıştıralım, cmd /c bazen karmaşa yaratabiliyor
    final result = await Process.run('reg', args);
    if (result.exitCode != 0) {
      throw Exception('Registry hatası (${result.exitCode}): ${result.stderr}');
    }
  }
}
