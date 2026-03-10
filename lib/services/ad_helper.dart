import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'premium_manager.dart';

class AdHelper {
  // Yeni Banner Reklam ID (Android)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1425423650354205/7876029394'; 
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test iOS Banner ID
    } else {
      return '';
    }
  }

  // Yeni Geçiş (Interstitial) Reklam ID (Android)
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1425423650354205/9069691563';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test iOS Interstitial ID
    } else {
      return '';
    }
  }

  // Yeni Ödüllü (Rewarded) Reklam ID (Android)
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1425423650354205/7482692431'; 
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712467307'; // Test iOS Rewarded ID
    } else {
      return '';
    }
  }

  static int _interstitialCounter = 0;
  static const int _interstitialShowRate = 3; 

  // Tüm uygulama boyunca kullanılacak Navigator Observer
  static final RouteObserver<PageRoute<dynamic>> routeObserver = AdRouteObserver();

  static Future<void> showInterstitialAd({VoidCallback? onAdDismissed}) async {
    if (PremiumManager.instance.isPremium || !(Platform.isAndroid || Platform.isIOS)) {
      onAdDismissed?.call();
      return;
    }

    _interstitialCounter++;
    if (_interstitialCounter < _interstitialShowRate) {
      onAdDismissed?.call();
      return;
    }

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
             _interstitialCounter = 0; 
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
            onAdDismissed?.call();
          },
        ),
      );
    } catch (e) {
      onAdDismissed?.call();
    }
  }

  static Future<void> showRewardedAd({required Function(RewardItem) onUserEarnedReward, VoidCallback? onAdDismissed, VoidCallback? onAdFailed}) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      onAdFailed?.call();
      return;
    }

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                onAdDismissed?.call();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                onAdFailed?.call();
              },
            );
            ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
              onUserEarnedReward(rewardItem);
            });
          },
          onAdFailedToLoad: (error) {
            onAdFailed?.call();
          },
        ),
      );
    } catch (e) {
       onAdFailed?.call();
    }
  }
}

class AdRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute && previousRoute is PageRoute) {
       AdHelper.showInterstitialAd();
    }
  }
}
