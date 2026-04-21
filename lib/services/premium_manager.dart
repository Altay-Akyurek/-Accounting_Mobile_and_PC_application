import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_helper.dart';

class PremiumManager {
  PremiumManager._privateConstructor();
  static final PremiumManager instance = PremiumManager._privateConstructor();

  bool _isPremium = false;
  
   // UI değişiklikleri için bildirim mekanizması
  final ValueNotifier<bool> premiumStatusNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> syncErrorNotifier = ValueNotifier<String?>(null);
  DateTime? _expiryDate;
  DateTime? get expiryDate => _expiryDate;

  // Reklam tetikleyicisi için timer
  Timer? _adIntervalTimer;
  
  // Geçici premium için anahtar ve timer
  static const String _tempPremiumKey = 'rewarded_premium_expiry';
  Timer? _tempPremiumTimer;

  bool get isPremium => _isPremium;
  
  DateTime? _lastAdShownTime;
  static const int adIntervalMinutes = 10;

  Future<void> init() async {
    // Auth durum değişikliklerini dinle
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        checkSubscriptionStatus();
      }
    });

    // Önce kalıcı abonelik durumunu kontrol et
    await checkSubscriptionStatus();
    // Sonra geçici premium (ödüllü reklam) kontrolü yap
    await _checkTemporaryPremium();

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

  Future<void> _checkTemporaryPremium() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_tempPremiumKey);

    if (expiryString != null) {
       final expiryDate = DateTime.tryParse(expiryString);
       if (expiryDate != null && DateTime.now().isBefore(expiryDate)) {
         _isPremium = true;
         _expiryDate = expiryDate;
         premiumStatusNotifier.value = true;
         
         final durationLeft = expiryDate.difference(DateTime.now());
         _tempPremiumTimer?.cancel();
         _tempPremiumTimer = Timer(durationLeft, () {
            _revokeTemporaryPremium();
         });
       } else {
         prefs.remove(_tempPremiumKey);
       }
    }
  }

  void startTemporaryPremium() async {
     final prefs = await SharedPreferences.getInstance();
     final expiryDate = DateTime.now().add(const Duration(minutes: 10));
     await prefs.setString(_tempPremiumKey, expiryDate.toIso8601String());

     setPremium(true);
     
     _tempPremiumTimer?.cancel();
     _tempPremiumTimer = Timer(const Duration(minutes: 10), () {
       _revokeTemporaryPremium();
     });
  }

  Future<void> _revokeTemporaryPremium() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tempPremiumKey);
      
      await checkSubscriptionStatus(); // Bu _isPremium değerini güncelleyecek
      if (!_isPremium) {
         setPremium(false);
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
             _expiryDate = expiresAt;
             premiumStatusNotifier.value = true;
             _adIntervalTimer?.cancel();
             return;
           }
        }
      }
      
      _isPremium = false; 
      premiumStatusNotifier.value = false;
      _startAdTimer();
    } catch (e) {
      debugPrint('Abonelik kontrolü hatası: $e');
      _isPremium = false;
      premiumStatusNotifier.value = false;
      _startAdTimer();
    }
  }

  // Sadece lokal durumu günceller (Reklam izleme vs için)
  Future<void> setPremium(bool status) async {
    _isPremium = status;
    premiumStatusNotifier.value = status;
    
    if (status) {
      _adIntervalTimer?.cancel();
    } else {
      _startAdTimer();
    }
  }

  Future<void> setPremiumFromIAP(String productId) async {
    await setPremium(true);
    syncErrorNotifier.value = null;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final now = DateTime.now();
      DateTime expiry;
      if (productId == 'premium_monthly') {
        expiry = now.add(const Duration(days: 31));
      } else {
        expiry = now.add(const Duration(days: 366));
      }
      _expiryDate = expiry;

      try {
        await Supabase.instance.client
            .from('user_subscriptions')
            .upsert(
              {
                'user_id': user.id,
                'is_premium': true,
                'expires_at': expiry.toIso8601String(),
                'plan_type': productId,
              },
              onConflict: 'user_id', // Kullanıcı ID'si çakışırsa güncelle
            );
        debugPrint('Premium status synced successfully to Supabase');
      } catch (e) {
        final errorMsg = 'Premium senkronizasyon hatası: $e';
        debugPrint(errorMsg);
        syncErrorNotifier.value = errorMsg;
      }
    } else {
      syncErrorNotifier.value = "Kullanıcı girişi yapılmadığı için veritabanı senkronize edilemedi.";
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
