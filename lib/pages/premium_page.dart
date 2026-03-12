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
    // Ürünlerin yüklendiğinden emin olmak için kısa bir süre sonra listeyi yenileyebiliriz
    if (IAPService.instance.products.isEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
         if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.premiumPackages),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Color(0xFF2EC4B6)),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.premiumSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.premiumDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildFeatureRow(context, Icons.block_flipped, AppLocalizations.of(context)!.featureRemoveAds),
            _buildFeatureRow(context, Icons.picture_as_pdf, AppLocalizations.of(context)!.featureUnlimitedPDF),
            _buildFeatureRow(context, Icons.cloud_done, AppLocalizations.of(context)!.featureCloudBackup),
            _buildFeatureRow(context, Icons.business, AppLocalizations.of(context)!.featureB2B),
            ValueListenableBuilder<bool>(
              valueListenable: PremiumManager.instance.premiumStatusNotifier,
              builder: (context, isPremium, child) {
                if (isPremium) {
                  return Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EC4B6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF2EC4B6), width: 2),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF2EC4B6), size: 64),
                        const SizedBox(height: 16),
                        Text(
                          "Tebrikler!",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF011627)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Aktif bir Premium üyeliğiniz bulunuyor. Tüm özelliklerin keyfini çıkarın!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Color(0xFF011627)),
                        ),
                        if (PremiumManager.instance.expiryDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              "Bitiş: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(PremiumManager.instance.expiryDate!)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2EC4B6)),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    // Reklam İzle - 10 Dk Premium
                    _buildRewardedAdCard(),
                    
                    const SizedBox(height: 30),
                    if (IAPService.instance.products.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else
                      ...IAPService.instance.products.map((product) {
                        final isYearly = product.id.contains('yearly');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSubscriptionCard(
                            context,
                            product: product,
                            title: isYearly 
                                ? AppLocalizations.of(context)!.yearlyPackage 
                                : AppLocalizations.of(context)!.monthlyPackage,
                            price: product.price,
                            description: isYearly 
                                ? AppLocalizations.of(context)!.save25 
                                : AppLocalizations.of(context)!.cancelAnytime,
                            isPopular: isYearly,
                            onTap: () {
                              setState(() => _selectedProduct = product);
                            },
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _selectedProduct == null ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EC4B6),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.continueButton,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Satın almalar geri yükleniyor...")),
                        );
                        await IAPService.instance.restorePurchases();
                      },
                      child: const Text(
                        "Satın Almaları Geri Yükle",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    if (_selectedProduct != null) {
      IAPService.instance.buyProduct(_selectedProduct!);
      // Not: Satın alma sonucu iap_service içindeki stream listener'dan yönetiliyor.
      // Kullanıcıya işlemin başladığına dair bilgi verebiliriz.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.processingPayment ?? "İşlem başlatıldı...")),
      );
    }
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2EC4B6), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardedAdCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        border: Border.all(color: Colors.orange.shade300, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.ondemand_video_rounded, color: Colors.orange, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Ücretsiz Deneyin",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Kısa bir reklam izleyerek 10 dakika boyunca tüm Premium özelliklere (Reklamsız deneyim dahil) ücretsiz erişim sağlayın.",
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingAd ? null : _showRewardedPremiumAd,
              icon: _isLoadingAd 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.play_circle_filled),
              label: Text(_isLoadingAd ? "Yükleniyor..." : "Reklam İzle - 10dk Aç"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showRewardedPremiumAd() {
     setState(() {
       _isLoadingAd = true;
     });
     
     AdHelper.showRewardedAd(
       onUserEarnedReward: (reward) {
          PremiumManager.instance.startTemporaryPremium();
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Tebrikler! 10 Dakika boyunca Premium özellikleriniz aktif edildi."), backgroundColor: Color(0xFF2EC4B6)),
          );
          Navigator.pop(context);
       },
       onAdDismissed: () {
          setState(() {
             _isLoadingAd = false;
          });
       },
       onAdFailed: () {
          setState(() {
             _isLoadingAd = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Reklam yüklenirken bir sorun oluştu, lütfen daha sonra tekrar deneyin.")),
          );
       }
     );
  }

  Widget _buildSubscriptionCard(
    BuildContext context, {
    required ProductDetails product,
    required String title,
    required String price,
    required String description,
    required VoidCallback onTap,
    bool isPopular = false,
  }) {
    final isSelected = _selectedProduct == product;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2EC4B6).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2EC4B6)
                : (isPopular ? const Color(0xFF2EC4B6).withOpacity(0.5) : Colors.black.withOpacity(0.1)),
            width: isSelected ? 3 : (isPopular ? 2 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF2EC4B6).withOpacity(0.1) : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EC4B6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.mostPopular,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF011627))),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2EC4B6), size: 32),
          ],
        ),
      ),
    );
  }
}
