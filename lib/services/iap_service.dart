import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'premium_manager.dart';

class IAPService {
  static final IAPService instance = IAPService._();
  IAPService._();

  InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Google Play Console'da oluşturulacak ürün ID'leri
  static const String _monthlyId = 'premium_monthly';
  static const String _yearlyId = 'premium_yearly';
  static const Set<String> _kIds = {_monthlyId, _yearlyId};

  List<ProductDetails> products = [];
  bool isAvailable = false;

  void init() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('IAP is not supported on this platform.');
      return;
    }

    _iap = InAppPurchase.instance;
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap!.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('IAP Error: $error');
      },
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (_iap == null) return;
    isAvailable = await _iap!.isAvailable();
    if (!isAvailable) return;

    final ProductDetailsResponse response = await _iap!.queryProductDetails(_kIds);
    if (response.error == null) {
      products = response.productDetails;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Bekleyen işlem
      } else if (purchase.status == PurchaseStatus.error) {
        // Hata
      } else if (purchase.status == PurchaseStatus.purchased || 
                 purchase.status == PurchaseStatus.restored) {
        // Satın alma başarılı veya geri yüklendi
        _verifyPurchase(purchase);
      }
      
      if (purchase.pendingCompletePurchase) {
        _iap?.completePurchase(purchase);
      }
    }
  }

  void _verifyPurchase(PurchaseDetails purchase) {
    // Burada sunucu tarafı doğrulaması (Supabase verify) yapılabilir
    // Şimdilik lokalde premium durumunu aktif ediyoruz
    PremiumManager.instance.setPremium(true);
  }

  void buyProduct(ProductDetails product) {
    if (_iap == null) return;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _iap!.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
