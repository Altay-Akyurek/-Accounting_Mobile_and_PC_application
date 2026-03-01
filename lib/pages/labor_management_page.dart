import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/worker.dart';
import '../models/cari_hesap.dart';
import '../models/project.dart';
import '../services/database_helper.dart';
import '../services/language_service.dart';
import 'worker_documents_page.dart';
import '../widgets/banner_ad_widget.dart';

class LaborManagementPage extends StatefulWidget {
  const LaborManagementPage({super.key});

  @override
  State<LaborManagementPage> createState() => _LaborManagementPageState();
}

class _LaborManagementPageState extends State<LaborManagementPage> {
  List<Worker> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() => _isLoading = true);
    final workers = await DatabaseHelper.instance.getAllWorkers();
    setState(() {
      _workers = workers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.personnelTracking.toUpperCase()),
      ),
      body: Column(
        children: [
          _buildExecutiveBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _workers.isEmpty
                    ? _buildEmptyState()
                    : _buildWorkerGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWorkerDialog,
        icon: const Icon(Icons.add_moderator_rounded),
        label: Text(AppLocalizations.of(context)!.workerRegistration.toUpperCase()),
        backgroundColor: const Color(0xFF011627),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildExecutiveBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF011627),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF011627).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_ind_rounded, color: Color(0xFF2EC4B6), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.fieldPersonnelManagement, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(AppLocalizations.of(context)!.attendanceAndSalaryTracking, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showSummaryDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2EC4B6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(AppLocalizations.of(context)!.getSummary.toUpperCase(), style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerGrid() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _workers.length,
      itemBuilder: (context, index) {
        final worker = _workers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              if (!worker.aktif)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.statusDismissed.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: const Color(0xFF011627).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_pin_rounded, color: Color(0xFF011627)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.adSoyad,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            decoration: worker.aktif ? null : TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          worker.pozisyon ?? AppLocalizations.of(context)!.fieldPersonnel,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (worker.aktif)
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () => _showPuantajCalendar(worker),
                            icon: const Icon(Icons.calendar_month_rounded, size: 14),
                            label: Text(AppLocalizations.of(context)!.attendance.toUpperCase(), style: const TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF011627),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (val) {
                          if (val == 'dismiss') {
                            _showDismissDialog(worker);
                          } else if (val == 'documents') {
                            _showDocumentsDialog(worker);
                          } else if (val == 'delete') {
                            _showDeleteDialog(worker);
                          }
                        },
                        itemBuilder: (context) => [
                          if (worker.aktif) PopupMenuItem(value: 'dismiss', child: Text(AppLocalizations.of(context)!.dismissWorker)),
                          PopupMenuItem(value: 'documents', child: Text(AppLocalizations.of(context)!.documents)),
                          if (!worker.aktif) PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.deletePermanently, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ],
          ),
        );
      },
    );
  }

  void _showDismissDialog(Worker worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dismissWorker),
        content: Text('${worker.adSoyad} ${AppLocalizations.of(context)!.dismissConfirmNote}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel.toUpperCase())),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.dismissWorker(worker.id!, DateTime.now());
              if (mounted) {
                Navigator.pop(context);
                _loadWorkers();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.workerDismissedInfo)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.dismissWorker.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Worker worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePermanently),
        content: Text('${worker.adSoyad} ${AppLocalizations.of(context)!.deleteWorkerConfirmNote}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel.toUpperCase())),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteWorker(worker.id!);
              if (mounted) {
                Navigator.pop(context);
                _loadWorkers();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.workerDeletedInfo)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deletePermanently.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showDocumentsDialog(Worker worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerDocumentsPage(worker: worker),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.personnelListEmpty, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    final posController = TextEditingController();
    final salaryController = TextEditingController();
    WorkerSalaryType selectedType = WorkerSalaryType.gunluk;
    bool addAsCari = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.newWorkerCard, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF011627))),
                const SizedBox(height: 24),
                TextField(controller: nameController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fullName)),
                const SizedBox(height: 16),
                TextField(controller: posController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.dutyPosition)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: salaryController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.salaryAmount))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<WorkerSalaryType>(
                        value: selectedType,
                        items: [
                          DropdownMenuItem(value: WorkerSalaryType.gunluk, child: Text(AppLocalizations.of(context)!.daily)),
                          DropdownMenuItem(value: WorkerSalaryType.aylik, child: Text(AppLocalizations.of(context)!.monthly)),
                          DropdownMenuItem(value: WorkerSalaryType.saatlik, child: Text(AppLocalizations.of(context)!.hourly)),
                        ],
                        onChanged: (v) => setModalState(() => selectedType = v!),
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.salaryType),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: addAsCari,
                  onChanged: (v) => setModalState(() => addAsCari = v ?? false),
                  title: Text(AppLocalizations.of(context)!.saveAsCariAccount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(AppLocalizations.of(context)!.requiredForSalaryPayments, style: const TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: const Color(0xFF2EC4B6),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        int? linkedCariId;
                        if (addAsCari) {
                          linkedCariId = await DatabaseHelper.instance.insertCariHesap(CariHesap(unvan: nameController.text, bakiye: 0));
                        }
                        
                        final w = Worker(
                          adSoyad: nameController.text,
                          pozisyon: posController.text,
                          maasTutari: double.tryParse(salaryController.text) ?? 0.0,
                          maasTuru: selectedType,
                          baslangicTarihi: DateTime.now(),
                          cariHesapId: linkedCariId,
                        );
                        await DatabaseHelper.instance.insertWorker(w);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _loadWorkers();
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.completeRegistration.toUpperCase()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPuantajCalendar(Worker worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AttendanceCalendar(worker: worker),
    );
  }

  void _showSummaryDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final summary = await DatabaseHelper.instance.getPersonnelSummary();

    if (mounted) {
      Navigator.pop(context); // Close loading
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.personnelGeneralSummary, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF011627))),
              const SizedBox(height: 24),
              _buildSummaryItem(AppLocalizations.of(context)!.totalPersonnel, summary['total'].toString(), Icons.people_rounded),
              _buildSummaryItem(AppLocalizations.of(context)!.activePersonnel, summary['active'].toString(), Icons.check_circle_outline_rounded, color: Colors.green),
              _buildSummaryItem(AppLocalizations.of(context)!.dismissedPersonnel, summary['dismissed'].toString(), Icons.exit_to_app_rounded, color: Colors.orange),
              const Divider(height: 32),
              _buildSummaryItem(AppLocalizations.of(context)!.totalAccrued, NumberFormat.currency(
                locale: Localizations.localeOf(context).toString(),
                symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : r'$',
              ).format(summary['accrued']), Icons.work_history_rounded),
              _buildSummaryItem(AppLocalizations.of(context)!.totalPaid, NumberFormat.currency(
                locale: Localizations.localeOf(context).toString(),
                symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : r'$',
              ).format(summary['paid']), Icons.payments_rounded, color: Colors.blue),
              _buildSummaryItem(AppLocalizations.of(context)!.remainingDebtBalance, NumberFormat.currency(
                locale: Localizations.localeOf(context).toString(),
                symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : r'$',
              ).format(summary['balance']), Icons.account_balance_wallet_rounded, 
                color: (summary['balance'] as double) > 0 ? Colors.red : Colors.green),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF011627)),
                  child: Text(AppLocalizations.of(context)!.close.toUpperCase()),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color ?? const Color(0xFF011627), fontSize: 16)),
        ],
      ),
    );
  }
}

class _AttendanceCalendar extends StatefulWidget {
  final Worker worker;
  const _AttendanceCalendar({required this.worker});

  @override
  State<_AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<_AttendanceCalendar> {
  DateTime _viewDate = DateTime.now();
  Map<String, Puantaj> _attendance = {}; // Key: "yyyy-MM-dd"
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  String _dateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    final start = DateTime(_viewDate.year, _viewDate.month, 1);
    final end = DateTime(_viewDate.year, _viewDate.month + 1, 0);
    
    // Fetch 6 extra days to calculate streaks for Sundays at month start
    final fetchStart = start.subtract(const Duration(days: 6));

    final results = await Future.wait([
      DatabaseHelper.instance.getPuantajByWorkerId(widget.worker.id!, fetchStart, end),
      DatabaseHelper.instance.getAllProjects(),
    ]);
    
    final list = results[0] as List<Puantaj>;
    final projects = results[1] as List<Project>;
    
    Map<String, Puantaj> map = {};
    for (var p in list) {
      map[_dateKey(p.tarih)] = p;
    }
    
    setState(() {
      _attendance = map;
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _showPuantajEditDialog(int day) async {
    final date = DateTime(_viewDate.year, _viewDate.month, day);
    final existingPuantaj = _attendance[_dateKey(date)];
    
    final hourController = TextEditingController(text: existingPuantaj?.saat.toString() ?? '8');
    final mesaiController = TextEditingController(text: existingPuantaj?.mesai.toString() ?? '0');
    final noteController = TextEditingController(text: existingPuantaj?.aciklama ?? '');
    int? selectedProjectId = existingPuantaj?.projectId;
    PuantajStatus selectedStatus = existingPuantaj?.status ?? PuantajStatus.normal;

    double calculateRealTimeCost() {
      if (selectedStatus == PuantajStatus.izinsiz) return 0;
      
      double maas = widget.worker.maasTutari;
      double hRate = 0;
      if (widget.worker.maasTuru == WorkerSalaryType.saatlik) hRate = maas;
      else if (widget.worker.maasTuru == WorkerSalaryType.gunluk) hRate = maas / 8;
      else if (widget.worker.maasTuru == WorkerSalaryType.aylik) hRate = maas / 240;

      double hrs = double.tryParse(hourController.text) ?? 0;
      double ms = double.tryParse(mesaiController.text) ?? 0;
      
      return (hrs * hRate) + (ms * hRate * 1.5);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentCost = calculateRealTimeCost();
          
          double maas = widget.worker.maasTutari;
          double hRate = 0;
          if (widget.worker.maasTuru == WorkerSalaryType.saatlik) hRate = maas;
          else if (widget.worker.maasTuru == WorkerSalaryType.gunluk) hRate = maas / 8;
          else if (widget.worker.maasTuru == WorkerSalaryType.aylik) hRate = maas / 240;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${DateFormat('dd MMMM yyyy EEEE', Localizations.localeOf(context).toString()).format(date)} - ${AppLocalizations.of(context)!.attendance}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Hesaplama Bilgi Kutusu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF011627).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${AppLocalizations.of(context)!.hourlyRate}:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(NumberFormat.currency(
                              locale: Localizations.localeOf(context).toString(),
                              symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : r'$',
                            ).format(hRate), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${AppLocalizations.of(context)!.overtimeHourly} (1.5x):', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(NumberFormat.currency(
                              locale: Localizations.localeOf(context).toString(),
                              symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : r'$',
                            ).format(hRate * 1.5), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${AppLocalizations.of(context)!.calculatedAmount.toUpperCase()}:', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF011627))),
                            ValueListenableBuilder<Locale>(
                              valueListenable: LanguageService.instance.localeNotifier,
                              builder: (context, locale, _) {
                                return Text(
                                  NumberFormat.currency(
                                    locale: locale.toString(),
                                    symbol: locale.toString() == 'tr' ? '₺' : r'$',
                                  ).format(currentCost),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2EC4B6)),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hourController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.workingHours,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: mesaiController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.overtimeHours,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                   Text(
                    AppLocalizations.of(context)!.selectStatus.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PuantajStatus.values.map((status) {
                        String label = '';
                        switch (status) {
                          case PuantajStatus.normal: label = AppLocalizations.of(context)!.normal; break;
                          case PuantajStatus.izinli: label = AppLocalizations.of(context)!.onLeave; break;
                          case PuantajStatus.raporlu: label = AppLocalizations.of(context)!.onReport; break;
                          case PuantajStatus.mazeretli: label = AppLocalizations.of(context)!.onExcuse; break;
                          case PuantajStatus.izinsiz: label = AppLocalizations.of(context)!.unauthorized; break;
                        }
                        final isSelected = selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedStatus = status;
                                  // İzinsiz ise saatleri sıfırlayabiliriz ama kullanıcı kalsın diyebilir
                                });
                              }
                            },
                            selectedColor: const Color(0xFF011627),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF011627),
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.descriptionNote,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedProjectId,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(AppLocalizations.of(context)!.noProjectSelected),
                      ),
                      ..._projects.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.ad),
                      )),
                    ],
                    onChanged: (v) => setModalState(() => selectedProjectId = v),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.relatedProject,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final p = Puantaj(
                          id: existingPuantaj?.id,
                          workerId: widget.worker.id!,
                          tarih: date,
                          saat: double.tryParse(hourController.text) ?? 8.0,
                          mesai: double.tryParse(mesaiController.text) ?? 0.0,
                          aciklama: noteController.text,
                          projectId: selectedProjectId,
                          status: selectedStatus,
                        );
                        await DatabaseHelper.instance.insertPuantaj(p);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadAttendance();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF011627),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF011627).withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(AppLocalizations.of(context)!.save.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  if (existingPuantaj != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await DatabaseHelper.instance.deletePuantaj(existingPuantaj.id!);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadAttendance();
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.deleteRecord.toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_viewDate.year, _viewDate.month + 1, 0).day;
    final firstDayOffset = DateTime(_viewDate.year, _viewDate.month, 1).weekday - 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2F5),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF011627),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month - 1));
                        _loadAttendance();
                      },
                    ),
                    Text(
                      DateFormat('MMMM yyyy', Localizations.localeOf(context).toString()).format(_viewDate).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () {
                        setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month + 1));
                        _loadAttendance();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.worker.adSoyad,
                  style: const TextStyle(color: Color(0xFF2EC4B6), fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        AppLocalizations.of(context)!.monday_short,
                        AppLocalizations.of(context)!.tuesday_short,
                        AppLocalizations.of(context)!.wednesday_short,
                        AppLocalizations.of(context)!.thursday_short,
                        AppLocalizations.of(context)!.friday_short,
                        AppLocalizations.of(context)!.saturday_short,
                        AppLocalizations.of(context)!.sunday_short,
                      ].map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: const Color(0xFF011627).withOpacity(0.5),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: daysInMonth + firstDayOffset,
                      itemBuilder: (context, index) {
                        if (index < firstDayOffset) return const SizedBox.shrink();
                        final day = index - firstDayOffset + 1;
                        final date = DateTime(_viewDate.year, _viewDate.month, day);
                        final puantaj = _attendance[_dateKey(date)];
                        
                        Color bgColor = Colors.white;
                        Color textColor = const Color(0xFF011627);
                        
                        bool isBonusSunday = false;
                        if (date.weekday == DateTime.sunday) {
                          bool earned = true;
                          for (int i = 1; i <= 6; i++) {
                            final p = _attendance[_dateKey(date.subtract(Duration(days: i)))];
                            if (p == null || p.status == PuantajStatus.izinsiz) {
                              earned = false;
                              break;
                            }
                          }
                          if (earned) {
                            bool isPaidHolidayRecord = puantaj != null && 
                              [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(puantaj.status);
                            if (!isPaidHolidayRecord) isBonusSunday = true;
                          }
                        }

                        if (puantaj != null) {
                          switch (puantaj.status) {
                            case PuantajStatus.normal:
                              bgColor = const Color(0xFF2EC4B6);
                              textColor = Colors.white;
                              break;
                            case PuantajStatus.izinli:
                            case PuantajStatus.raporlu:
                            case PuantajStatus.mazeretli:
                              bgColor = Colors.blue.shade600;
                              textColor = Colors.white;
                              break;
                            case PuantajStatus.izinsiz:
                              bgColor = Colors.red.shade600;
                              textColor = Colors.white;
                              break;
                          }
                        } else if (isBonusSunday) {
                          bgColor = Colors.amber.shade400;
                          textColor = Colors.white;
                        }

                        return GestureDetector(
                          onTap: () => _showPuantajEditDialog(day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: puantaj != null ? Colors.transparent : Colors.black.withOpacity(0.05)),
                              boxShadow: puantaj != null ? [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                            ),
                            child: Center(
                              child: Text(
                                day.toString(),
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          _buildInfoFooter(),
        ],
      ),
    );
  }

  Widget _buildInfoFooter() {
    int daysInMonth = DateTime(_viewDate.year, _viewDate.month + 1, 0).day;
    int workedDays = 0;
    int leaveDays = 0;
    int absentDays = 0;
    int sundayBonuses = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_viewDate.year, _viewDate.month, day);
      final p = _attendance[_dateKey(date)];
      if (p != null) {
        if (p.status == PuantajStatus.normal) workedDays++;
        else if ([PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(p.status)) leaveDays++;
        else if (p.status == PuantajStatus.izinsiz) absentDays++;
      }
      
      if (date.weekday == DateTime.sunday) {
        bool earned = true;
        for (int i = 1; i <= 6; i++) {
          final cp = _attendance[_dateKey(date.subtract(Duration(days: i)))];
          if (cp == null || cp.status == PuantajStatus.izinsiz) {
            earned = false;
            break;
          }
        }
        if (earned) {
          final ps = _attendance[_dateKey(date)];
          bool isPaidHolidayRecord = ps != null && 
            [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(ps.status);
          if (!isPaidHolidayRecord) {
            sundayBonuses++;
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: const Color(0xFFF0F2F5)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniSummary(AppLocalizations.of(context)!.work_caps, workedDays, const Color(0xFF2EC4B6)),
              _buildMiniSummary(AppLocalizations.of(context)!.leave_report_caps, leaveDays, Colors.blue.shade600),
              _buildMiniSummary(AppLocalizations.of(context)!.unauthorized_caps, absentDays, Colors.red.shade600),
              _buildMiniSummary(AppLocalizations.of(context)!.sunday_caps, sundayBonuses, Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF011627), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(AppLocalizations.of(context)!.close.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSummary(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
