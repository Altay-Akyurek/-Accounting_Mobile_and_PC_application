import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/worker.dart';
import '../models/cari_hesap.dart';
import '../models/project.dart';
import '../services/database_helper.dart';
import 'worker_documents_page.dart';

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
        title: const Text('PERSONEL TAKİBİ'),
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
        label: const Text('PERSONEL KAYIT'),
        backgroundColor: const Color(0xFF011627),
        foregroundColor: Colors.white,
      ),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saha Personel Yönetimi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                Text('Puantaj ve maaş tahakkuk takibi', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
            child: const Text('ÖZET AL', style: TextStyle(fontSize: 11)),
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
                  child: const Text(
                    'İŞTEN AYRILDI',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                          worker.pozisyon ?? 'Saha Personeli',
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
                            label: const Text('PUANTAJ', style: TextStyle(fontSize: 11)),
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
                          if (worker.aktif) const PopupMenuItem(value: 'dismiss', child: Text('İşten Çıkar')),
                          const PopupMenuItem(value: 'documents', child: Text('Belgeler')),
                          if (!worker.aktif) const PopupMenuItem(value: 'delete', child: Text('Kalıcı Olarak Sil', style: TextStyle(color: Colors.red))),
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
        title: const Text('İşten Çıkar'),
        content: Text('${worker.adSoyad} isimli personeli işten çıkarmak istediğinize emin misiniz?\n\nNot: Eğer geçmiş işlemleri yoksa bağlı cari hesap otomatik olarak silinecektir. İşlemleri varsa cari hesap dökümü için korunacaktır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İPTAL')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.dismissWorker(worker.id!, DateTime.now());
              if (mounted) {
                Navigator.pop(context);
                _loadWorkers();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personel işten çıkarıldı. (Hareket geçmişi olan cari hesaplar korunur)')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İŞTEN ÇIKAR'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Worker worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kalıcı Olarak Sil'),
        content: Text('${worker.adSoyad} isimli personeli ve tüm puantaj kayıtlarını tamamen silmek istediğinize emin misiniz? bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İPTAL')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteWorker(worker.id!);
              if (mounted) {
                Navigator.pop(context);
                _loadWorkers();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personel kaydı tamamen silindi.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('KALICI OLARAK SİL'),
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
          Text('Personel listesi boş', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
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
                const Text('Yeni Personel Kartı', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF011627))),
                const SizedBox(height: 24),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ad Soyad')),
                const SizedBox(height: 16),
                TextField(controller: posController, decoration: const InputDecoration(labelText: 'Görev / Pozisyon')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: salaryController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Maaş Tutarı'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<WorkerSalaryType>(
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(value: WorkerSalaryType.gunluk, child: Text('Günlük')),
                          DropdownMenuItem(value: WorkerSalaryType.aylik, child: Text('Aylık')),
                          DropdownMenuItem(value: WorkerSalaryType.saatlik, child: Text('Saatlik')),
                        ],
                        onChanged: (v) => setModalState(() => selectedType = v!),
                        decoration: const InputDecoration(labelText: 'Maaş Türü'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: addAsCari,
                  onChanged: (v) => setModalState(() => addAsCari = v ?? false),
                  title: const Text('Cari Hesap Olarak Kaydet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Maaş ödemeleri ve mutabakat için gereklidir', style: TextStyle(fontSize: 12)),
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
                    child: const Text('KAYDI TAMAMLA'),
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
              const Text('PERSONEL GENEL ÖZETİ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF011627))),
              const SizedBox(height: 24),
              _buildSummaryItem('Toplam Personel', summary['total'].toString(), Icons.people_rounded),
              _buildSummaryItem('Aktif Personel', summary['active'].toString(), Icons.check_circle_outline_rounded, color: Colors.green),
              _buildSummaryItem('Ayrılan Personel', summary['dismissed'].toString(), Icons.exit_to_app_rounded, color: Colors.orange),
              const Divider(height: 32),
              _buildSummaryItem('Toplam Tahakkuk (Hak)', NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(summary['accrued']), Icons.work_history_rounded),
              _buildSummaryItem('Toplam Ödenen', NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(summary['paid']), Icons.payments_rounded, color: Colors.blue),
              _buildSummaryItem('Kalan Borç (Bakiye)', NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(summary['balance']), Icons.account_balance_wallet_rounded, 
                color: (summary['balance'] as double) > 0 ? Colors.red : Colors.green),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF011627)),
                  child: const Text('KAPAT'),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  '${DateFormat('dd MMMM yyyy EEEE', 'tr_TR').format(date)} - Puantaj',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hourController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Çalışma Saati',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: mesaiController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Mesai Saati',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'DURUM SEÇİN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PuantajStatus.values.map((status) {
                      String label = '';
                      switch (status) {
                        case PuantajStatus.normal: label = 'Normal'; break;
                        case PuantajStatus.izinli: label = 'İzinli'; break;
                        case PuantajStatus.raporlu: label = 'Raporlu'; break;
                        case PuantajStatus.mazeretli: label = 'Mazeretli'; break;
                        case PuantajStatus.izinsiz: label = 'İzinsiz'; break;
                      }
                      final isSelected = selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => selectedStatus = status);
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
                    labelText: 'Not / Açıklama',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedProjectId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Proje Seçilmedi')),
                    ..._projects.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.ad),
                    )),
                  ],
                  onChanged: (v) => setModalState(() => selectedProjectId = v),
                  decoration: InputDecoration(
                    labelText: 'İlgili Proje',
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
                    child: const Text('KAYDET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
                    child: const Text('KAYDI SİL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_viewDate.year, _viewDate.month + 1, 0).day;
    final firstDayOffset = DateTime(_viewDate.year, _viewDate.month, 1).weekday - 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: Color(0xFFF0F2F5), borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFF011627), borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () {
                      setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month - 1));
                      _loadAttendance();
                    }),
                    Text(DateFormat('MMMM yyyy', 'tr_TR').format(_viewDate).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                    IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: () {
                      setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month + 1));
                      _loadAttendance();
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Text(widget.worker.adSoyad, style: const TextStyle(color: Color(0xFF2EC4B6), fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
          if (_isLoading) 
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: daysInMonth + firstDayOffset,
                itemBuilder: (context, index) {
                  if (index < firstDayOffset) return const SizedBox.shrink();
                  final day = index - firstDayOffset + 1;
                  final date = DateTime(_viewDate.year, _viewDate.month, day);
                  final puantaj = _attendance[_dateKey(date)];
                  
                  Color bgColor = Colors.white;
                  Color textColor = const Color(0xFF011627);
                  
                  // Sunday Streak Logic for Visualization
                  bool isBonusSunday = false;
                  if (date.weekday == DateTime.sunday) {
                    bool earned = true;
                    for (int i = 1; i <= 6; i++) {
                      DateTime checkDate = date.subtract(Duration(days: i));
                      final p = _attendance[_dateKey(checkDate)];
                      if (p == null || p.status == PuantajStatus.izinsiz) {
                        earned = false;
                        break;
                      }
                    }
                    if (earned) {
                      // Rule: If sunday itself has a paid leave record, it's not a "Bonus" highlighting
                      bool isPaidHolidayRecord = puantaj != null && 
                        [PuantajStatus.izinli, PuantajStatus.raporlu, PuantajStatus.mazeretli].contains(puantaj.status);
                      if (!isPaidHolidayRecord) {
                        isBonusSunday = true;
                      }
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
                    bgColor = Colors.amber.shade400; // Earned Sunday is Yellow
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
              _buildMiniSummary('ÇALIŞMA', workedDays, const Color(0xFF2EC4B6)),
              _buildMiniSummary('İZİN/RAPOR', leaveDays, Colors.blue.shade600),
              _buildMiniSummary('İZSİNSİZ', absentDays, Colors.red.shade600),
              _buildMiniSummary('PAZAR', sundayBonuses, Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF011627), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('KAPAT'),
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
