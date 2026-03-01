import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/database_helper.dart';
import '../models/gelir_gider.dart';
import '../models/hakedis.dart';
import '../models/project.dart';
import '../widgets/banner_ad_widget.dart';

class RaporlarPage extends StatefulWidget {
  const RaporlarPage({super.key});

  @override
  State<RaporlarPage> createState() => _RaporlarPageState();
}

class _RaporlarPageState extends State<RaporlarPage> {
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;
  Map<String, double> _genelOzet = {'gelir': 0.0, 'gider': 0.0, 'kar': 0.0};
  Map<String, double> _kategoriler = {};
  Map<String, dynamic> _workerBreakdown = {};
  List<Map<String, dynamic>> _projeRaporlari = [];
  List<Project> _projeler = [];
  int? _seciliProjeId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _baslangicTarihi = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _bitisTarihi = DateTime.now();
    _yukleBaslangicVerileri();
  }

  Future<void> _yukleBaslangicVerileri() async {
    await _yukleProjeler();
    await _yukleRapor();
  }

  Future<void> _yukleProjeler() async {
    try {
      final projeler = await DatabaseHelper.instance.getAllProjects();
      setState(() {
        _projeler = projeler;
      });
    } catch (e) {
      // debugPrint('Proje yükleme hatası: $e');
    }
  }

  Future<void> _yukleRapor() async {
    setState(() => _isLoading = true);
    try {
      final analysis = await DatabaseHelper.instance
          .getDetailedFinancialAnalysis(_baslangicTarihi!, _bitisTarihi!, projectId: _seciliProjeId);
      final projeler = await DatabaseHelper.instance.getProjectReports();
      setState(() {
        _genelOzet = {
          'gelir': analysis['gelir'],
          'gider': analysis['gider'],
          'kar': analysis['kar'],
        };
        _kategoriler = Map<String, double>.from(analysis['kategoriler']);
        _workerBreakdown = Map<String, dynamic>.from(analysis['worker_breakdown'] ?? {});
        _projeRaporlari = projeler;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorPrefix}: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tarihSec() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: _baslangicTarihi!,
        end: _bitisTarihi!,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF011627),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF011627),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _baslangicTarihi = picked.start;
        _bitisTarihi = picked.end;
      });
      _yukleRapor();
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _yukleRapor,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildProjectFilter(),
                  const SizedBox(height: 32),
                  _buildExecutiveSummary(),
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
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.projectBasedPerformance,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF011627),
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProjectList(),
                ],
              ),
            ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    AppLocalizations.of(context)!.financialAnalysis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF011627),
                      letterSpacing: -1.0,
                    ),
                  ),
                  Text(
                    '${DateFormat('MMMM yyyy', Localizations.localeOf(context).toString()).format(_baslangicTarihi!)} ${AppLocalizations.of(context)!.summary}', // simplified
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: IconButton(
                onPressed: _tarihSec,
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF011627),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(null, AppLocalizations.of(context)!.allProjects),
          ..._projeler.map((p) => _buildFilterChip(p.id, p.ad)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int? id, String label) {
    final bool isSelected = _seciliProjeId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _seciliProjeId = id;
            });
            _yukleRapor();
          }
        },
        selectedColor: const Color(0xFF011627),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF011627),
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.1),
          ),
        ),
        showCheckmark: false,
        elevation: isSelected ? 4 : 0,
      ),
    );
  }

  Widget _buildExecutiveSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SummaryCard(
              title: AppLocalizations.of(context)!.totalCollection.toUpperCase(),
              value: _formatPara(_genelOzet['gelir']!),
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF2EC4B6),
              isDark: false,
            ),
            const SizedBox(width: 16),
            _SummaryCard(
              title: AppLocalizations.of(context)!.netProfit.toUpperCase(),
              value: _formatPara(_genelOzet['kar']!),
              icon: Icons.account_balance_rounded,
              color: const Color(0xFF011627),
              isDark: true,
            ),
          ],
        ),
        const SizedBox(height: 32),
         Text(
          AppLocalizations.of(context)!.expenseBreakdown,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF011627),
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildExpenseBreakdown(),
      ],
    );
  }

  Widget _buildExpenseBreakdown() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: _kategoriler.entries.map((entry) {
          double ratio = _genelOzet['gider']! > 0
              ? entry.value / _genelOzet['gider']!
              : 0;
          
          final bool isPendingLabor = entry.key == 'İşçilik (Bekleyen)';

          Widget row = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _translateCategory(entry.key, context),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatPara(entry.value),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    entry.key.contains('İşçilik')
                        ? (entry.key.contains('Ödenen')
                              ? Colors.purple
                              : Colors.purple.withOpacity(0.4))
                        : (entry.key == 'Malzeme/Hizmet'
                              ? Colors.orange
                              : Colors.blue),
                  ),
                ),
              ),
            ],
          );

          if (isPendingLabor && _workerBreakdown.isNotEmpty) {
            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: row,
                children: _workerBreakdown.entries.map((wb) {
                  final data = wb.value as Map<String, dynamic>;
                  final amount = data['amount'] as double;
                  final worked = data['worked'] as int;
                  final leave = data['leave'] as int;
                  final sunday = data['sunday'] as int;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(wb.key, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                            Text(_formatPara(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.purple)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$worked ${AppLocalizations.of(context)!.normal} + $leave ${AppLocalizations.of(context)!.onLeave} + $sunday ${AppLocalizations.of(context)!.sunday}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: row,
          );
        }).toList(),
      ),
    );
  }

  String _translateCategory(String key, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Malzeme/Hizmet':
        return l10n.materialService;
      case 'İşçilik (Ödenen)':
        return l10n.laborPaid;
      case 'İşçilik (Bekleyen)':
        return l10n.pendingWorkerPayment;
      case 'Cari Ödemeler':
        return l10n.accountPayments;
      case 'Kasa Çıkışları':
        return l10n.cashOutflows;
      default:
        return key;
    }
  }

  Widget _buildProjectList() {
    if (_projeRaporlari.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            AppLocalizations.of(context)!.noProjectsDefined,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      );
    }
    return Column(
      children: _projeRaporlari
          .map((rp) => _ProjectReportItem(report: rp))
          .toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: isDark
              ? null
              : Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? Colors.white : color, size: 20),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade500,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF011627),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectReportItem extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ProjectReportItem({required this.report});

  @override
  Widget build(BuildContext context) {
    double progress = 0;
    if (report['gelir'] > 0) {
      progress = report['kar'] / report['gelir'];
    }
    final bool isPositive = report['kar'] >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF011627).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Color(0xFF011627),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['projeAd'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF011627),
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context)!.profitabilityRate}: %${(progress * 100).toStringAsFixed(1)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(
                      locale: Localizations.localeOf(context).toString(),
                      symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : '\$',
                      decimalDigits: 0,
                    ).format(report['kar']),
                    style: TextStyle(
                      color: isPositive
                          ? const Color(0xFF2EC4B6)
                          : const Color(0xFFE71D36),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                   Text(
                    AppLocalizations.of(context)!.netProfit.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Custom Bar Representing Income/Expense ratio
          _SimpleRatioBar(gelir: report['gelir'], gider: report['gider']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _MiniValue(
                  label: AppLocalizations.of(context)!.collected_caps.substring(0, 5), // hacky limit
                  value: report['gelir'] ?? 0.0,
                  color: const Color(0xFF2EC4B6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniValue(
                  label: AppLocalizations.of(context)!.expenses.toUpperCase(),
                  value: report['gider'] ?? 0.0,
                  color: const Color(0xFFE71D36),
                ),
              ),
            ],
          ),
          if ((report['bekleyenIscilik'] ?? 0.0) > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.pendingWorkerPayment}:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: Localizations.localeOf(context).toString(),
                      symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : '\$',
                      decimalDigits: 0,
                    ).format(report['bekleyenIscilik']),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SimpleRatioBar extends StatelessWidget {
  final double gelir;
  final double gider;
  const _SimpleRatioBar({required this.gelir, required this.gider});

  @override
  Widget build(BuildContext context) {
    double total = gelir + gider;
    if (total == 0) total = 1;
    double expenseRatio = gider / total;

    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: (gelir * 100).toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
          Expanded(
            flex: (gider * 100).toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE71D36),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniValue({
    required this.label,
    required this.value,
    required this.color,
  });

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
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          NumberFormat.currency(
            locale: Localizations.localeOf(context).toString(),
            symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : '\$',
            decimalDigits: 0,
          ).format(value),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF011627),
          ),
        ),
      ],
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

extension on _RaporlarPageState {
  Widget _buildPerformanceIndicator() {
    double total = _genelOzet['gelir']! + _genelOzet['gider']!;
    double profitRatio = total > 0 ? _genelOzet['gelir']! / total : 0.5;

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
                  AppLocalizations.of(context)!.periodIncomeExpenseBalance,
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
                  AppLocalizations.of(context)!.xPercentPositive((profitRatio * 100).toStringAsFixed(1)),
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
}
