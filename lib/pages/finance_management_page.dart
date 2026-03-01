import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../widgets/banner_ad_widget.dart';

class FinanceManagementPage extends StatefulWidget {
  const FinanceManagementPage({super.key});

  @override
  State<FinanceManagementPage> createState() => _FinanceManagementPageState();
}

class _FinanceManagementPageState extends State<FinanceManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  String _formatPara(double tutar) {
    return NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : r'$',
      decimalDigits: 2,
    ).format(tutar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.financeKasaManagement),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.bankKasa),
            Tab(text: AppLocalizations.of(context)!.cekSenet),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBankTab(),
          _buildCheckTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_card_rounded),
        label: Text(_tabController.index == 0 ? AppLocalizations.of(context)!.cashMovement : AppLocalizations.of(context)!.documentEntry),
        backgroundColor: const Color(0xFF003399),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildBankTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildFinanceCard(AppLocalizations.of(context)!.mainVault, 125400.00, Colors.green),
        const SizedBox(height: 16),
        _buildFinanceCard('Ziraat Bankası', 450000.00, Colors.blue),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.recentTransactions, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 16),
        _buildMovementItem('Hakediş Tahsilatı', 'Akasya Projesi', 85000.0, true),
        _buildMovementItem('Mazot Gideri', 'Şantiye Petrol', -4500.0, false),
        _buildMovementItem('Maaş Ödemesi', 'Personel Ödemeleri', -12500.0, false),
      ],
    );
  }

  Widget _buildCheckTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(AppLocalizations.of(context)!.pendingCollections, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 16),
        _buildCheckItem('Müşteri Çeki', 'Özkul İnşaat', 150000.0, '25.04.2026', Colors.orange),
        _buildCheckItem('Portföy Çeki', 'Alfa Yapı', 75000.0, '12.05.2026', Colors.blue),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.checksGiven, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 16),
        _buildCheckItem('Firma Çeki', 'Beton A.Ş', 45000.0, '15.03.2026', Colors.red),
      ],
    );
  }

  Widget _buildFinanceCard(String account, double balance, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_formatPara(balance), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            ],
          ),
          Icon(Icons.account_balance_wallet_rounded, color: color, size: 32),
        ],
      ),
    );
  }

  Widget _buildMovementItem(String title, String subtitle, double amount, bool isIncome) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
            child: Icon(isIncome ? Icons.south_east_rounded : Icons.north_east_rounded, color: isIncome ? Colors.green : Colors.red, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Text(_formatPara(amount), style: TextStyle(fontWeight: FontWeight.w900, color: isIncome ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String type, String company, double amount, String date, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.document_scanner_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(company, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(type, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatPara(amount), style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(date, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
