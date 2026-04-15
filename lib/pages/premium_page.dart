import 'package:flutter/material.dart';
import '../services/premium_manager.dart';
import '../l10n/app_localizations.dart';
import '../services/iap_service.dart';
import '../services/ad_helper.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  ProductDetails? _selectedProduct;
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    // Pre-select yearly if available
    _initializeSelection();
    
    // Purchase Status Listener
    IAPService.instance.purchaseStatusNotifier.addListener(_onPurchaseStatusChanged);
  }

  @override
  void dispose() {
    IAPService.instance.purchaseStatusNotifier.removeListener(_onPurchaseStatusChanged);
    super.dispose();
  }

  void _onPurchaseStatusChanged() {
    final status = IAPService.instance.purchaseStatusNotifier.value;
    if (!mounted) return;

    if (status == PurchaseStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: ${IAPService.instance.lastErrorMessage ?? 'Bilinmeyen bir hata oluştu'}"),
          backgroundColor: Colors.red,
        ),
      );
    } else if (status == PurchaseStatus.purchased || status == PurchaseStatus.restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tebrikler! Premium üyeliğiniz aktif edildi."),
          backgroundColor: Color(0xFF2EC4B6),
        ),
      );
    }
  }

  void _initializeSelection() {

    final products = IAPService.instance.products;
    if (products.isNotEmpty) {
      ProductDetails? yearly;
      for (final p in products) {
        if (p.id.contains('yearly')) {
          yearly = p;
          break;
        }
      }
      _selectedProduct = yearly ?? products.first;
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && IAPService.instance.products.isNotEmpty) {
          setState(() {
            final products = IAPService.instance.products;
            ProductDetails? yearly;
            for (final p in products) {
              if (p.id.contains('yearly')) {
                yearly = p;
                break;
              }
            }
            _selectedProduct = yearly ?? products.first;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(l10n),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      _buildHeaderInfo(l10n),
                      const SizedBox(height: 40),
                      _buildFeaturesList(l10n),
                      const SizedBox(height: 48),
                      ValueListenableBuilder<bool>(
                        valueListenable: PremiumManager.instance.premiumStatusNotifier,
                        builder: (context, isPremium, child) {
                          if (isPremium) return _buildAlreadyPremiumCard(l10n);
                          return _buildPurchaseSection(l10n);
                        },
                      ),
                      const SizedBox(height: 40),
                      _buildRestoreButton(l10n),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<PurchaseStatus?>(
            valueListenable: IAPService.instance.purchaseStatusNotifier,
            builder: (context, status, child) {
              if (status == PurchaseStatus.pending) {
                return Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          l10n.processingPayment,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );

  }

  Widget _buildSliverAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF011627),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF011627), Color(0xFF2EC4B6)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Icon(Icons.stars_rounded, size: 250, color: Colors.white.withOpacity(0.05)),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.premiumSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF011627), letterSpacing: -1),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.premiumDescription,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.premiumFeatures.toUpperCase(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2EC4B6), letterSpacing: 1.5),
        ),
        const SizedBox(height: 24),
        _buildFeatureItem(l10n.featureRemoveAds, Icons.block_rounded),
        _buildFeatureItem(l10n.featureUnlimitedPDF, Icons.picture_as_pdf_rounded),
        _buildFeatureItem(l10n.featureCloudBackup, Icons.cloud_done_rounded),
        _buildFeatureItem(l10n.featureB2B, Icons.business_center_rounded),
        _buildFeatureItem(l10n.premiumBenefitPerformance, Icons.analytics_rounded),
      ],

    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2EC4B6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2EC4B6), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF011627)),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2EC4B6), size: 20),
        ],
      ),
    );
  }

  Widget _buildPurchaseSection(AppLocalizations l10n) {
    if (IAPService.instance.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              const CircularProgressIndicator(color: Color(0xFF2EC4B6)),
              const SizedBox(height: 24),
              Text(
                "Paketler yükleniyor veya mağaza ile bağlantı kuruluyor...",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {}); // UI yenilemeyi tetikle
                },
                child: const Text("Yenilemeyi Dene"),
              ),
            ],
          ),
        ),
      );
    }

    try {

    return Column(
      children: [
        ...IAPService.instance.products.map((product) {
          final isYearly = product.id.contains('yearly');
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSubscriptionCard(
              l10n,
              product: product,
              title: isYearly ? l10n.yearlyPackage : l10n.monthlyPackage,
              price: product.price,
              description: isYearly ? l10n.save25 : l10n.cancelAnytime,
              isPopular: isYearly,
            ),
          );
        }).toList(),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _selectedProduct == null ? null : _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF011627),
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: const Color(0xFF011627).withOpacity(0.4),
          ),
          child: Text(
            l10n.continueButton,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 24),
        _buildRewardedAdCard(l10n),
      ],
    );
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Ürünler listelenirken bir hata oluştu.",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSubscriptionCard(
    AppLocalizations l10n, {
    required ProductDetails product,
    required String title,
    required String price,
    required String description,
    bool isPopular = false,
  }) {
    final isSelected = _selectedProduct == product;

    return GestureDetector(
      onTap: () => setState(() => _selectedProduct = product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF011627).withOpacity(0.02) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF2EC4B6) : Colors.grey.shade200,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF2EC4B6).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EC4B6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.mostPopular,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF011627))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2EC4B6) : Colors.grey.shade300,
                  width: isSelected ? 10 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyPremiumCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2EC4B6).withOpacity(0.1), const Color(0xFF2EC4B6).withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF2EC4B6).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF2EC4B6), size: 80),
          const SizedBox(height: 24),
          Text(
            l10n.congratulations,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF011627)),
          ),
          const SizedBox(height: 12),
          const Text(
            "Aktif bir Premium üyeliğiniz bulunuyor. Tüm özelliklerin keyfini çıkarın!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF011627), height: 1.5),
          ),
          if (PremiumManager.instance.expiryDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF011627),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  PremiumManager.instance.expiryDate != null 
                    ? "Bitiş: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(PremiumManager.instance.expiryDate!)}"
                    : "Premium Üyelik Aktif",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRewardedAdCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: Colors.orange, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.tryFreeTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(l10n.tryFreeDescription, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _isLoadingAd ? null : _showRewardedPremiumAd,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Colors.orange, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoadingAd 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
              : Text(l10n.watchAdButton, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(AppLocalizations l10n) {
    return TextButton(
      onPressed: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Satın almalar geri yükleniyor...")),
        );
        await IAPService.instance.restorePurchases();
      },
      child: Text(
        l10n.restorePurchases,
        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
      ),
    );
  }

  void _handleContinue() {
    if (_selectedProduct != null) {
      IAPService.instance.buyProduct(_selectedProduct!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.processingPayment)),
      );
    }
  }

  void _showRewardedPremiumAd() {
    setState(() => _isLoadingAd = true);
    AdHelper.showRewardedAd(
      onUserEarnedReward: (reward) {
        PremiumManager.instance.startTemporaryPremium();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Premium özellikler aktif edildi!"), backgroundColor: Color(0xFF2EC4B6)),
        );
        Navigator.pop(context);
      },
      onAdDismissed: () => setState(() => _isLoadingAd = false),
      onAdFailed: () {
        setState(() => _isLoadingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reklam yüklenemedi. Lütfen tekrar deneyin.")),
        );
      },
    );
  }
}
