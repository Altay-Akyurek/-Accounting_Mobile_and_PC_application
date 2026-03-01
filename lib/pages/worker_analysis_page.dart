import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
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
      bool isIzinsiz = false;

      final dayPuantajs = _allPuantajs.where((Puantaj p) => 
        p.workerId == worker.id && 
        p.tarih.year == date.year && p.tarih.month == date.month && p.tarih.day == date.day
      );
      
      for (Puantaj p in dayPuantajs) {
        if (p.status == PuantajStatus.normal || 
            [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)) {
          dailyTotal += p.saat + p.mesai;
        } else if (p.status == PuantajStatus.izinsiz) {
          isIzinsiz = true;
        }
      }
      
      // If izinsiz, show as negative dip
      if (isIzinsiz) {
        _lineSpots.add(FlSpot(i.toDouble(), -5));
      } else {
        _lineSpots.add(FlSpot(i.toDouble(), dailyTotal));
      }
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
      
      final Set<String> workedDates = {};
      final Set<String> leaveDates = {};

      for (var p in workerPuantajs) {
        final dateKey = "${p.tarih.year}-${p.tarih.month}-${p.tarih.day}";
        if (p.status == PuantajStatus.normal) {
          workedDates.add(dateKey);
        } else if ([PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli, PuantajStatus.izinsiz].contains(p.status)) {
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
        title: Text(AppLocalizations.of(context)!.workerAnalysis),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty 
            ? Center(child: Text(AppLocalizations.of(context)!.noWorkerFound))
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
                          Text(
                            AppLocalizations.of(context)!.performanceOverTime,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF011627),
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${DateFormat('dd MMM', Localizations.localeOf(context).toString()).format(_startDate)} - ${DateFormat('dd MMM', Localizations.localeOf(context).toString()).format(_endDate)}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLineChart(),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.workerDistribution,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF011627),
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMMM', Localizations.localeOf(context).toString()).format(_startDate),
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildBarChart(),
                      const SizedBox(height: 48),
                      Text(
                        AppLocalizations.of(context)!.attendanceSummary,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF011627),
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                '${DateFormat('dd MMMM yyyy', Localizations.localeOf(context).toString()).format(_startDate)} - ${DateFormat('dd MMMM yyyy', Localizations.localeOf(context).toString()).format(_endDate)}',
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
    String subtitle = AppLocalizations.of(context)!.workerAnalysisSubtitle(_selectedWorkerWorkedDays, _selectedWorkerLeaveDays);

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
                  AppLocalizations.of(context)!.workerAnalysisDetail(_selectedWorker),
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
                  final days = [
                    AppLocalizations.of(context)!.monday_short,
                    AppLocalizations.of(context)!.tuesday_short,
                    AppLocalizations.of(context)!.wednesday_short,
                    AppLocalizations.of(context)!.thursday_short,
                    AppLocalizations.of(context)!.friday_short,
                    AppLocalizations.of(context)!.saturday_short,
                    AppLocalizations.of(context)!.sunday_short
                  ];
                  int idx = value.toInt();
                  if (idx >= 0 && idx < _lineSpots.length) {
                    final date = _startDate.add(Duration(days: idx));
                    bool shouldShow = true;
                    if (_lineSpots.length > 7) {
                      shouldShow = idx % (_lineSpots.length ~/ 5 + 1) == 0 || idx == _lineSpots.length - 1;
                    }
                    
                    if (!shouldShow) return const Text('');

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _lineSpots.length <= 7 ? days[date.weekday - 1] : DateFormat('dd.MM', Localizations.localeOf(context).toString()).format(date), 
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
          minY: -10, 
          maxY: 25,
          lineBarsData: [
            // Base Zero Line
            LineChartBarData(
              spots: [FlSpot(0, 0), FlSpot(_lineSpots.length.toDouble(), 0)],
              isCurved: false,
              color: Colors.grey.withOpacity(0.2),
              barWidth: 1,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: _lineSpots,
              isCurved: true,
              color: const Color(0xFF2EC4B6),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (spot.y < 0) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.red,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  }
                  return FlDotCirclePainter(radius: 0);
                },
              ),
              gradient: LinearGradient(
                colors: [const Color(0xFF2EC4B6), const Color(0xFF2EC4B6)],
              ),
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
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(y: 0, color: Colors.black12, strokeWidth: 1),
            ],
          ),
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
      return SizedBox(height: 200, child: Center(child: Text(AppLocalizations.of(context)!.noDataEntryThisMonth)));
    }

    final double total = (_totalWorkedDays + _totalLeaveDays).toDouble();
    final double productivity = total > 0 ? (_totalWorkedDays / total * 100) : 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 6,
              centerSpaceRadius: 65,
              startDegreeOffset: -90,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFF2EC4B6),
                  value: _totalWorkedDays.toDouble(),
                  title: '',
                  radius: 22,
                  badgeWidget: _buildPieBadge(Icons.check_circle_rounded, const Color(0xFF2EC4B6)),
                  badgePositionPercentageOffset: 1.3,
                ),
                PieChartSectionData(
                  color: const Color(0xFFE71D36).withOpacity(0.8),
                  value: _totalLeaveDays.toDouble(),
                  title: '',
                  radius: 18,
                  badgeWidget: _buildPieBadge(Icons.cancel_rounded, const Color(0xFFE71D36)),
                  badgePositionPercentageOffset: 1.3,
                ),
              ],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '%${productivity.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF011627),
                letterSpacing: -1,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.productivity_caps,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPieBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
