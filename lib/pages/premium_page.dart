import 'package:flutter/material.dart';
import '../services/premium_manager.dart';
import '../l10n/app_localizations.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  String? _selectedPackage;

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
            const SizedBox(height: 40),
            _buildSubscriptionCard(
              context,
              id: 'monthly',
              title: AppLocalizations.of(context)!.monthlyPackage,
              price: AppLocalizations.of(context)!.monthlyPrice,
              description: AppLocalizations.of(context)!.cancelAnytime,
              onTap: () {
                setState(() => _selectedPackage = 'monthly');
              },
            ),
            const SizedBox(height: 16),
            _buildSubscriptionCard(
              context,
              id: 'yearly',
              title: AppLocalizations.of(context)!.yearlyPackage,
              price: AppLocalizations.of(context)!.yearlyPrice,
              description: AppLocalizations.of(context)!.save25,
              isPopular: true,
              onTap: () {
                setState(() => _selectedPackage = 'yearly');
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _selectedPackage == null ? null : _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2EC4B6),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                AppLocalizations.of(context)!.continueButton,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    // Simüle edilmiş satın alma işlemi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2EC4B6)),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.congratulations),
          ],
        ),
        content: Text(
          _selectedPackage == 'monthly' 
            ? AppLocalizations.of(context)!.premiumActivatedMonthly 
            : AppLocalizations.of(context)!.premiumActivatedYearly,
        ),
        actions: [
          TextButton(
            onPressed: () {
              PremiumManager.instance.setPremium(true);
              Navigator.pop(context); // Dialogu kapat
              Navigator.pop(context); // Premium sayfasından çık
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.premiumSuccessSnackBar),
                  backgroundColor: const Color(0xFF2EC4B6),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.great, style: const TextStyle(color: Color(0xFF2EC4B6), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

  Widget _buildSubscriptionCard(
    BuildContext context, {
    required String id,
    required String title,
    required String price,
    required String description,
    required VoidCallback onTap,
    bool isPopular = false,
  }) {
    final isSelected = _selectedPackage == id;

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
