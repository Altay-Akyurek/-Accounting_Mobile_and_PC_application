import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/cari_islem.dart';
import '../models/hakedis.dart';
import '../models/cari_hesap.dart';
import '../models/project.dart';
import '../models/worker.dart';

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

  @override
  void initState() {
    super.initState();
    _loadReport();
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
          SnackBar(content: Text('Rapor yüklenirken hata oluştu: $e')),
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
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(tutar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('HESAP KESİM RAPORU'),
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
                : _reportData == null
                    ? const Center(child: Text('Veri bulunamadı'))
                    : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF011627),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HESAP DÖNEMİ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('dd MMM', 'tr_TR').format(_startDate)} - ${DateFormat('dd MMM yyyy', 'tr_TR').format(_endDate)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('TARİH SEÇ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2EC4B6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildExecutiveSummary(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'PERSONEL & MAAŞ DURUMU', 
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
            'PROJE HAKEDİŞLERİ', 
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
              color: Color(0xFF011627),
            ),
          ),
          if (action != null) ...[
            const Spacer(),
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
      label: const Text('HESABI KES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2EC4B6),
        side: const BorderSide(color: Color(0xFF2EC4B6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }

  Future<void> _settleHakedis() async {
    final hakedis = _reportData!['hakedis'];
    final items = List<Map<String, dynamic>>.from(hakedis['items'] ?? []);
    final pending = hakedis['pending'].toDouble();

    if (pending <= 0 || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tahsil edilecek bekleyen hakediş bulunamadı.')));
      return;
    }

    final confirm = await _showConfirmDialog(
      'Hakediş Tahsilatı İşle',
      '${items.length} projenin toplam ${_formatPara(pending)} tutarındaki hakedişi, ilgili cari hesaplara "BORÇ" (Alınan) olarak işlenecektir.',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final List<CariIslem> transactions = [];
      for (var item in items) {
        final double amount = item['amount'].toDouble();
        if (amount > 0) {
          transactions.add(CariIslem(
            cariHesapId: item['cariId'],
            cariHesapUnvan: item['cariName'] ?? 'Bilinmeyen',
            projectId: item['projectId'],
            tarih: DateTime.now(),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hakediş tahsilatları cari hesaplara işlendi.')));
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _settleLabor() async {
    final labor = _reportData!['labor'];
    final items = List<Map<String, dynamic>>.from(labor['items']);
    final toSettle = items.where((i) => i['amount'] != 0).toList();

    if (toSettle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sıfırlanacak bakiye bulunamadı.')));
      return;
    }

    final confirm = await _showConfirmDialog(
      'Personel Hesabı Kes',
      '${toSettle.length} personelin toplam ${_formatPara(labor['net_debt'].toDouble())} tutarındaki maaş ödemesi, ana kasadan personeller adına "ALACAK" (Verilecek) olarak muhasebeleşecektir.',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final List<CariIslem> transactions = [];
      for (var item in toSettle) {
        final double amount = item['amount'].toDouble();
        transactions.add(CariIslem(
          cariHesapId: item['cariId'],
          cariHesapUnvan: item['name'],
          tarih: DateTime.now(),
          aciklama: 'Maaş Ödemesi: ${item['name']}',
          hesapTipi: 'Nakit',
          borc: 0,
          alacak: amount,
          bakiye: -amount,
        ));
      }
      await DatabaseHelper.instance.bulkInsertCariIslemler(transactions);
      await _loadReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personel maaş ödemeleri muhasebeleşti.')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _settleLedger() async {
    final ledger = _reportData!['ledger'];
    final items = List<Map<String, dynamic>>.from(ledger['items']);
    final toSettle = items.where((i) => i['balance'] != 0).toList();

    if (toSettle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sıfırlanacak bakiye bulunamadı.')));
      return;
    }

    final confirm = await _showConfirmDialog(
      'Cari Hesapları Kapat',
      '${toSettle.length} cari hesabın dönemsel bakiyesi "HESAP KAPATMA" olarak muhasebeye işlenecektir.',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final List<CariIslem> transactions = [];
      for (var item in toSettle) {
        final balance = item['balance'].toDouble();
        
        // Cari Hesap Kaydı (Bakiyeyi kapatıyoruz)
        transactions.add(CariIslem(
          cariHesapId: item['cariId'],
          cariHesapUnvan: item['name'],
          tarih: DateTime.now(),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cari hesap bakiyeleri kapatıldı.')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
              child: const Text('İPTAL')
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2EC4B6),
                foregroundColor: Colors.white,
              ),
              child: const Text('ONAYLA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummary() {
    final fin = _reportData!['financials'];
    final bool isProfit = fin['net_profit'] >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'DÖNEM NET KARI',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatPara(fin['net_profit'].toDouble()),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isProfit ? const Color(0xFF2EC4B6) : Colors.red,
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('TOPLAM GELİR', fin['total_revenue'].toDouble(), Colors.green),
              _buildMiniStat('TOPLAM GİDER', fin['total_cost'].toDouble(), Colors.red),
            ],
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

    return _buildCardWrapper(
      child: Column(
        children: [
          _buildDataRow('Hak Edilen Toplam', labor['total_earned'].toDouble()),
          _buildDataRow('Ödenen Toplam', labor['total_paid'].toDouble()),
          const Divider(),
          _buildDataRow(
            'Kalan Personel Borcu', 
            labor['net_debt'].toDouble(), 
            isBold: true, 
            valueColor: Colors.red
          ),
          if (items.isNotEmpty) ...[
            const Divider(),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text('Personel Detaylarını Gör', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                onExpansionChanged: (expanded) => setState(() => _isLaborExpanded = expanded),
                children: items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(_formatPara(item['amount'].toDouble()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ]
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
          _buildDataRow('Toplam Satış (Matrah)', inv['sales'].toDouble()),
          _buildDataRow('Toplam Alış (Matrah)', inv['purchases'].toDouble()),
          const Divider(),
          _buildDataRow('Satış KDV (%20)', inv['sales_vat'].toDouble(), valueColor: Colors.blue),
          _buildDataRow('Alış KDV (%20)', inv['purchase_vat'].toDouble(), valueColor: Colors.orange),
          const Divider(),
          _buildDataRow(
            vatBalance >= 0 ? 'Ödenecek KDV' : 'Devreden KDV', 
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
          _buildDataRow('Üretilen Hakediş (Net)', hakedis['total_net'].toDouble()),
          _buildDataRow('Tahsil Edilen', hakedis['collected'].toDouble(), valueColor: Colors.green),
          const Divider(),
          _buildDataRow(
            'Bekleyen Tahsilat', 
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
          _buildDataRow('Müşteri Alacakları', ledger['total_receivable'].toDouble(), valueColor: Colors.green),
          _buildDataRow('Tedarikçi Borçları', ledger['total_payable'].toDouble(), valueColor: Colors.red),
          const Divider(),
          _buildDataRow(
            'Ana Kasa (Güncel Durum)', 
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

  Widget _buildDataRow(String label, double value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFF011627) : Colors.black87,
            ),
          ),
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
