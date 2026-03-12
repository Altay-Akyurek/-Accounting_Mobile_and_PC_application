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
        // Bekleyen işlem - UI'da bir loading gösterilebilir
        debugPrint('Purchase Pending...');
      } else if (purchase.status == PurchaseStatus.error) {
        // Hata
        debugPrint('Purchase Error: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.purchased || 
                 purchase.status == PurchaseStatus.restored) {
        // Satın alma başarılı veya geri yüklendi
        // İlgili productDetails'ı bulalım
        final product = products.firstWhere(
          (p) => p.id == purchase.productID,
          orElse: () => products.first, // Fallback (riskli ama genelde liste doludur)
        );
        _verifyPurchase(purchase, product);
      }
      
      if (purchase.pendingCompletePurchase) {
        _iap?.completePurchase(purchase);
      }
    }
  }

  void _verifyPurchase(PurchaseDetails purchase, ProductDetails product) {
    // Sunucu tarafı senkronizasyonu için ürün bilgisini de gönderiyoruz
    PremiumManager.instance.setPremiumFromIAP(product.id);
  }

  void buyProduct(ProductDetails product) {
    if (_iap == null) return;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _iap!.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (_iap == null) return;
    await _iap!.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
