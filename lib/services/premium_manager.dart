import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ad_helper.dart';

class PremiumManager {
  static final PremiumManager instance = PremiumManager._();
  PremiumManager._();

  bool _isPremium = false;
  bool get isPremium => _isPremium;
  
  DateTime? _lastAdShownTime;
  Timer? _adIntervalTimer;
  static const int adIntervalMinutes = 10;

  Future<void> init() async {
    // Auth durum değişikliklerini dinle
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        checkSubscriptionStatus();
      }
    });

    await checkSubscriptionStatus();
    
    /* // Geliştirme aşamasında (Debug mode) reklamları devre dışı bırakıyoruz
    if (kDebugMode) {
      // debugPrint('Debug modunda reklamlar devre dışı bırakıldı.');
      return;
    } */

    // Reklamlar sadece Android ve iOS'ta çalışır
    if (!_isPremium && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await MobileAds.instance.initialize();
        // Uygulama açılışında ilk reklamı göster
        _showInitialAdWithDelay();
        // 10 dakikalık döngüyü başlat
        _startAdTimer();
      } catch (e) {
        // debugPrint('MobileAds initialization error: $e');
      }
    }
  }

  void _showInitialAdWithDelay() {
    // Uygulama tam açılmadan reklam göstermek bazen sorun çıkarabilir, 2 sn gecikme ekliyoruz
    Future.delayed(const Duration(seconds: 2), () {
      showTimedAd();
    });
  }

  void _startAdTimer() {
    _adIntervalTimer?.cancel();
    _adIntervalTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isPremium) {
        timer.cancel();
        return;
      }

      if (_lastAdShownTime != null) {
        final difference = DateTime.now().difference(_lastAdShownTime!).inMinutes;
        if (difference >= adIntervalMinutes) {
          showTimedAd();
        }
      }
    });
  }

  Future<void> showTimedAd() async {
    if (_isPremium || !(Platform.isAndroid || Platform.isIOS)) return;

    await AdHelper.showInterstitialAd(
      onAdDismissed: () {
        _lastAdShownTime = DateTime.now();
      },
    );
  }

  Future<void> checkSubscriptionStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _isPremium = false;
      return;
    }

    try {
      // Önce mevcut durumu sıfırla ki hesaptan çıkış yapılıp girilmişse eski veri kalmasın
      _isPremium = false;
      
      // Supabase'den user_subscriptions tablosundaki veriyi çek
      final response = await Supabase.instance.client
          .from('user_subscriptions')
          .select('is_premium, expires_at')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        // Eğer expires_at (bitiş tarihi) bugünden ileriyse Premium kalsın
        DateTime? expiresAt;
        if (response['expires_at'] != null) {
          expiresAt = DateTime.parse(response['expires_at'].toString());
        }

        if (response['is_premium'] == true) {
           if (expiresAt == null || expiresAt.isAfter(DateTime.now())) {
             _isPremium = true;
             return;
           }
        }
      }
      
      _isPremium = false; 
    } catch (e) {
      debugPrint('Abonelik kontrolü hatası: $e');
      _isPremium = false;
    }
  }

  Future<void> setPremium(bool status) async {
    _isPremium = status;
    if (status) {
      _adIntervalTimer?.cancel();
    }
    
    // Supabase tarafında da (opsiyonel) güncelleme yapılabilir
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && status) {
       try {
         await Supabase.instance.client
            .from('user_subscriptions')
            .upsert({
              'user_id': user.id,
              'is_premium': true,
              'expires_at': DateTime.now().add(const Duration(days: 365)).toIso8601String(), // Örnek olarak 1 yıl
            });
       } catch (e) {
         debugPrint('Premium status sync error: $e');
       }
    }
  }

  bool checkPremium(BuildContext context) {
    if (_isPremium) return true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.stars_rounded, color: Color(0xFF2EC4B6)),
            SizedBox(width: 8),
            Text('Premium Özellik'),
          ],
        ),
        content: const Text(
          'Bu özellik sadece Muhasebe Pro Premium üyelerine özeldir. Hemen yükseltin ve tüm kısıtlamaları kaldırın!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2EC4B6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Paketleri Gör'),
          ),
        ],
      ),
    );
    return false;
  }
}
