import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/worker.dart';
import '../models/project.dart';

class LaborSummaryReportPage extends StatefulWidget {
  const LaborSummaryReportPage({super.key});

  @override
  State<LaborSummaryReportPage> createState() => _LaborSummaryReportPageState();
}

class _LaborSummaryReportPageState extends State<LaborSummaryReportPage> {
  bool _isLoading = true;
  List<Puantaj> _puantajlar = [];
  Map<int, Worker> _workerMap = {};
  Map<int, String> _projectNames = {};
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getAllPuantajlar(baslangic: _startDate, bitis: _endDate),
        DatabaseHelper.instance.getAllWorkers(),
        DatabaseHelper.instance.getAllProjects(),
      ]);

      final puantajList = results[0] as List<Puantaj>;
      final workerList = results[1] as List<Worker>;
      final projectList = results[2] as List<Project>;

      Map<int, Worker> wMap = {};
      for (var w in workerList) {
        if (w.id != null) wMap[w.id!] = w;
      }

      Map<int, String> pMap = {};
      for (var p in projectList) {
        if (p.id != null) pMap[p.id!] = p.ad;
      }

      puantajList.sort((a, b) => b.tarih.compareTo(a.tarih));

      setState(() {
        _puantajlar = puantajList;
        _workerMap = wMap;
        _projectNames = pMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DEBUG: Labor Summary load error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  String _formatPara(double tutar) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(tutar);
  }

  @override
  Widget build(BuildContext context) {
    double totalCost = 0;
    double totalHours = 0;
    for (var p in _puantajlar) {
      final worker = _workerMap[p.workerId];
      if (worker != null) {
        totalCost += DatabaseHelper.instance.calculateLaborCost(p, worker);
      }
      totalHours += p.saat;
    }

    // Grouping
    Map<int, List<Puantaj>> groupedPuantaj = {};
    for (var p in _puantajlar) {
      groupedPuantaj.putIfAbsent(p.workerId, () => []).add(p);
    }

    final sortedWorkerIds = groupedPuantaj.keys.toList()
      ..sort((a, b) => (_workerMap[a]?.adSoyad ?? '').compareTo(_workerMap[b]?.adSoyad ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('İŞÇİLİK ÖZET RAPORU'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Tarih Aralığı',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF011627),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('dd.MM.yyyy').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Text('Seçili Dönem Kayıtları', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPara(totalCost),
                      style: const TextStyle(color: Color(0xFF2EC4B6), fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    Text('$totalHours Saat Çalışma', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Grouped List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _puantajlar.isEmpty
                    ? const Center(child: Text('Bu tarih aralığında kayıt bulunamadı.'))
                    : ListView.builder(
                        itemCount: sortedWorkerIds.length,
                        itemBuilder: (context, index) {
                          final workerId = sortedWorkerIds[index];
                          final worker = _workerMap[workerId];
                          final puantajs = groupedPuantaj[workerId]!;
                          
                          double workerTotalHours = 0;
                          double workerTotalCost = 0;
                          for (var p in puantajs) {
                            workerTotalHours += p.saat;
                            if (worker != null) {
                              workerTotalCost += DatabaseHelper.instance.calculateLaborCost(p, worker);
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ExpansionTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF011627),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                worker?.adSoyad ?? 'Bilinmiyor',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                'Toplam: $workerTotalHours Saat  |  ${_formatPara(workerTotalCost)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              children: [
                                const Divider(height: 1),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowHeight: 40,
                                    columnSpacing: 24,
                                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FA)),
                                    columns: const [
                                      DataColumn(label: Text('TARİH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('PROJE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('SAAT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('MESAİ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('TUTAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: puantajs.map((p) {
                                      final cost = worker != null 
                                          ? DatabaseHelper.instance.calculateLaborCost(p, worker)
                                          : 0.0;
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(DateFormat('dd.MM.yy').format(p.tarih), style: const TextStyle(fontSize: 12))),
                                          DataCell(Text(_projectNames[p.projectId] ?? '-', style: const TextStyle(fontSize: 12))),
                                          DataCell(Text(p.saat.toString(), style: const TextStyle(fontSize: 12))),
                                          DataCell(Text(p.mesai.toString(), style: const TextStyle(fontSize: 12))),
                                          DataCell(Text(_formatPara(cost), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel dışa aktarımı yakında eklenecek')),
          );
        },
        child: const Icon(Icons.file_download),
      ),
    );
  }
}
