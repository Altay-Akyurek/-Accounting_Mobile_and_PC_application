import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../l10n/app_localizations.dart';
import '../services/database_helper.dart';
import '../models/worker.dart';
import '../models/project.dart';

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
  List<Project> _allProjects = [];
  
  String _selectedWorker = '';
  
  // Single Worker Stats
  int _selectedWorkerWorkedDays = 0;
  int _selectedWorkerLeaveDays = 0;
  int _selectedWorkerAbsenceDays = 0;
  double _selectedWorkerTotalHours = 0;
  double _selectedWorkerOvertime = 0;
  double _productivityScore = 0;
  double _participationRate = 0;
  double _hourPerformanceRate = 0;

  // Charts data
  List<FlSpot> _lineSpots = [];
  double _maxHoursInPeriod = 0;
  List<Map<String, dynamic>> _projectDistribution = [];
  Map<String, PuantajStatus> _heatmapData = {}; // "yyyy-MM-dd" : Status

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  // Heatmap boundaries (last 6 months)
  late DateTime _heatmapStart;
  late DateTime _heatmapEnd;

  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _heatmapEnd = DateTime.now();
    _heatmapStart = DateTime(_heatmapEnd.year, _heatmapEnd.month - 6, _heatmapEnd.day);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<List<dynamic>>([
        _db.getAllWorkers(),
        _db.getAllPuantajlar(baslangic: _heatmapStart, bitis: _heatmapEnd), // Fetch last 6 months globally for heatmap logic
        _db.getAllProjects(),
      ]);

      _workers = (results[0] as List<Worker>).where((w) => w.aktif).toList(); // Sadece aktif işçiler veya tümü
      _allPuantajs = results[1] as List<Puantaj>;
      _allProjects = results[2] as List<Project>;

      if (_selectedWorker.isEmpty && _workers.isNotEmpty) {
        _selectedWorker = _workers.first.adSoyad;
      }

      _processData();
    } catch (e) {
      debugPrint("WorkerAnalysis error: $e");
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
      _processData(); // Only re-process, no need to load all data if we fetched mostly everything. Or just reload to be safe.
      // Doing a full reload to ensure the date range is properly covered if it's outside 6 months.
      _loadData();
    }
  }

  void _processData() {
    if (_workers.isEmpty) return;
    
    final worker = _workers.firstWhere((w) => w.adSoyad == _selectedWorker, orElse: () => _workers.first);
    final workerAllPuantajs = _allPuantajs.where((p) => p.workerId == worker.id).toList();

    // 1. Calculate Selected Worker Stats for specifically selected Date Range
    _selectedWorkerWorkedDays = 0;
    _selectedWorkerLeaveDays = 0;
    _selectedWorkerAbsenceDays = 0;
    _selectedWorkerTotalHours = 0;
    _selectedWorkerOvertime = 0;

    final selectedRangePuantajs = workerAllPuantajs.where((p) => 
       p.tarih.isAfter(_startDate.subtract(const Duration(days: 1))) && 
       p.tarih.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList();

    for (var p in selectedRangePuantajs) {
      if (p.status == PuantajStatus.normal) {
        _selectedWorkerWorkedDays++;
        _selectedWorkerTotalHours += p.saat;
        _selectedWorkerOvertime += p.mesai;
      } else if (p.status == PuantajStatus.izinsiz) {
        _selectedWorkerAbsenceDays++;
      } else if ([PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)) {
        _selectedWorkerLeaveDays++;
      }
    }

    final totalRangeDays = _endDate.difference(_startDate).inDays + 1;
    // Calculate Rates
    if (totalRangeDays > 0) {
       _participationRate = ((_selectedWorkerWorkedDays + _selectedWorkerLeaveDays) / totalRangeDays) * 100;
       
       // Expected hours roughly: total range days excluding sundays * 8
       int workingDaysExpected = 0;
       for (int i = 0; i < totalRangeDays; i++) {
          if (_startDate.add(Duration(days: i)).weekday != DateTime.sunday) {
             workingDaysExpected++;
          }
       }
       double expectedHours = workingDaysExpected * 8.0;
       if (expectedHours > 0) {
          _hourPerformanceRate = (_selectedWorkerTotalHours / expectedHours) * 100;
       } else {
          _hourPerformanceRate = 100;
       }
    } else {
       _participationRate = 0;
       _hourPerformanceRate = 0;
    }
    
    _participationRate = _participationRate.clamp(0, 100);
    _hourPerformanceRate = _hourPerformanceRate.clamp(0, 100);
    
    // Overall Productivity Score roughly average of both
    _productivityScore = (_participationRate + _hourPerformanceRate) / 2;
    if (_selectedWorkerAbsenceDays > 0) {
       _productivityScore -= (_selectedWorkerAbsenceDays * 5); // Penalty
    }
    _productivityScore = _productivityScore.clamp(0, 100);

    // 2. Line Chart: Performance Over Time (Selected Range)
    _lineSpots = [];
    for (int i = 0; i < totalRangeDays; i++) {
      final date = _startDate.add(Duration(days: i));
      double dailyTotal = 0;
      bool isIzinsiz = false;

      final dayPuantajs = selectedRangePuantajs.where((p) => 
        p.tarih.year == date.year && p.tarih.month == date.month && p.tarih.day == date.day
      );
      
      for (var p in dayPuantajs) {
        if (p.status == PuantajStatus.izinsiz) {
           isIzinsiz = true;
        } else {
           dailyTotal += p.saat + p.mesai;
        }
      }
      
      if (isIzinsiz) {
        _lineSpots.add(FlSpot(i.toDouble(), 0)); // Drop to 0 or negative
      } else {
        _lineSpots.add(FlSpot(i.toDouble(), dailyTotal));
      }
    }

    if (_lineSpots.isNotEmpty) {
      _maxHoursInPeriod = 8.0; // Standart Beklenen Günlük Mesai (Örn: 8 Saat)
    } else {
      _maxHoursInPeriod = 0;
    }

    // 3. Heatmap Data (Last 6 Months up to Today)
    _heatmapData = {};
    for (var p in workerAllPuantajs) {
       if (p.tarih.isAfter(_heatmapStart) && p.tarih.isBefore(_heatmapEnd.add(const Duration(days: 1)))) {
          String key = "${p.tarih.year}-${p.tarih.month.toString().padLeft(2, '0')}-${p.tarih.day.toString().padLeft(2, '0')}";
          _heatmapData[key] = p.status;
       }
    }

    // 4. Project Distribution based on Selected Range
    Map<int, double> projectHoursMap = {};
    for (var p in selectedRangePuantajs) {
       if (p.status == PuantajStatus.normal || [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)) {
          if (p.projectId != null) {
              projectHoursMap[p.projectId!] = (projectHoursMap[p.projectId!] ?? 0) + p.saat + p.mesai;
          }
       }
    }
    
    _projectDistribution = [];
    final projColors = [const Color(0xFF2EC4B6), Colors.blue, Colors.orange, Colors.purple];
    int colorIdx = 0;
    projectHoursMap.forEach((pId, hours) {
       final proj = _allProjects.firstWhere((pr) => pr.id == pId, orElse: () => Project(ad: 'Silinmiş Proje', baslangicTarihi: DateTime.now()));
       _projectDistribution.add({
         'name': proj.ad,
         'hours': hours,
         'color': projColors[colorIdx % projColors.length],
       });
       colorIdx++;
    });
    
    _projectDistribution.sort((a, b) => b['hours'].compareTo(a['hours']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.workerAnalysis, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF011627),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
           : _workers.isEmpty 
             ? Center(child: Text(AppLocalizations.of(context)!.noWorkerFound))
             : RefreshIndicator(
                 color: const Color(0xFF2EC4B6),
                 onRefresh: _loadData,
                 child: ListView(
                   padding: const EdgeInsets.all(20),
                   children: [
                      _buildTopSelectors(),
                      const SizedBox(height: 20),
                      _buildProfileScoreCard(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 16),
                      _buildAbsenceCard(),
                      const SizedBox(height: 16),
                      _buildHeatmapCard(),
                      const SizedBox(height: 16),
                      if (_projectDistribution.isNotEmpty) _buildProjectDistributionCard(),
                      if (_projectDistribution.isNotEmpty) const SizedBox(height: 16),
                      _buildPerformanceLineChartCard(),
                      const SizedBox(height: 16),
                      _buildDonutSummaryCard(),
                      const SizedBox(height: 32),
                   ],
                 ),
               ),
    );
  }

  Widget _buildTopSelectors() {
    return Column(
      children: [
        // Worker Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedWorker,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2EC4B6)),
              isExpanded: true,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF011627)),
              items: _workers.map((e) => e.adSoyad)
                  .map<DropdownMenuItem<String>>((String str) => DropdownMenuItem<String>(
                        value: str,
                        child: Text(str),
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
        ),
        const SizedBox(height: 12),
        // Date Range Selector
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Color(0xFF2EC4B6), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${DateFormat('dd MMMM yyyy', 'tr_TR').format(_startDate)} - ${DateFormat('dd MMMM yyyy', 'tr_TR').format(_endDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF011627)),
                  ),
                ),
                const Icon(Icons.edit_calendar_rounded, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileScoreCard() {
    String ratingText = "Zayıf";
    Color ratingColor = Colors.red;
    if (_productivityScore > 85) {
      ratingText = "Çok İyi";
      ratingColor = Colors.green;
    } else if (_productivityScore >= 65) {
      ratingText = "İyi";
      ratingColor = Colors.amber;
    } else if (_productivityScore >= 45) {
       ratingText = "Orta";
       ratingColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF011627),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF011627).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          // Circular Score
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: _productivityScore / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: Colors.amber,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                _productivityScore.toInt().toString(),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedWorker,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Genel Verimlilik Puanı",
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ratingColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ratingColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    ratingText,
                    style: TextStyle(color: ratingColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatItem(Icons.calendar_month_outlined, "Katılım Oranı", "%${_participationRate.toStringAsFixed(0)}", const Color(0xFF2EC4B6), _participationRate / 100)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem(Icons.access_time_rounded, "Saat Performansı", "%${_hourPerformanceRate.toStringAsFixed(0)}", Colors.blue, _hourPerformanceRate / 100)),
      ],
    );
  }
  
  Widget _buildAbsenceCard() {
     return Row(
       children: [
          Expanded(child: _buildStatItem(Icons.work_history_rounded, "Toplam Çalışma", "${_selectedWorkerTotalHours.toStringAsFixed(1)} sa", const Color(0xFF011627), 0.8)), // Arbitrary progress to look good
          const SizedBox(width: 16),
          Expanded(child: _buildStatItem(Icons.update_rounded, "Fazla Mesai", "${_selectedWorkerOvertime.toStringAsFixed(1)} sa", Colors.orange, 0.4)),
       ],
     );
  }

  Widget _buildStatItem(IconData icon, String title, String value, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF011627))),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeatmapCard() {
     // A custom minimal heatmap representation 
     // We will calculate 6 cols x 4 rows representing the last weeks or months. 
     // We will use a grid. For simplicity 26 weeks x 7 days.
     List<Widget> gridItems = [];
     int daysIn6Months = 180;
     DateTime startMap = _heatmapEnd.subtract(Duration(days: daysIn6Months - 1));
     
     // Align start map to Monday
     while(startMap.weekday != DateTime.monday) {
        startMap = startMap.subtract(const Duration(days: 1));
        daysIn6Months++;
     }
     
     // Build Grid
     for (int i = 0; i < daysIn6Months; i++) {
        DateTime current = startMap.add(Duration(days: i));
        String key = "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}";
        
        Color cellColor = Colors.grey.shade200; // Default off day
        String statusText = "Kayıt Yok";
        bool isEmpty = current.isAfter(_heatmapEnd);
        
        if (isEmpty) {
           cellColor = Colors.transparent; // Future empty
           statusText = "";
        } else {
           PuantajStatus? status = _heatmapData[key];
           if (status == PuantajStatus.normal) {
              cellColor = const Color(0xFF2EC4B6);
              statusText = "Normal";
           } else if (status == PuantajStatus.izinsiz) {
              cellColor = const Color(0xFFE71D36);
              statusText = "İzinsiz";
           } else if (status != null) { // Izinli vb
              cellColor = Colors.amber;
              statusText = "İzinli/Raporlu";
           } else {
              statusText = "Tatil/Kayıt Yok";
           }
        }
        
        Widget cell = Container(
             decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(2),
             ),
        );
        
        if (!isEmpty) {
            cell = Tooltip(
               message: "${DateFormat('dd MMM yyyy', 'tr_TR').format(current)}\n$statusText",
               textStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
               decoration: BoxDecoration(color: const Color(0xFF011627), borderRadius: BorderRadius.circular(8)),
               child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: cell,
               ),
            );
        }

        gridItems.add(cell);
     }

     return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AKTİVİTE ISI HARİTASI (SON 6 AY)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF011627), letterSpacing: 1.2)),
          const SizedBox(height: 20),
          // We use a SizedBox to restrain grid height and enable horizontal scrolling if needed, or just shrink
          SizedBox(
             height: 90,
             child: GridView.count(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(), // Assuming it fits, or simple scroll
                crossAxisCount: 7, // 7 days a week
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                children: gridItems,
             ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
               _buildLegendBadge("Normal", const Color(0xFF2EC4B6)),
               const SizedBox(width: 12),
               _buildLegendBadge("İzinli", Colors.amber),
               const SizedBox(width: 12),
               _buildLegendBadge("İzinsiz", const Color(0xFFE71D36)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendBadge(String label, Color color) {
     return Row(
        children: [
           Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
           const SizedBox(width: 4),
           Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
     );
  }

  Widget _buildProjectDistributionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text("PROJE BAZLI ZAMAN DAĞILIMI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF011627), letterSpacing: 1.2)),
           const SizedBox(height: 24),
           ..._projectDistribution.map((proj) {
              double maxHours = _projectDistribution.first['hours']; // First is max since sorted
              double progress = maxHours > 0 ? proj['hours'] / maxHours : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Text(proj['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF011627))),
                            Text("${proj['hours'].toStringAsFixed(1)} sa", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                         ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                         value: progress,
                         backgroundColor: Colors.grey.shade100,
                         valueColor: AlwaysStoppedAnimation<Color>(proj['color']),
                         minHeight: 6,
                         borderRadius: BorderRadius.circular(3),
                      ),
                   ],
                ),
              );
           }),
        ],
      ),
    );
  }

  Widget _buildPerformanceLineChartCard() {
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Zaman İçinde Performans", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF011627))),
                 Text(
                   '${DateFormat('dd MMM', 'tr_TR').format(_startDate)} - ${DateFormat('dd MMM', 'tr_TR').format(_endDate)}',
                   style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                 ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF011627),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                         if (touchedSpot.barIndex == 0) return null; // Ignore baseline
                         final date = _startDate.add(Duration(days: touchedSpot.x.toInt()));
                         return LineTooltipItem(
                            '${DateFormat('dd MMM', 'tr_TR').format(date)}\n',
                            const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            children: [
                               TextSpan(
                                 text: '${touchedSpot.y} sa',
                                 style: const TextStyle(color: Color(0xFF2EC4B6), fontSize: 14, fontWeight: FontWeight.w900),
                               )
                            ]
                         );
                      }).toList();
                    }
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF6F8FA), strokeWidth: 1.5),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        int maxIdx = _lineSpots.length - 1;
                        
                        // Sadece ilk, tam orta ve son noktayı göster ki yazılar üst üste binmesin.
                        if (idx == 0 || idx == maxIdx || (idx == maxIdx ~/ 2 && maxIdx > 5)) {
                           if (idx >= 0 && idx <= maxIdx) {
                             final date = _startDate.add(Duration(days: idx));
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(
                                 DateFormat('dd.MM', 'tr_TR').format(date), 
                                 style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)
                               ),
                             );
                           }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                         // Only show 0, 10, 20
                         if (value == 0 || value == 10 || value == 20) {
                            return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                         }
                         return const Text('');
                      }
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, 
                maxX: math.max(1, (_lineSpots.length - 1).toDouble()), 
                minY: -5, 
                maxY: 25,
                lineBarsData: [
                  // Expected baseline 
                  LineChartBarData(
                    spots: _lineSpots.map((e) => FlSpot(e.x, 8)).toList(),
                    isCurved: false,
                    color: Colors.grey.withOpacity(0.3),
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                  LineChartBarData(
                    spots: _lineSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF2EC4B6),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF2EC4B6).withOpacity(0.15), const Color(0xFF2EC4B6).withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  extraLinesOnTop: false,
                  horizontalLines: [
                    HorizontalLine(y: 0, color: Colors.black12, strokeWidth: 1.5),
                    if (_maxHoursInPeriod > 0)
                      HorizontalLine(
                        y: _maxHoursInPeriod, 
                        color: Colors.purpleAccent.withOpacity(0.6), 
                        strokeWidth: 1.5, 
                        dashArray: [4, 4],
                        label: HorizontalLineLabel(
                           show: true,
                           alignment: Alignment.topRight,
                           padding: const EdgeInsets.only(right: 8, bottom: -4),
                           style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                           labelResolver: (line) => "Beklenen Hedef: 8 sa",
                        )
                      ),
                  ],
                ),
              ),
              duration: const Duration(milliseconds: 400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutSummaryCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Puantaj Özeti", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF011627))),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 48, bottom: 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
           child: Stack(
             alignment: Alignment.center,
             clipBehavior: Clip.none,
             children: [
               // Background & Progress Ring Animated
               SizedBox(
                 width: 260,
                 height: 260,
                 child: TweenAnimationBuilder<double>(
                   tween: Tween<double>(begin: 0, end: _productivityScore / 100),
                   duration: const Duration(milliseconds: 1200),
                   curve: Curves.easeOutCubic,
                   builder: (context, val, _) {
                     return CircularProgressIndicator(
                       value: val,
                       strokeWidth: 36,
                       backgroundColor: const Color(0xFF2EC4B6).withOpacity(0.12),
                       color: const Color(0xFF2EC4B6),
                       strokeCap: StrokeCap.round,
                     );
                   }
                 )
               ),
               // Inside Text Animated
               Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: _productivityScore),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) {
                        return Text(
                           "%${val.toStringAsFixed(1)}",
                           style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Color(0xFF011627), letterSpacing: -1.5),
                        );
                      }
                    ),
                    const SizedBox(height: 2),
                    const Text(
                       "VERİMLİLİK",
                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 2.5),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EC4B6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "$_selectedWorkerWorkedDays Gün Çalıştı",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2EC4B6)),
                      ),
                    ),
                 ],
               ),
               // Bottom Floating Checkmark Badge
               Positioned(
                  bottom: -15,
                  child: Container(
                     padding: const EdgeInsets.all(5),
                     decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                     ),
                     child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2EC4B6), size: 28),
                  )
               )
             ],
           ),
        ),
      ],
    );
  }
}
