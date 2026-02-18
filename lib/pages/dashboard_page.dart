import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import 'raporlar_page.dart';
import 'muhasebe_sayfasi.dart';
import 'hesap_kesim_rapor_page.dart';
import 'fatura_liste_page.dart';
import 'stok_liste_page.dart';
import '../models/project.dart';

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
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    ).format(tutar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Muhasebe Asistanı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _yukleOzetBilgiler,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFE71D36)),
            onPressed: () => AuthService().signOut(),
            tooltip: 'Çıkış Yap',
          ),
          const SizedBox(width: 8),
        ],
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
                    const Text(
                      'HIZLI ERİŞİM',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF011627),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMainActions(),
                    const SizedBox(height: 32),
                    const Text(
                      'DURUM ANALİZİ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF011627),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusGrid(),
                    const SizedBox(height: 32),
                    const Text(
                      'EN KARLI PROJELER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF011627),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopProjects(),
                    const SizedBox(height: 32),
                    const Text(
                      'PERFORMANS GÖSTERGESİ',
                      style: TextStyle(
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
              const Text(
                'NET NAKİT (KASA)',
                style: TextStyle(
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
                child: const Text(
                  'GÜNCEL',
                  style: TextStyle(
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
                label: 'TAHSİLAT',
                value: _formatPara(_ozetBilgiler['toplamGelir']!),
                color: const Color(0xFF2EC4B6),
              ),
              const SizedBox(width: 24),
              _MiniStat(
                label: 'KALAN BORÇ',
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
              label: 'Muhasebe',
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
              label: 'Raporlar',
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
              label: 'Personel',
              color: const Color(0xFF011627),
              onTap: () async {
                await Navigator.pushNamed(context, '/labor');
                _yukleOzetBilgiler();
              },
            ),
            const SizedBox(width: 16),
            _QuickAction(
              icon: Icons.auto_graph_rounded,
              label: 'Hesap Kesimi',
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
          baslik: 'Açık Projeler',
          deger: _ozetBilgiler['acikProjeler']!.toInt().toString(),
          icon: Icons.architecture_rounded,
          onTap: () => Navigator.pushNamed(context, '/projects'),
        ),
        _StatusCard(
          baslik: 'Toplam Cari',
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
              const Expanded(
                child: Text(
                  'Gelir / Gider Dengesi',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF011627),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                child: Text(
                  '%${(profitRatio * 100).toStringAsFixed(1)} Pozitif',
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
              _LegendItem(label: 'Gelir Payı', color: const Color(0xFF2EC4B6)),
              _LegendItem(label: 'Gider Payı', color: const Color(0xFFE71D36)),
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
        child: const Center(
          child: Text(
            'Henüz kârlılık verisi olan proje yok.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
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
                      (proj['durum'] as String? ?? 'Aktif').toUpperCase(),
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
