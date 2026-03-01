import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/cari_islem.dart';
import '../models/cari_hesap.dart';
import '../models/worker.dart';
import '../models/project.dart';
import '../services/database_helper.dart';

class CariDetaySayfasi extends StatefulWidget {
  final int cariId;
  final String cariUnvan;

  const CariDetaySayfasi({
    super.key,
    required this.cariId,
    required this.cariUnvan,
  });

  @override
  State<CariDetaySayfasi> createState() => _CariDetaySayfasiState();
}

class _CariDetaySayfasiState extends State<CariDetaySayfasi> {
  List<CariIslem> _islemler = [];
  CariHesap? _cari;
  Worker? _worker;
  List<Puantaj> _workerPuantaj = [];
  Map<int, String> _projectNames = {};
  bool _isLoading = true;
  Map<String, double> _toplamlar = {'borc': 0.0, 'alacak': 0.0, 'bakiye': 0.0};

  @override
  void initState() {
    super.initState();
    _yukleVeriler();
  }

  Future<void> _yukleVeriler() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final islemler = await DatabaseHelper.instance.getCariIslemlerByCariId(widget.cariId);
      final toplamlar = await DatabaseHelper.instance.getCariToplamlar(widget.cariId);
      final cariler = await DatabaseHelper.instance.getAllCariHesaplar();
      final cari = cariler.firstWhere((c) => c.id == widget.cariId);
      
      Worker? worker = await DatabaseHelper.instance.getWorkerByCariId(widget.cariId);
      List<Puantaj> puantaj = [];
      Map<int, String> projectNames = {};
      
      if (worker != null && worker.id != null) {
        puantaj = await DatabaseHelper.instance.getPuantajByWorkerId(worker.id!, null, null);
        puantaj.sort((a, b) => b.tarih.compareTo(a.tarih));
        
        final projects = await DatabaseHelper.instance.getAllProjects();
        for (var p in projects) {
          if (p.id != null) projectNames[p.id!] = p.ad;
        }
      }

      setState(() {
        _islemler = islemler;
        _toplamlar = toplamlar;
        _cari = cari;
        _worker = worker;
        _workerPuantaj = puantaj;
        _projectNames = projectNames;
        _isLoading = false;
      });
    } catch (e) {
      // debugPrint('DEBUG: Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatPara(double tutar) {
    final locale = Localizations.localeOf(context).toString();
    try {
      return NumberFormat.currency(
        locale: locale,
        symbol: locale == 'tr' ? '₺' : '\$',
        decimalDigits: 2,
      ).format(tutar);
    } catch (e) {
      return (locale == 'tr' ? '₺' : '\$') + tutar.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${AppLocalizations.of(context)!.accountDetail}: ${widget.cariUnvan.toUpperCase()}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _yukleVeriler,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ekstre (Ledger)', icon: Icon(Icons.receipt_long)),
              Tab(text: 'İşçilik Özeti', icon: Icon(Icons.engineering)),
            ],
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            // Üst Özet Paneli
            Container(
              color: const Color(0xFF003399),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _OzetKart(
                      baslik: _cari?.isKasa == true ? AppLocalizations.of(context)!.collectionIn_caps : AppLocalizations.of(context)!.incomingDebt_caps,
                      deger: _formatPara(_toplamlar['borc']!),
                      renk: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _OzetKart(
                      baslik: _cari?.isKasa == true ? AppLocalizations.of(context)!.paymentOut_caps : AppLocalizations.of(context)!.outgoingCredit_caps,
                      deger: _formatPara(_toplamlar['alacak']!),
                      renk: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _OzetKart(
                      baslik: _cari?.isKasa == true ? AppLocalizations.of(context)!.netCashKasa_caps : AppLocalizations.of(context)!.netStatusBalance_caps,
                      deger: _formatPara(_toplamlar['bakiye']!),
                      renk: Colors.yellow,
                    ),
                  ),
                ],
              ),
            ),
            // Tab İçeriği
            Expanded(
              child: TabBarView(
                children: [
                  _buildEkstreTab(),
                  _buildIscilikOzetiTab(),
                ],
              ),
            ),
            // Alt Butonlar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.excelFeatureSoon)),
                        );
                      },
                      icon: const Icon(Icons.file_download, size: 18),
                      label: Text(AppLocalizations.of(context)!.exportExcel),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.printFeatureSoon)),
                        );
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: Text(AppLocalizations.of(context)!.print),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Makbuz özelliği yakında eklenecek')),
                        );
                      },
                      icon: const Icon(Icons.receipt, size: 18),
                      label: Text(AppLocalizations.of(context)!.createReceipt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 45,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(AppLocalizations.of(context)!.back),
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

  Widget _buildEkstreTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_islemler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noTransactionsYet, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFE6EBF5)),
          columns: [
            DataColumn(label: Text(AppLocalizations.of(context)!.tableDate, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.tableDescription, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.tableStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.tableIncoming, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.tableOutgoing, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.balance, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _islemler.map((islem) {
            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(islem.tarih))),
                DataCell(Text(islem.displayAciklama)),
                DataCell(Text(islem.hesapTipi)),
                DataCell(Text(
                  islem.borc > 0 ? _formatPara(islem.borc) : '',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                )),
                DataCell(Text(
                  islem.alacak > 0 ? _formatPara(islem.alacak) : '',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                )),
                DataCell(Text(_formatPara(islem.bakiye))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIscilikOzetiTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_worker == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.accountNotLinkedToWorker, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_workerPuantaj.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.engineering_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noLaborRecordsYet, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF0F2F5)),
          columns: [
            DataColumn(label: Text(AppLocalizations.of(context)!.tableDate, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.project, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.work_caps, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.overtime_caps, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.status, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context)!.hakedis_short, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _workerPuantaj.map((p) {
            final cost = DatabaseHelper.instance.calculateLaborCost(p, _worker!);
            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(p.tarih))),
                DataCell(Text(_projectNames[p.projectId] ?? AppLocalizations.of(context)!.notSpecified)),
                DataCell(Text(p.saat.toString())),
                DataCell(Text(p.mesai.toString())),
                DataCell(Text(p.status.name.toUpperCase())),
                DataCell(Text(
                  _formatPara(cost),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _OzetKart extends StatelessWidget {
  final String baslik;
  final String deger;
  final Color renk;

  const _OzetKart({
    required this.baslik,
    required this.deger,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: const TextStyle(
            color: Color(0xFFC8D2F0),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          deger,
          style: TextStyle(
            color: renk,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


