import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // TEST ID'leri (Gerçek ID'ler gelene kadar bunları kullanacağız)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1425423650354205/7876029394'; // Üretim Banner ID (Android)
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test iOS Banner ID
    } else {
      return ''; // Desteklenmeyen platformlarda boş döndür
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1425423650354205/9969691563'; // Üretim Interstitial ID (Android)
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test iOS Interstitial ID
    } else {
      return '';
    }
  }

  static Future<void> showInterstitialAd({VoidCallback? onAdDismissed}) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      onAdDismissed?.call();
      return;
    }

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                onAdDismissed?.call();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                onAdDismissed?.call();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (error) {
            debugPrint('InterstitialAd failed to load: $error');
            onAdDismissed?.call();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error showing InterstitialAd: $e');
      onAdDismissed?.call();
    }
  }
}
