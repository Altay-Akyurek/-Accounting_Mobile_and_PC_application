import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/hakedis.dart';
import '../models/gelir_gider.dart';
import '../models/cari_islem.dart';
import '../models/worker.dart';
import '../services/database_helper.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Hakedis> _hakedisler = [];
  List<GelirGider> _gelirGiderler = [];
  List<CariIslem> _cariIslemler = [];
  List<Puantaj> _puantajlar = [];
  List<Worker> _workers = [];
  bool _isLoading = true;

  double _toplamGelir = 0;
  double _toplamGider = 0;
  double _netKar = 0;
  double _tahsilEdilenHakedis = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final hakedisler = await DatabaseHelper.instance.getHakedisByProjectId(widget.project.id!);
    final gelirGiderler = await DatabaseHelper.instance.getGelirGiderByProjectId(widget.project.id!);
    final cariIslemler = await DatabaseHelper.instance.getCariIslemlerByProjectId(widget.project.id!);
    final puantajlar = await DatabaseHelper.instance.getPuantajByProjectId(widget.project.id!);
    final workers = await DatabaseHelper.instance.getAllWorkers();

    double gelir = 0;
    double gider = 0;
    double tahsilEdilen = 0;

    // Hakedişler
    for (var h in hakedisler) {
      if (h.durum == HakedisDurum.tahsilEdildi) {
        gelir += h.netTutar;
        tahsilEdilen += h.netTutar;
      }
    }

    // Gelir/Gider
    for (var gg in gelirGiderler) {
      if (gg.tipi == GelirGiderTipi.gelir) gelir += gg.tutar;
      if (gg.tipi == GelirGiderTipi.gider) gider += gg.tutar;
    }

    // Cari İşlemler
    for (var islem in cariIslemler) {
      if (!(islem.aciklama.contains('Hakediş Tahsilatı'))) {
        gelir += islem.borc;
      }
      gider += islem.alacak;
    }

    // İşçilik (Puantaj) - Dinamik maliyet
    for (var p in puantajlar) {
      final worker = workers.firstWhere((w) => w.id == p.workerId, orElse: () => Worker(adSoyad: 'Bilinmeyen', baslangicTarihi: DateTime.now()));
      gider += DatabaseHelper.instance.calculateLaborCost(p, worker);
    }

    setState(() {
      _hakedisler = hakedisler;
      _gelirGiderler = gelirGiderler;
      _cariIslemler = cariIslemler;
      _puantajlar = puantajlar;
      _workers = workers;
      _toplamGelir = gelir;
      _toplamGider = gider;
      _netKar = gelir - gider;
      _tahsilEdilenHakedis = tahsilEdilen;
      _isLoading = false;
    });
  }

  String _formatPara(double tutar) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(tutar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.project.ad.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ÖZET'),
            Tab(text: 'HAKEDİŞLER'),
            Tab(text: 'GİDERLER'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHakedisTab(),
          _buildExpensesTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddHakedisDialog,
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text('YENİ HAKEDİŞ'),
              backgroundColor: const Color(0xFF003399),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStatGrid(),
          const SizedBox(height: 24),
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildStatusUpdateCard(),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.1, // Adjusted ratio to allow more height (2.2 -> 2.1)
      ),
      children: [
        _buildMiniStat('Tahsil Edilen', _formatPara(_tahsilEdilenHakedis), Colors.green),
        _buildMiniStat('Toplam Gider', _formatPara(_toplamGider), Colors.red),
        _buildMiniStat('Net Kar', _formatPara(_netKar), _netKar >= 0 ? Colors.blue : Colors.red),
        _buildMiniStat('Proje Bütçesi', _formatPara(widget.project.toplamButce), Colors.orange),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Proje Detayları', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 16),
          _buildDetailRow('Başlangıç', DateFormat('dd.MM.yyyy').format(widget.project.baslangicTarihi)),
          _buildDetailRow('Durum', widget.project.durum.name.toUpperCase()),
          _buildDetailRow('Açıklama', widget.project.aciklama ?? 'Girilmemiş'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Proje Durumu Değiştir', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 16),
          SegmentedButton<ProjectStatus>(
            segments: const [
              ButtonSegment(value: ProjectStatus.aktif, label: Text('Aktif'), icon: Icon(Icons.play_circle_outline)),
              ButtonSegment(value: ProjectStatus.askida, label: Text('Askıda'), icon: Icon(Icons.pause_circle_outline)),
              ButtonSegment(value: ProjectStatus.tamamlandi, label: Text('Bitti'), icon: Icon(Icons.check_circle_outline)),
            ],
            selected: {widget.project.durum},
            onSelectionChanged: (val) async {
              final newStatus = val.first;
              if (newStatus != widget.project.durum) {
                final updatedProject = widget.project.copyWith(
                  durum: newStatus,
                  bitisTarihi: newStatus == ProjectStatus.tamamlandi ? DateTime.now() : widget.project.bitisTarihi,
                );
                await DatabaseHelper.instance.updateProject(updatedProject);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Proje durumu ${newStatus.name} olarak güncellendi')),
                  );
                  Navigator.pop(context); // Refresh parent page
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHakedisTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hakedisler.isEmpty) return _buildEmptyTab('Henüz hakediş girilmemiş');

    // Sort: newest first
    final sortedHakedisler = List<Hakedis>.from(_hakedisler)..sort((a, b) => b.tarih.compareTo(a.tarih));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedHakedisler.length,
      itemBuilder: (context, index) {
        final h = sortedHakedisler[index];
        final isTahsilEdildi = h.durum == HakedisDurum.tahsilEdildi;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
          elevation: 0,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Row(
                  children: [
                    Text(h.baslik, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTahsilEdildi ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isTahsilEdildi ? 'TAHSİL EDİLDİ' : 'BEKLİYOR',
                        style: TextStyle(
                          color: isTahsilEdildi ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(h.tarih),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'status') _toggleHakedisStatus(h);
                    if (val == 'delete') _deleteHakedis(h);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(isTahsilEdildi ? Icons.pending_actions_rounded : Icons.check_circle_outline_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(isTahsilEdildi ? 'Bekliyor İşaretle' : 'Tahsil Edildi İşaretle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text('Hakedişi Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (h.aciklama != null && h.aciklama!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      h.aciklama!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHakedisDetailItem('Brüt', _formatPara(h.tutar)),
                    _buildHakedisDetailItem('Kesintiler', _formatPara(h.stopajTutari + h.teminatTutari)),
                    _buildHakedisDetailItem('Net Tahsilat', _formatPara(h.netTutar), isBold: true, color: Colors.green),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHakedisDetailItem(String label, String value, {bool isBold = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            fontSize: 13,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleHakedisStatus(Hakedis h) async {
    final newStatus = h.durum == HakedisDurum.tahsilEdildi ? HakedisDurum.bekliyor : HakedisDurum.tahsilEdildi;
    final updated = Hakedis(
      id: h.id,
      projectId: h.projectId,
      projectAd: h.projectAd,
      baslik: h.baslik,
      tutar: h.tutar,
      kdvOrani: h.kdvOrani,
      stopajOrani: h.stopajOrani,
      teminatOrani: h.teminatOrani,
      durum: newStatus,
      tarih: h.tarih,
      aciklama: h.aciklama,
      olusturmaTarihi: h.olusturmaTarihi,
    );
    await DatabaseHelper.instance.updateHakedis(updated);
    _loadData();
  }

  Future<void> _deleteHakedis(Hakedis h) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hakedişi Sil'),
        content: Text('"${h.baslik}" hakedişini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İPTAL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SİL'),
          ),
        ],
      ),
    );

    if (confirmed == true && h.id != null) {
      await DatabaseHelper.instance.deleteHakedis(h.id!);
      _loadData();
    }
  }

  Widget _buildExpensesTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    final List<Map<String, dynamic>> allExpenses = [];

    // GelirGider from db
    for (var gg in _gelirGiderler) {
      if (gg.tipi == GelirGiderTipi.gider) {
        allExpenses.add({
          'title': gg.baslik,
          'subtitle': gg.kategori ?? 'Gider',
          'amount': gg.tutar,
          'date': gg.tarih,
          'icon': Icons.shopping_cart_rounded,
          'color': Colors.orange,
        });
      }
    }

    // Cari İşlemler
    for (var islem in _cariIslemler) {
      if (islem.alacak > 0) {
        allExpenses.add({
          'title': islem.aciklama,
          'subtitle': islem.cariHesapUnvan ?? 'Cari İşlem',
          'amount': islem.alacak,
          'date': islem.tarih,
          'icon': Icons.swap_horiz_rounded,
          'color': Colors.blue,
        });
      }
    }

    // Puantaj
    for (var p in _puantajlar) {
      final worker = _workers.firstWhere((w) => w.id == p.workerId, orElse: () => Worker(adSoyad: 'Bilinmeyen', baslangicTarihi: DateTime.now()));
      allExpenses.add({
        'title': 'İşçilik Ödemesi',
        'subtitle': 'Puantaj Kaydı (${worker.adSoyad})',
        'amount': DatabaseHelper.instance.calculateLaborCost(p, worker),
        'date': p.tarih,
        'icon': Icons.engineering_rounded,
        'color': Colors.purple,
      });
    }

    allExpenses.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (allExpenses.isEmpty) return _buildEmptyTab('Henüz gider kaydı bulunamadı');

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: allExpenses.length,
      itemBuilder: (context, index) {
        final exp = allExpenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (exp['color'] as Color).withOpacity(0.1),
              child: Icon(exp['icon'] as IconData, color: exp['color'] as Color, size: 20),
            ),
            title: Text(exp['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${exp['subtitle']} - ${DateFormat('dd.MM.yyyy').format(exp['date'] as DateTime)}'),
            trailing: Text(
              _formatPara(exp['amount'] as double),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTab(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  void _showAddHakedisDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    double kdv = 20.0;
    double stopaj = 0.0;
    double teminat = 0.0;
    DateTime selectedDate = DateTime.now();

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
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 24),
                  const Text('Hakediş Girişi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF003399))),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Hakediş Başlığı',
                      hintText: 'örn: 1. Hakediş veya Ocak Ayı Hakedişi',
                      prefixIcon: const Icon(Icons.title_rounded),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Hakediş Tutarı (KDV Hariç)',
                      suffixText: '₺',
                      prefixIcon: const Icon(Icons.payments_rounded),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Vergi ve Kesinti Oranları (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'KDV',
                            hintText: '20',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (v) => kdv = double.tryParse(v) ?? 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Stopaj',
                            hintText: '0',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (v) => stopaj = double.tryParse(v) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Teminat',
                            hintText: '0',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (v) => teminat = double.tryParse(v) ?? 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded),
                    title: const Text('Hakediş Tarihi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(selectedDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Açıklama / Not (Opsiyonel)',
                      alignLabelWithHint: true,
                      prefixIcon: const Icon(Icons.notes_rounded),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003399),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          final h = Hakedis(
                            projectId: widget.project.id!,
                            projectAd: widget.project.ad,
                            baslik: titleController.text,
                            tutar: double.parse(amountController.text),
                            kdvOrani: kdv,
                            stopajOrani: stopaj,
                            teminatOrani: teminat,
                            tarih: selectedDate,
                            aciklama: noteController.text,
                          );
                          await DatabaseHelper.instance.insertHakedis(h);
                          if (!mounted) return;
                          Navigator.pop(context);
                          _loadData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen başlık ve tutar giriniz.')));
                        }
                      },
                      child: const Text('HAKEDİŞİ KAYDET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
