import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/database_helper.dart';
import '../models/cari_islem.dart';
import '../utils/error_handler.dart';
import '../models/hakedis.dart';
import '../models/cari_hesap.dart';
import '../models/project.dart';
import '../models/worker.dart';
import '../services/sync_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class HesapKesimRaporPage extends StatefulWidget {
  const HesapKesimRaporPage({super.key});

  @override
  State<HesapKesimRaporPage> createState() => _HesapKesimRaporPageState();
}

class _HesapKesimRaporPageState extends State<HesapKesimRaporPage> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  List<Project> _projects = [];
  List<int> _selectedProjectIds = [];
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;
  List<CariHesap> _allCaris = [];
  CariHesap? _selectedOffsetCari;
  bool _isLaborExpanded = false;
  int _touchedPieIndex = -1;
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadReport();
    _syncSubscription = SyncManager.instance.onSyncCompleted.listen((_) {
      if (mounted) _loadReport();
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getSettlementReport(
        _startDate, 
        _endDate, 
        projectIds: _selectedProjectIds.isEmpty ? null : _selectedProjectIds
      );
      final caris = await DatabaseHelper.instance.getAllCariHesaplar();
      final projects = await DatabaseHelper.instance.getAllProjects();
      setState(() {
        _reportData = data;
        _allCaris = caris;
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF011627),
              onPrimary: Colors.white,
              onSurface: Color(0xFF011627),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  String _formatPara(double tutar) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.currency(
      locale: locale,
      symbol: locale == 'tr' ? '₺' : '\$',
      decimalDigits: 2,
    ).format(tutar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settlementReport_caps),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          _buildProjectFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _reportData == null
                        ? Center(key: const ValueKey('no_data'), child: Text(AppLocalizations.of(context)!.noDataFound))
                        : _buildReportContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF011627),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF011627).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.settlementPeriod_caps,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, color: Color(0xFF2EC4B6), size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${DateFormat('dd MMM', Localizations.localeOf(context).toString()).format(_startDate)} - ${DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(_endDate)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EC4B6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2EC4B6).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_calendar_rounded, color: Color(0xFF2EC4B6), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.selectDate_caps,
                      style: const TextStyle(
                        color: Color(0xFF2EC4B6),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectFilter() {
    if (_projects.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final p = _projects[index];
          final isSelected = _selectedProjectIds.contains(p.id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(p.ad, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedProjectIds.add(p.id!);
                  } else {
                    _selectedProjectIds.remove(p.id);
                  }
                });
                _loadReport();
              },
              selectedColor: const Color(0xFF011627),
              checkmarkColor: Colors.white,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportContent() {
    return SingleChildScrollView(
      key: ValueKey('${_startDate.toIso8601String()}-${_endDate.toIso8601String()}-${_selectedProjectIds.join(',')}'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildExecutiveSummary(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            AppLocalizations.of(context)!.personnelSalaryStatus_caps, 
            Icons.people_rounded,
            action: _buildSimpleSettleButton(onTap: () => _settleLabor()),
          ),
          _buildLaborSection(),
          const SizedBox(height: 24),
          // Faturalar ve Stoklar şimdilik kapatıldı
          // _buildSectionHeader(
          //   'FATURA & KDV DURUMU', 
          //   Icons.receipt_long_rounded,
          //   action: _buildSimpleSettleButton(onTap: () => _settleInvoices()),
          // ),
          // _buildInvoiceSection(),
          // const SizedBox(height: 24),
          _buildSectionHeader(
            AppLocalizations.of(context)!.projectHakedis_caps, 
            Icons.assignment_rounded,
            action: _buildSimpleSettleButton(onTap: () => _settleHakedis()),
          ),
          _buildHakedisSection(),
          const SizedBox(height: 24),
          // _buildSectionHeader(
          //   'MÜŞTERİ & KASA DURUMU', 
          //   Icons.account_balance_rounded,
          //   action: _buildSimpleSettleButton(onTap: () => _settleLedger()),
          // ),
          // _buildCariSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF011627)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
                color: Color(0xFF011627),
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleSettleButton({required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
      label: Text(AppLocalizations.of(context)!.settleAccount_caps, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2EC4B6),
        side: const BorderSide(color: Color(0xFF2EC4B6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }

  DateTime _getSettlementDate() {
    return DateTime.now();
  }

  Future<void> _settleHakedis() async {
    final hakedis = _reportData!['hakedis'];
    final items = List<Map<String, dynamic>>.from(hakedis['items'] ?? []);
    final pending = hakedis['pending'].toDouble();

    if (pending <= 0 || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noPendingHakedisFound)));
      return;
    }

    final confirm = await _showConfirmDialog(
      AppLocalizations.of(context)!.processHakedisCollection,
      AppLocalizations.of(context)!.hakedisSettleConfirm(items.length, _formatPara(pending)),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final List<CariIslem> transactions = [];
      final islemTarihi = _getSettlementDate();
      for (var item in items) {
        final double amount = item['amount'].toDouble();
        if (amount > 0) {
          if (item['cariId'] == null) {
             throw Exception('${item['name'] ?? 'Proje'} için Cari Hesap tanımlanmamış. Lütfen düzenlemeden bir Cari Hesap bağlayın.');
          }
          transactions.add(CariIslem(
            cariHesapId: item['cariId'],
            cariHesapUnvan: item['name'] ?? 'Bilinmeyen',
            projectId: item['projectId'],
            tarih: islemTarihi,
            vade: _endDate, // Indicate this settles the selected period
            aciklama: 'Hakediş tahsilatı: ${item['name']} #H:[${(item['hakedisIds'] as List<int>).join(',')}]',
            hesapTipi: 'Nakit',
            borc: amount,
            alacak: 0,
            bakiye: amount,
          ));
        }
      }
      
      await DatabaseHelper.instance.bulkInsertCariIslemler(transactions);
      
      // Hakedişlerin durumunu 'Tahsil Edildi' olarak güncelle (İlgili projeler ve tarih aralığı için)
      final projectIds = items.map((i) => i['projectId'] as int).toSet().toList();
      await DatabaseHelper.instance.bulkUpdateHakedisStatusByProject(
        projectIds, 
        _startDate, 
        _endDate, 
        HakedisDurum.tahsilEdildi
      );

      await _loadReport();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hakedisCollectionsProcessed)));
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
    }
  }

  Future<void> _settleLabor() async {
    final labor = _reportData!['labor'];
    final items = List<Map<String, dynamic>>.from(labor['items']);
    // Filter items where there is something to pay in the CURRENT PERIOD
    final toSettle = items.where((i) => (i['period_balance'] ?? 0.0) != 0).toList();

    if (toSettle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seçilen dönem için ödenecek bakiye bulunamadı.')));
      return;
    }

    final double periodNet = labor['period_net']?.toDouble() ?? 0.0;

    final confirm = await _showConfirmDialog(
      'Seçili Dönemi Kapat',
      'Seçili tarih aralığındaki ${toSettle.length} personelin net hakediş ödemesini (${_formatPara(periodNet.abs())}) yapmak istiyor musunuz?',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final List<CariIslem> transactions = [];
      final islemTarihi = _getSettlementDate();
      for (var item in toSettle) {
        final double amount = item['period_balance'].toDouble();
        if (item['cariId'] == null) {
           throw Exception('${item['name']} için Cari Hesap tanımlanmamış. Lütfen Personel Düzenle kısmından bir Cari Hesap bağlayın.');
        }
        transactions.add(CariIslem(
          cariHesapId: item['cariId'],
          cariHesapUnvan: item['name'],
          projectId: _selectedProjectIds.length == 1 ? _selectedProjectIds.first : null,
          tarih: islemTarihi,
          vade: _endDate, // Indicate this settles the selected period
          aciklama: 'Maaş Ödemesi (Dönem): ${item['name']}',
          hesapTipi: 'Nakit',
          borc: amount < 0 ? amount.abs() : 0,
          alacak: amount > 0 ? amount : 0,
          bakiye: -amount,
        ));
      }
      await DatabaseHelper.instance.bulkInsertCariIslemler(transactions);
      await _loadReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.personnelPaymentsProcessed)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
    }
  }

  Future<void> _settleLedger() async {
    final ledger = _reportData!['ledger'];
    final items = List<Map<String, dynamic>>.from(ledger['items']);
    final toSettle = items.where((i) => i['balance'] != 0).toList();

    if (toSettle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noBalanceToReset)));
      return;
    }

    final confirm = await _showConfirmDialog(
      AppLocalizations.of(context)!.closeCariAccounts,
      AppLocalizations.of(context)!.cariSettleConfirm(toSettle.length),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final List<CariIslem> transactions = [];
      final islemTarihi = _getSettlementDate();
      for (var item in toSettle) {
        final balance = item['balance'].toDouble();
        
        if (item['cariId'] == null) {
           throw Exception('${item['name']} için Cari Hesap bulunamadı.');
        }

        // Cari Hesap Kaydı (Bakiyeyi kapatıyoruz)
        transactions.add(CariIslem(
          cariHesapId: item['cariId'],
          cariHesapUnvan: item['name'],
          tarih: islemTarihi,
          vade: _endDate, // Indicate this settles the selected period
          aciklama: 'Hesap Kapatma',
          hesapTipi: 'Nakit',
          borc: balance < 0 ? balance.abs() : 0,
          alacak: balance > 0 ? balance : 0,
          bakiye: -balance,
        ));
      }
      await DatabaseHelper.instance.bulkInsertCariIslemler(transactions);
      await _loadReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.cariAccountBalancesClosed)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
    }
  }

  // Future<void> _settleInvoices() ...

  Future<bool?> _showConfirmDialog(String title, String message) {
    _selectedOffsetCari = null;
    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), 
              child: Text(AppLocalizations.of(context)!.cancel_caps)
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2EC4B6),
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.confirm_caps),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummary() {
    final fin = _reportData!['financials'] ?? {};
    final bool isProfit = (fin['net_profit'] ?? 0) >= 0;
    final double revenue = (fin['total_revenue'] ?? 0).toDouble();
    final double cost = (fin['total_cost'] ?? 0).toDouble();
    final double total = revenue + cost;
    final double ratio = total > 0 ? (revenue / total) : (isProfit ? 1.0 : 0.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isProfit 
            ? [const Color(0xFF1B2B48), const Color(0xFF011627)]
            : [const Color(0xFF3D1D1D), const Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? const Color(0xFF2EC4B6) : const Color(0xFFE71D36)).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 150,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.periodNetProfit_caps,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isProfit ? const Color(0xFF2EC4B6) : const Color(0xFFE71D36)).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isProfit ? const Color(0xFF2EC4B6) : const Color(0xFFE71D36)).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isProfit ? 'KARDA' : 'ZARARDA',
                        style: TextStyle(
                          color: isProfit ? const Color(0xFF2EC4B6) : const Color(0xFFE71D36),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatPara((fin['net_profit'] ?? 0).toDouble()),
                    style: TextStyle(
                      color: isProfit ? const Color(0xFF2EC4B6) : const Color(0xFFE71D36),
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Modern Progress Indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.incomeShare} %${(ratio * 100).toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${AppLocalizations.of(context)!.expenseShare} %${((1 - ratio) * 100).toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(height: 8, color: const Color(0xFFE71D36)), // Cost (Base)
                          AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            curve: Curves.fastOutSlowIn,
                            height: 8,
                            width: (MediaQuery.of(context).size.width - 88) * ratio,
                            color: const Color(0xFF2EC4B6), // Revenue
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildInteractiveStat(
                        AppLocalizations.of(context)!.totalRevenue_caps,
                        revenue,
                        const Color(0xFF2EC4B6),
                        Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInteractiveStat(
                        AppLocalizations.of(context)!.totalCost_caps,
                        cost,
                        const Color(0xFFE71D36),
                        Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveStat(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatPara(value),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        Text(
          _formatPara(value),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _buildLaborSection() {
    final labor = _reportData!['labor'];
    final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(labor['items']);
    final double cumulative = labor['cumulative_balance'].toDouble();
    final double periodNet = labor['period_net']?.toDouble() ?? 0.0;
    final bool isPeriodClosed = periodNet.abs() < 0.1;

    return _buildCardWrapper(
      child: Column(
        children: [
          _buildDataRow(
            AppLocalizations.of(context)!.previousBalanceTransfer, 
            labor['previous_balance'].toDouble().abs(), 
            valueColor: Colors.grey.shade600
          ),
          _buildDataRow(
            AppLocalizations.of(context)!.periodEarnedPlus, 
            labor['period_earned'].toDouble().abs(), 
            isBold: true,
            valueColor: Colors.black,
          ),
          _buildDataRow(
            AppLocalizations.of(context)!.periodPaidMinus, 
            labor['period_paid'].toDouble().abs(), 
            valueColor: Colors.blue.shade400
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Seçili Dönem Kalan Bakiye',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF011627),
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatPara(periodNet.abs()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isPeriodClosed ? Colors.grey : const Color(0xFFE71D36),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildDataRow(
            'Genel Toplam Bakiye (Tüm Zamanlar)', 
            cumulative, 
            isBold: true,
            valueColor: cumulative.abs() < 0.1 ? Colors.grey : const Color(0xFF011627)
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  AppLocalizations.of(context)!.seePersonnelDetails, 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)
                ),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                onExpansionChanged: (expanded) => setState(() => _isLaborExpanded = expanded),
                children: items.map((item) {
                  final worked = item['worked'] ?? 0;
                  final leave = item['leave'] ?? 0;
                  final sunday = item['sunday'] ?? 0;
                  final absent = item['absent'] ?? 0;
                  final prev = item['previous_balance']?.toDouble() ?? 0.0;
                  final earned = item['period_earned']?.toDouble() ?? 0.0;
                                final double periodBalance = item['period_balance']?.toDouble() ?? 0.0;
                  final double total = item['cumulative_balance']?.toDouble() ?? 0.0;
                  final bool periodSettled = periodBalance.abs() < 0.1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                periodSettled ? '${item['name']} (Dönem Kapalı)' : item['name'], 
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.w900, 
                                  color: periodSettled ? Colors.grey : const Color(0xFF011627)
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatPara(periodBalance.abs()), 
                              style: TextStyle(
                                fontSize: 14, 
                                fontWeight: FontWeight.w900, 
                                color: periodSettled ? Colors.grey : const Color(0xFFE71D36)
                              )
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildMiniActivityBadge(Icons.check_circle_rounded, worked.toString(), const Color(0xFF2EC4B6), worked > 0),
                            const SizedBox(width: 8),
                            _buildMiniActivityBadge(Icons.event_note_rounded, leave.toString(), Colors.blue, leave > 0),
                            const SizedBox(width: 8),
                            _buildMiniActivityBadge(Icons.wb_sunny_rounded, sunday.toString(), Colors.amber.shade700, sunday > 0),
                            const SizedBox(width: 8),
                            _buildMiniActivityBadge(Icons.error_outline_rounded, absent.toString(), Colors.red, absent > 0),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Eski Borç: ${_formatPara(prev.abs())}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                                ),
                                Text(
                                  'Genel Toplam: ${_formatPara(total.abs())}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, thickness: 0.5),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceSection() {
    final inv = _reportData!['invoices'];
    final double vatBalance = inv['vat_balance'].toDouble();

    return _buildCardWrapper(
      child: Column(
        children: [
          _buildDataRow(AppLocalizations.of(context)!.totalSalesTaxBase, inv['sales'].toDouble()),
          _buildDataRow(AppLocalizations.of(context)!.totalPurchaseTaxBase, inv['purchases'].toDouble()),
          const Divider(),
          _buildDataRow('${AppLocalizations.of(context)!.salesVat} (%20)', inv['sales_vat'].toDouble(), valueColor: Colors.blue),
          _buildDataRow('${AppLocalizations.of(context)!.purchaseVat} (%20)', inv['purchase_vat'].toDouble(), valueColor: Colors.orange),
          const Divider(),
          _buildDataRow(
            vatBalance >= 0 ? AppLocalizations.of(context)!.vatToPay : AppLocalizations.of(context)!.vatDeferred, 
            vatBalance.abs(), 
            isBold: true, 
            valueColor: vatBalance >= 0 ? Colors.red : Colors.green
          ),
        ],
      ),
    );
  }

  Widget _buildHakedisSection() {
    final hakedis = _reportData!['hakedis'];
    return _buildCardWrapper(
      child: Column(
        children: [
          _buildDataRow(AppLocalizations.of(context)!.producedHakedisNet, hakedis['total_net'].toDouble()),
          _buildDataRow(AppLocalizations.of(context)!.collected, hakedis['collected'].toDouble(), valueColor: Colors.green),
          const Divider(),
          _buildDataRow(
            AppLocalizations.of(context)!.pendingCollection, 
            hakedis['pending'].toDouble(), 
            isBold: true, 
            valueColor: Colors.orange
          ),
        ],
      ),
    );
  }

  Widget _buildCariSection() {
    final ledger = _reportData!['ledger'];
    return _buildCardWrapper(
      child: Column(
        children: [
          _buildDataRow(AppLocalizations.of(context)!.customerReceivables, ledger['total_receivable'].toDouble(), valueColor: Colors.green),
          _buildDataRow(AppLocalizations.of(context)!.supplierPayables, ledger['total_payable'].toDouble(), valueColor: Colors.red),
          const Divider(),
          _buildDataRow(
            AppLocalizations.of(context)!.mainCashStatus, 
            ledger['net_balance'].toDouble(), 
            isBold: true,
            valueColor: ledger['net_balance'] >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildMiniActivityBadge(IconData icon, String value, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isActive ? color.withOpacity(0.3) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: isActive ? color : Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, double value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? const Color(0xFF011627) : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatPara(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: valueColor ?? (isBold ? const Color(0xFF011627) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
