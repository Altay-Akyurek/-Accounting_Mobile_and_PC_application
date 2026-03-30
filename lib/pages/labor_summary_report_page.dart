import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../services/database_helper.dart';
import '../models/worker.dart';
import '../models/project.dart';
import '../services/worker_export_service.dart';
import '../services/premium_manager.dart';
import '../widgets/banner_ad_widget.dart';

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
  double _totalCost = 0;
  double _totalHours = 0;
  Map<int, double> _workerTotalCosts = {};
  Map<int, double> _workerTotalHours = {};
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _currentStatus = "";
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Give UI a chance to show the spinner
    await Future.delayed(Duration.zero);
    
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

      // Perform heavy calculations in a separate isolate
      final totals = await compute(_calculateTotalsInIsolate, {
        'puantajlar': puantajList,
        'workerMap': wMap,
      });

      setState(() {
        _puantajlar = puantajList;
        _workerMap = wMap;
        _projectNames = pMap;
        _totalCost = totals['totalCost']!;
        _totalHours = totals['totalHours']!;
        _workerTotalCosts = totals['workerTotalCosts']!;
        _workerTotalHours = totals['workerTotalHours']!;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Heavy calculation logic for Isolate
  static Map<String, dynamic> _calculateTotalsInIsolate(Map<String, dynamic> params) {
    final List<Puantaj> puantajList = params['puantajlar'];
    final Map<int, Worker> wMap = params['workerMap'];
    
    // Sort
    puantajList.sort((a, b) => b.tarih.compareTo(a.tarih));

    double tCost = 0;
    double tHours = 0;
    Map<int, double> wTCost = {};
    Map<int, double> wTHours = {};

    for (var p in puantajList) {
      final worker = wMap[p.workerId];
      double cost = 0;
      if (worker != null) {
        // Simple cost calculation (static logic replicate)
        double hourlyRate = 0;
        if (worker.maasTuru == WorkerSalaryType.saatlik) {
          hourlyRate = worker.maasTutari;
        } else if (worker.maasTuru == WorkerSalaryType.gunluk) {
          hourlyRate = worker.maasTutari / 8;
        } else if (worker.maasTuru == WorkerSalaryType.aylik) {
          hourlyRate = worker.maasTutari / 240;
        }
        cost = (p.saat * hourlyRate) + (p.mesai * hourlyRate * 1.5);
        
        tCost += cost;
        wTCost[p.workerId] = (wTCost[p.workerId] ?? 0) + cost;
      }
      tHours += p.saat;
      wTHours[p.workerId] = (wTHours[p.workerId] ?? 0) + p.saat;
    }

    return {
      'totalCost': tCost,
      'totalHours': tHours,
      'workerTotalCosts': wTCost,
      'workerTotalHours': wTHours,
    };
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
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.currency(
      locale: locale,
      symbol: locale == 'tr' ? '₺' : '\$',
      decimalDigits: 2,
    ).format(tutar);
  }

  @override
  Widget build(BuildContext context) {
    // Grouping
    Map<int, List<Puantaj>> groupedPuantaj = {};
    for (var p in _puantajlar) {
      groupedPuantaj.putIfAbsent(p.workerId, () => []).add(p);
    }

    final sortedWorkerIds = groupedPuantaj.keys.toList()
      ..sort((a, b) => (_workerMap[a]?.adSoyad ?? '').compareTo(_workerMap[b]?.adSoyad ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search,
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.laborSummaryReport_caps,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textScaleFactor: 1.0,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: AppLocalizations.of(context)!.dateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'pdf' || value == 'excel') {
                if (PremiumManager.instance.checkPremium(context)) {
                    setState(() {
                      _currentStatus = AppLocalizations.of(context)!.preparing_ellipsis;
                      _isCancelled = false;
                    });
                    _showLoadingDialog();
                    try {
                        final l10n = AppLocalizations.of(context)!;
                        if (value == 'pdf') {
                          await WorkerExportService.exportToPDF(
                            l10n: l10n,
                            startDate: _startDate,
                            endDate: _endDate,
                            puantajlar: _puantajlar,
                            workerMap: _workerMap,
                            projectNames: _projectNames,
                            totalCost: _totalCost,
                            totalHours: _totalHours,
                            onStatusUpdate: (status) {
                              if (mounted && !_isCancelled) {
                                setState(() {
                                  _currentStatus = status;
                                });
                              }
                            },
                            isCancelled: () => _isCancelled,
                          );
                        } else {
                          await WorkerExportService.exportToExcel(
                            l10n: l10n,
                            startDate: _startDate,
                            endDate: _endDate,
                            puantajlar: _puantajlar,
                            workerMap: _workerMap,
                            projectNames: _projectNames,
                          );
                        }
                    } catch (e) {
                        if (mounted && !_isCancelled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${AppLocalizations.of(context)!.error_colon}$e')),
                          );
                        }
                    } finally {
                        if (mounted) Navigator.of(context).pop();
                    }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.downloadPDF),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.downloadExcel),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(_totalCost, _totalHours),
          _buildWorkerList(groupedPuantaj, sortedWorkerIds, _totalHours),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildHeader(double totalCost, double totalHours) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF011627), Color(0xFF013354)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(_startDate)} - ${DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(_endDate)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: AppLocalizations.of(context)!.totalCost,
                  value: _formatPara(totalCost),
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF2EC4B6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: AppLocalizations.of(context)!.totalWork_caps,
                  value: AppLocalizations.of(context)!.xHoursWork(totalHours),
                  icon: Icons.timer_rounded,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList(Map<int, List<Puantaj>> groupedPuantaj, List<int> sortedWorkerIds, double totalHours) {
    // Filter by search query
    final filteredIds = sortedWorkerIds.where((id) {
      final worker = _workerMap[id];
      if (worker == null) return false;
      return worker.adSoyad.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredIds.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty 
                  ? AppLocalizations.of(context)!.noRecordFoundInRange 
                  : AppLocalizations.of(context)!.noRecordFound,
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              itemCount: filteredIds.length,
              itemBuilder: (context, index) {
                final workerId = filteredIds[index];
                final worker = _workerMap[workerId];
                final puantajs = groupedPuantaj[workerId]!;
                
                final workerTotalHours = _workerTotalHours[workerId] ?? 0.0;
                final workerTotalCost = _workerTotalCosts[workerId] ?? 0.0;
                double contribution = totalHours > 0 ? workerTotalHours / totalHours : 0;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        splashColor: const Color(0xFF011627).withOpacity(0.05),
                        highlightColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF011627).withOpacity(0.1),
                        child: Text(
                          (worker != null && worker.adSoyad.isNotEmpty 
                              ? worker.adSoyad[0] 
                              : '?'),
                          style: const TextStyle(color: Color(0xFF011627), fontWeight: FontWeight.w900),
                        ),
                      ),
                      title: Text(
                        worker?.adSoyad ?? AppLocalizations.of(context)!.unknown,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF011627)),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          FittedBox(
                            child: Text(
                              '${AppLocalizations.of(context)!.total}: ${AppLocalizations.of(context)!.xHours(workerTotalHours)} | ${_formatPara(workerTotalCost)}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: contribution,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                contribution > 0.5 ? const Color(0xFF2EC4B6) : Colors.blue.shade400,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf, size: 22, color: Color(0xFFE71D36)),
                            onPressed: () async {
                              if (PremiumManager.instance.checkPremium(context)) {
                                setState(() {
                                  _currentStatus = AppLocalizations.of(context)!.preparing_ellipsis;
                                  _isCancelled = false;
                                });
                                _showLoadingDialog();
                                try {
                                  final l10n = AppLocalizations.of(context)!;
                                  await WorkerExportService.exportToPDF(
                                    l10n: l10n,
                                    startDate: _startDate,
                                    endDate: _endDate,
                                    puantajlar: puantajs,
                                    workerMap: _workerMap,
                                    projectNames: _projectNames,
                                    totalCost: workerTotalCost,
                                    totalHours: workerTotalHours,
                                    filterWorkerId: workerId,
                                    onStatusUpdate: (status) {
                                      if (mounted && !_isCancelled) {
                                        setState(() {
                                          _currentStatus = status;
                                        });
                                      }
                                    },
                                    isCancelled: () => _isCancelled,
                                  );
                                } catch (e) {
                                  if (mounted && !_isCancelled) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${AppLocalizations.of(context)!.error_colon}$e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) Navigator.of(context).pop();
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.table_chart, size: 22, color: Color(0xFF2EC4B6)),
                            onPressed: () async {
                              if (PremiumManager.instance.checkPremium(context)) {
                                _showLoadingDialog();
                                try {
                                  final l10n = AppLocalizations.of(context)!;
                                  await WorkerExportService.exportToExcel(
                                    l10n: l10n,
                                    startDate: _startDate,
                                    endDate: _endDate,
                                    puantajlar: puantajs,
                                    workerMap: _workerMap,
                                    projectNames: _projectNames,
                                    filterWorkerId: workerId,
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Hata: $e')),
                                  );
                                } finally {
                                  if (mounted) Navigator.of(context).pop();
                                }
                              }
                            },
                          ),
                          const Icon(Icons.expand_more_rounded, color: Colors.grey),
                        ],
                      ),
                      children: [
                        const Divider(height: 1, indent: 24, endIndent: 24),
                        _buildTimelineDetail(puantajs, worker),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                );
              },
            ),
    );
  }

  Widget _buildTimelineDetail(List<Puantaj> puantajs, Worker? worker) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: puantajs.asMap().entries.map((entry) {
          final index = entry.key;
          final p = entry.value;
          final isLast = index == puantajs.length - 1;
          
          double cost = 0;
          if (worker != null) {
            cost = DatabaseHelper.instance.calculateLaborCost(p, worker);
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline Line and Dot
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EC4B6).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2EC4B6), width: 2),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                // Content Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(p.tarih),
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF011627)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (p.mesai > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '+${p.mesai} ${l10n.tableMesai_caps}',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _projectNames[p.projectId] ?? '-',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FittedBox(
                              child: Text(
                                _formatPara(cost),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFFE71D36)),
                                textScaleFactor: 1.0,
                              ),
                            ),
                            FittedBox(
                              child: Text(
                                '${p.saat} ${l10n.hour_caps}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                textScaleFactor: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF011627).withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 2),
                    tween: Tween(begin: 0.0, end: 1.0),
                    onEnd: () {},
                    builder: (context, value, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF2EC4B6).withOpacity(0.2),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2EC4B6)),
                            ),
                          ),
                          const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFFE71D36),
                            size: 35,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const _AnimatedProcessingText(),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Text(
                        _currentStatus.isEmpty ? AppLocalizations.of(context)!.reportPreparing_ellipsis : _currentStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isCancelled = true;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.cancel_caps_upper,
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedProcessingText extends StatefulWidget {
  const _AnimatedProcessingText();

  @override
  State<_AnimatedProcessingText> createState() => _AnimatedProcessingTextState();
}

class _AnimatedProcessingTextState extends State<_AnimatedProcessingText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        AppLocalizations.of(context)!.processing,
        style: const TextStyle(
          color: Color(0xFF011627),
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.none,
          fontSize: 20,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Simple feedback
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                FittedBox(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
