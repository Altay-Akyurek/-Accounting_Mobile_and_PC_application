import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/worker.dart';

class WorkerAnalysisPage extends StatefulWidget {
  const WorkerAnalysisPage({super.key});

  @override
  State<WorkerAnalysisPage> createState() => _WorkerAnalysisPageState();
}

class _WorkerAnalysisPageState extends State<WorkerAnalysisPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = true;
  List<Worker> _workers = [];
  List<Puantaj> _allPuantajs = [];
  
  String _selectedWorker = '';
  List<FlSpot> _lineSpots = [];
  List<Map<String, dynamic>> _workerMonthlyStats = [];
  int _totalWorkedDays = 0;
  int _totalLeaveDays = 0;
  int _selectedWorkerWorkedDays = 0;
  int _selectedWorkerLeaveDays = 0;

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
      final results = await Future.wait<List<dynamic>>([
        _db.getAllWorkers(),
        _db.getAllPuantajlar(baslangic: _startDate, bitis: _endDate),
      ]);

      _workers = results[0] as List<Worker>;
      _allPuantajs = results[1] as List<Puantaj>;

      if (_selectedWorker.isEmpty && _workers.isNotEmpty) {
        _selectedWorker = _workers.first.adSoyad;
      }

      _processData();
    } catch (e) {
      print('DEBUG: Worker Analysis load error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2EC4B6),
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
      _loadData();
    }
  }

  void _processData() {
    // 1. Line Chart Data (Dynamic Range)
    _lineSpots = [];
    final int dayCount = _endDate.difference(_startDate).inDays + 1;
    final worker = _workers.firstWhere((w) => w.adSoyad == _selectedWorker, orElse: () => _workers.first);
    for (int i = 0; i < dayCount; i++) {
      final date = _startDate.add(Duration(days: i));
      double dailyTotal = 0;

      final dayPuantajs = _allPuantajs.where((Puantaj p) => 
        p.workerId == worker.id && 
        p.tarih.year == date.year && p.tarih.month == date.month && p.tarih.day == date.day
      );
      for (Puantaj p in dayPuantajs) {
        if (p.status == PuantajStatus.normal) dailyTotal += p.saat;
      }
      _lineSpots.add(FlSpot(i.toDouble(), dailyTotal));
    }

    // 2. Bar Chart & Pie Chart Data (Selected Range Statistics)
    _workerMonthlyStats = [];
    _totalWorkedDays = 0;
    _totalLeaveDays = 0;
    _selectedWorkerWorkedDays = 0;
    _selectedWorkerLeaveDays = 0;

    final colors = [
      const Color(0xFF2EC4B6), const Color(0xFFE71D36), 
      const Color(0xFF011627), Colors.amber, Colors.purple,
      Colors.orange, Colors.blue, Colors.green,
    ];

    for (int i = 0; i < _workers.length; i++) {
      final w = _workers[i];
      final workerPuantajs = _allPuantajs.where((Puantaj p) => p.workerId == w.id);
      
      // Calculate unique worked and leave days (Date only, no hours/multiple entries)
      final Set<String> workedDates = {};
      final Set<String> leaveDates = {};

      for (var p in workerPuantajs) {
        final dateKey = "${p.tarih.year}-${p.tarih.month}-${p.tarih.day}";
        if (p.status == PuantajStatus.normal) {
          workedDates.add(dateKey);
        } else if ([PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)) {
          leaveDates.add(dateKey);
        }
      }

      int worked = workedDates.length;
      int leave = leaveDates.length;
      
      _totalWorkedDays += worked;
      _totalLeaveDays += leave;

      if (w.adSoyad == _selectedWorker) {
        _selectedWorkerWorkedDays = worked;
        _selectedWorkerLeaveDays = leave;
      }

      _workerMonthlyStats.add({
        'name': w.adSoyad,
        'days': worked,
        'leave': leave,
        'color': colors[i % colors.length],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('İşçi Analizleri'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty 
            ? const Center(child: Text('Henüz işçi kaydı bulunamadı.'))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInternalSelector(),
                      const SizedBox(height: 12),
                      _buildDateSelector(),
                      const SizedBox(height: 24),
                      _buildHeaderCard(),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Text(
                            'ÇALIŞMA SAATLERİ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF011627),
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLineChart(),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Text(
                            'İŞÇİ BAZLI ÇALIŞMA GÜNLERİ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF011627),
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${DateFormat('MMMM').format(_startDate)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildBarChart(),
                      const SizedBox(height: 40),
                      const Text(
                        'GENEL VERİMLİLİK',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF011627),
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPieChart(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildInternalSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedWorker,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2EC4B6)),
          isExpanded: true,
          items: _workers.map((e) => e.adSoyad)
              .map<DropdownMenuItem<String>>((String str) => DropdownMenuItem<String>(
                    value: str,
                    child: Text(str, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedWorker = val;
                _processData();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF2EC4B6), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${DateFormat('dd MMMM yyyy', 'tr').format(_startDate)} - ${DateFormat('dd MMMM yyyy', 'tr').format(_endDate)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    String subtitle = 'Toplam $_selectedWorkerWorkedDays gün çalışma, $_selectedWorkerLeaveDays gün izin kaydedildi.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF011627), Color(0xFF011627)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF011627).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2EC4B6).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_rounded, color: Color(0xFF2EC4B6), size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedWorker Analizi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 24, left: 12, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF1F3F5), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                  int idx = value.toInt();
                  if (idx >= 0 && idx < _lineSpots.length) {
                    final date = _startDate.add(Duration(days: idx));
                    // Only show title for every few days if range is large
                    bool shouldShow = true;
                    if (_lineSpots.length > 7) {
                      shouldShow = idx % (_lineSpots.length ~/ 5 + 1) == 0 || idx == _lineSpots.length - 1;
                    }
                    
                    if (!shouldShow) return const Text('');

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _lineSpots.length <= 7 ? days[date.weekday - 1] : DateFormat('dd.MM').format(date), 
                        style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0, maxX: (_lineSpots.length - 1).toDouble().clamp(0, 1000), 
          minY: 0, 
          maxY: 25,
          lineBarsData: [
            LineChartBarData(
              spots: _lineSpots,
              isCurved: true,
              color: const Color(0xFF2EC4B6),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [const Color(0xFF2EC4B6).withOpacity(0.2), const Color(0xFF2EC4B6).withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 31,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < _workerMonthlyStats.length) {
                    final name = _workerMonthlyStats[value.toInt()]['name'].split(' ')[0];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF495057))),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _workerMonthlyStats.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value['days'].toDouble(),
                  color: e.value['color'],
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_totalWorkedDays == 0 && _totalLeaveDays == 0) {
      return const SizedBox(height: 200, child: Center(child: Text('Bu ay henüz veri girişi yok.')));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(
              color: const Color(0xFF2EC4B6),
              value: _totalWorkedDays.toDouble(),
              title: 'Çalışma\n$_totalWorkedDays',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: const Color(0xFFE71D36).withOpacity(0.7),
              value: _totalLeaveDays.toDouble(),
              title: 'İzin/Rapor\n$_totalLeaveDays',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
