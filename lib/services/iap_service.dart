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
  
  // UI'ın dinleyebileceği bir ValueNotifier ekleyelim
  final ValueNotifier<PurchaseStatus?> purchaseStatusNotifier = ValueNotifier<PurchaseStatus?>(null);
  String? lastErrorMessage;

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
        purchaseStatusNotifier.value = PurchaseStatus.error;
        lastErrorMessage = error.toString();
      },
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (_iap == null) return;
    try {
      isAvailable = await _iap!.isAvailable();
      if (!isAvailable) return;

      final ProductDetailsResponse response = await _iap!.queryProductDetails(_kIds);
      if (response.error == null) {
        products = response.productDetails;
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      purchaseStatusNotifier.value = purchase.status;

      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('Purchase Pending...');
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase Error: ${purchase.error}');
        lastErrorMessage = purchase.error?.message;
      } else if (purchase.status == PurchaseStatus.purchased || 
                 purchase.status == PurchaseStatus.restored) {
        // Satın alma başarılı veya geri yüklendi
        if (products.isEmpty) {
          debugPrint('Product list is empty, querying again...');
          await _loadProducts();
        }
        
        // Güvenli ürün bulma (Android'de tip uyuşmazlığını önlemek için loop kullanıyoruz)
        ProductDetails? product;
        for (final p in products) {
          if (p.id == purchase.productID) {
            product = p;
            break;
          }
        }
        
        // Eğer ürün bulunamazsa ama liste boş değilse ilkini al (Fallback)
        product ??= products.isNotEmpty ? products.first : null;
        
        if (product == null) {
          throw Exception('Product details not available for ${purchase.productID}');
        }
        
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
