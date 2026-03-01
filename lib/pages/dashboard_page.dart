import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import '../services/premium_manager.dart';
import '../services/language_service.dart';
import '../models/project.dart';
import '../l10n/app_localizations.dart';
import 'muhasebe_sayfasi.dart';
import 'raporlar_page.dart';
import 'hesap_kesim_rapor_page.dart';
import 'worker_analysis_page.dart';
import 'portfolio_page.dart';
import '../widgets/banner_ad_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, double> _ozetBilgiler = {
    'toplamGelir': 0.0,
    'toplamGider': 0.0,
    'kar': 0.0,
    'toplamCari': 0,
    'toplamFatura': 0,
    'toplamStok': 0,
    'acikProjeler': 0,
  };
  List<Map<String, dynamic>> _topProjeler = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _yukleOzetBilgiler();
  }

  Future<void> _yukleOzetBilgiler() async {
    setState(() => _isLoading = true);
    try {
      final cariHesaplar = await DatabaseHelper.instance.getAllCariHesaplar();
      final faturalar = await DatabaseHelper.instance.getAllFaturalar();
      final gelirGider = await DatabaseHelper.instance
          .getGlobalFinancialSummary();
      final projects = await DatabaseHelper.instance.getAllProjects();
      final activeProjects = projects
          .where((p) => p.durum == ProjectStatus.aktif)
          .toList();
      final projectReports = await DatabaseHelper.instance.getProjectReports();

      // Sort and take top 3 profitable projects
      final sortedProjects = List<Map<String, dynamic>>.from(projectReports)
        ..sort((a, b) => (b['kar'] as double).compareTo(a['kar'] as double));
      final top3 = sortedProjects.take(3).toList();

      setState(() {
        _ozetBilgiler = {
          'toplamGelir': gelirGider['gelir'] ?? 0.0,
          'toplamGider': gelirGider['gider'] ?? 0.0,
          'kar': gelirGider['kar'] ?? 0.0,
          'toplamCari': cariHesaplar.length.toDouble(),
          'toplamFatura': faturalar.length.toDouble(),
          'toplamStok': 0.0,
          'acikProjeler': activeProjects.length.toDouble(),
        };
        _topProjeler = top3;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatPara(double tutar) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.currency(
      locale: locale,
      symbol: locale == 'tr' ? '₺' : '\$',
      decimalDigits: 0,
    ).format(tutar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _yukleOzetBilgiler,
            tooltip: AppLocalizations.of(context)!.current,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFE71D36)),
            onPressed: () => AuthService().signOut(),
            tooltip: AppLocalizations.of(context)!.logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF0F2F5),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF011627),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Color(0xFF2EC4B6),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'MUHASEBE PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.analytics_rounded,
                    label: AppLocalizations.of(context)!.workerAnalysis,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WorkerAnalysisPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.cases_rounded,
                    label: AppLocalizations.of(context)!.ourPortfolio,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PortfolioPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.engineering_rounded,
                    label: AppLocalizations.of(context)!.laborSummary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/labor_summary');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.stars_rounded,
                    label: AppLocalizations.of(context)!.premiumPackages,
                    color: const Color(0xFF2EC4B6),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/premium');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.language_rounded,
                    label: AppLocalizations.of(context)!.language,
                    onTap: () {
                      Navigator.pop(context);
                      _showLanguageDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.privacy_tip_rounded,
                    label: AppLocalizations.of(context)!.privacyPolicy,
                    onTap: () async {
                      Navigator.pop(context);
                      final url = Uri.parse('https://altay-akyurek.github.io/-Accounting_Mobile_and_PC_application/privacy_policy.html');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    label: AppLocalizations.of(context)!.logout,
                    color: const Color(0xFFE71D36),
                    onTap: () {
                      Navigator.pop(context);
                      AuthService().signOut();
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _yukleOzetBilgiler,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopOzet(),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.quickAccess,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF011627),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMainActions(),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.bottleneckAnalysis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF011627),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPremiumCharts(),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.statusAnalysis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF011627),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusGrid(),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.profitableProjects,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF011627),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopProjects(),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.performanceIndicator,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF011627),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPerformanceIndicator(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildPremiumCharts() {
    final isPremium = PremiumManager.instance.isPremium;

    return Stack(
      children: [
        Column(
          children: [
            _buildGelirGiderChart(),
            const SizedBox(height: 16),
            _buildProjeKarlilikChart(),
          ],
        ),
        if (!isPremium)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.white.withOpacity(0.05),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF011627),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF011627).withOpacity(0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.lock_rounded, color: Color(0xFF2EC4B6), size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.premiumAnalysis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Color(0xFF011627),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/premium'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2EC4B6),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(AppLocalizations.of(context)!.unlock),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGelirGiderChart() {
    double gelir = _ozetBilgiler['toplamGelir']!;
    double gider = _ozetBilgiler['toplamGider']!;
    double total = gelir + gider;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: gelir,
                    title: '%${total > 0 ? (gelir / total * 100).toStringAsFixed(0) : 0}',
                    color: const Color(0xFF2EC4B6),
                    radius: 25,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: gider,
                    title: '%${total > 0 ? (gider / total * 100).toStringAsFixed(0) : 0}',
                    color: const Color(0xFFE71D36),
                    radius: 25,
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.incomeAndExpense.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 16),
                _LegendItem(label: AppLocalizations.of(context)!.netIncomes, color: const Color(0xFF2EC4B6)),
                const SizedBox(height: 8),
                _LegendItem(label: AppLocalizations.of(context)!.totalExpenses, color: const Color(0xFFE71D36)),
                const SizedBox(height: 16),
                Text(
                  _formatPara(_ozetBilgiler['kar']!),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF011627)),
                ),
                Text(AppLocalizations.of(context)!.netCashStatus.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjeKarlilikChart() {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            AppLocalizations.of(context)!.top3ProfitableProjects.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _topProjeler.isEmpty ? 100 : _topProjeler.map((e) => e['kar'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < _topProjeler.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _topProjeler[index]['projeAd'].toString().substring(0, 3).toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_topProjeler.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _topProjeler[index]['kar'],
                        color: const Color(0xFF2EC4B6),
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOzet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF011627),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF011627).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.netCash,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EC4B6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)!.current,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatPara(_ozetBilgiler['kar']!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _MiniStat(
                label: AppLocalizations.of(context)!.totalCollection,
                value: _formatPara(_ozetBilgiler['toplamGelir']!),
                color: const Color(0xFF2EC4B6),
              ),
              const SizedBox(width: 24),
              _MiniStat(
                label: AppLocalizations.of(context)!.remainingDebt,
                value: _formatPara(_ozetBilgiler['toplamGider']!),
                color: const Color(0xFFE71D36),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        Row(
          children: [
            _QuickAction(
              icon: Icons.account_balance_wallet_rounded,
              label: AppLocalizations.of(context)!.accounting,
              color: const Color(0xFF011627),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MuhasebeSayfasi()),
                );
                _yukleOzetBilgiler();
              },
            ),
            const SizedBox(width: 16),
            _QuickAction(
              icon: Icons.pie_chart_rounded,
              label: AppLocalizations.of(context)!.reports,
              color: const Color(0xFF011627),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RaporlarPage()),
                );
                _yukleOzetBilgiler();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _QuickAction(
              icon: Icons.engineering_rounded,
              label: AppLocalizations.of(context)!.personnel,
              color: const Color(0xFF011627),
              onTap: () async {
                await Navigator.pushNamed(context, '/labor');
                _yukleOzetBilgiler();
              },
            ),
            const SizedBox(width: 16),
            _QuickAction(
              icon: Icons.auto_graph_rounded,
              label: AppLocalizations.of(context)!.settlement,
              color: const Color(0xFF2EC4B6),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HesapKesimRaporPage()),
                );
                _yukleOzetBilgiler();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      children: [
        _StatusCard(
          baslik: AppLocalizations.of(context)!.openedProjects,
          deger: _ozetBilgiler['acikProjeler']!.toInt().toString(),
          icon: Icons.architecture_rounded,
          onTap: () => Navigator.pushNamed(context, '/projects'),
        ),
        _StatusCard(
          baslik: AppLocalizations.of(context)!.totalCurrentAccounts,
          deger: _ozetBilgiler['toplamCari']!.toInt().toString(),
          icon: Icons.business_rounded,
          onTap: () => Navigator.pushNamed(context, '/cari_liste'),
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicator() {
    double total =
        _ozetBilgiler['toplamGelir']! + _ozetBilgiler['toplamGider']!;
    double profitRatio = total > 0
        ? _ozetBilgiler['toplamGelir']! / total
        : 0.5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.incomeExpenseBalance,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF011627),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                child: Text(
                  '${(profitRatio * 100).toStringAsFixed(1)} ${AppLocalizations.of(context)!.positive}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFF2EC4B6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: profitRatio,
              minHeight: 12,
              backgroundColor: const Color(0xFFE71D36),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2EC4B6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(label: AppLocalizations.of(context)!.incomeShare, color: const Color(0xFF2EC4B6)),
              _LegendItem(label: AppLocalizations.of(context)!.expenseShare, color: const Color(0xFFE71D36)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProjects() {
    if (_topProjeler.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noProfitData,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      children: _topProjeler.map((proj) {
        final isPositive = (proj['kar'] as double) >= 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF011627).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  size: 18,
                  color: Color(0xFF011627),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Text(
                  proj['projeAd'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (proj['durum'] == ProjectStatus.tamamlandi.name
                            ? Colors.green
                            : proj['durum'] == ProjectStatus.aktif.name
                                ? Colors.blue
                                : Colors.amber)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    child: Text(
                      (proj['durum'] == ProjectStatus.tamamlandi.name
                              ? AppLocalizations.of(context)!.completed
                              : proj['durum'] == ProjectStatus.aktif.name
                                  ? AppLocalizations.of(context)!.active
                                  : AppLocalizations.of(context)!.pending)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: (proj['durum'] == ProjectStatus.tamamlandi.name
                            ? Colors.green
                            : proj['durum'] == ProjectStatus.aktif.name
                                ? Colors.blue
                                : Colors.amber),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                child: Text(
                  _formatPara(proj['kar']),
                  style: TextStyle(
                    color: isPositive
                        ? const Color(0xFF2EC4B6)
                        : const Color(0xFFE71D36),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF011627),
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
              title: Text(AppLocalizations.of(context)!.turkish),
              onTap: () {
                LanguageService.instance.changeLanguage('tr');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(AppLocalizations.of(context)!.english),
              onTap: () {
                LanguageService.instance.changeLanguage('en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Color(0xFF011627),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String baslik;
  final String deger;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatusCard({
    required this.baslik,
    required this.deger,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      deger,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF011627),
                      ),
                    ),
                  ),
                  Text(
                    baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
