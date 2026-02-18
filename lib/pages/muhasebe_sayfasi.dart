import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cari_hesap.dart';
import '../models/cari_islem.dart';
import '../models/project.dart';
import '../services/database_helper.dart';
import 'cari_detay_sayfasi.dart';
import '../widgets/cari_ekle_dialog.dart';

class MuhasebeSayfasi extends StatefulWidget {
  const MuhasebeSayfasi({super.key});

  @override
  State<MuhasebeSayfasi> createState() => _MuhasebeSayfasiState();
}

class _MuhasebeSayfasiState extends State<MuhasebeSayfasi> {
  List<CariHesap> _cariHesaplar = [];
  List<CariIslem> _islemler = [];
  List<CariIslem> _filtrelenmisIslemler = [];
  List<Project> _projeler = [];
  CariHesap? _seciliCari;
  Project? _seciliProje;
  bool _isLoading = true;

  // Form controllers
  final _aciklamaController = TextEditingController();
  final _evrakNoController = TextEditingController();
  final _borcController = TextEditingController();
  final _alacakController = TextEditingController();

  DateTime _tarih = DateTime.now();
  DateTime? _vade;
  DateTime? _vadeBitis;
  String _hesapTipi = 'Nakit';

  Map<String, double> _toplamlar = {'borc': 0.0, 'alacak': 0.0, 'bakiye': 0.0};

  @override
  void initState() {
    super.initState();
    _yukleVeriler();
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _evrakNoController.dispose();
    _borcController.dispose();
    _alacakController.dispose();
    super.dispose();
  }

  Future<void> _yukleVeriler() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cariHesaplar = await DatabaseHelper.instance.getAllCariHesaplar();
      final projeler = await DatabaseHelper.instance.getAllProjects();
      final islemler = await DatabaseHelper.instance.getUnifiedLedger(
        cariId: _seciliCari?.id,
        projectId: _seciliProje?.id,
      );
      final toplamlar = await DatabaseHelper.instance.getCariToplamlar(_seciliCari?.id);

      // Seçili cariyi yeni listeden bul
      CariHesap? seciliCariGuncel;
      if (_seciliCari != null && _seciliCari!.id != null) {
        seciliCariGuncel = cariHesaplar.firstWhere(
          (c) => c.id == _seciliCari!.id,
          orElse: () => _seciliCari!,
        );
      }

      // Seçili projeyi yeni listeden bul
      Project? seciliProjeGuncel;
      if (_seciliProje != null && _seciliProje!.id != null) {
        seciliProjeGuncel = projeler.firstWhere(
          (p) => p.id == _seciliProje!.id,
          orElse: () => _seciliProje!,
        );
      }

      setState(() {
        _cariHesaplar = cariHesaplar;
        _projeler = projeler;
        _islemler = islemler;
        _filtrelenmisIslemler = islemler;
        _toplamlar = toplamlar;
        _seciliCari = seciliCariGuncel;
        _seciliProje = seciliProjeGuncel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cariFiltrele(CariHesap? cari) {
    setState(() => _seciliCari = cari);
    _yukleVeriler();
  }

  void _projeFiltrele(Project? proje) {
    setState(() => _seciliProje = proje);
    _yukleVeriler();
  }

  Future<void> _yukleToplamlar(int? cariId) async {
    final toplamlar = await DatabaseHelper.instance.getCariToplamlar(cariId);
    setState(() {
      _toplamlar = toplamlar;
    });
  }

  String _formatPara(double tutar) {
    try {
      return NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(tutar);
    } catch (e) {
      return '₺${tutar.toStringAsFixed(2)}';
    }
  }

  Future<void> _kaydet() async {
    if (_seciliCari == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir cari hesap seçiniz')),
      );
      return;
    }

    if (_aciklamaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Açıklama zorunludur')),
      );
      return;
    }

    final borc = double.tryParse(_borcController.text.replaceAll(',', '.')) ?? 0.0;
    final alacak = double.tryParse(_alacakController.text.replaceAll(',', '.')) ?? 0.0;

    if (borc == 0.0 && alacak == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borç veya Alacak tutarından biri girilmelidir')),
      );
      return;
    }

    try {
      final islem = CariIslem(
        cariHesapId: _seciliCari!.id!,
        cariHesapUnvan: _seciliCari!.unvan,
        tarih: _tarih,
        aciklama: _aciklamaController.text.trim(),
        hesapTipi: _hesapTipi,
        evrakNo: _evrakNoController.text.trim().isEmpty ? null : _evrakNoController.text.trim(),
        vade: _vade,
        vadeBitis: _vadeBitis,
        borc: borc,
        alacak: alacak,
        bakiye: borc - alacak,
        projectId: _seciliProje?.id,
      );

      await DatabaseHelper.instance.insertCariIslem(islem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem kaydedildi')),
        );
        _temizle();
        _yukleVeriler();
        _cariFiltrele(_seciliCari);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _temizle() {
    _aciklamaController.clear();
    _evrakNoController.clear();
    _borcController.clear();
    _alacakController.clear();
    _hesapTipi = 'Nakit';
    _vade = null;
    _vadeBitis = null;
  }

  Future<void> _silIslem(CariIslem islem) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: const Text('Bu işlemi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay == true && islem.id != null) {
      try {
        await DatabaseHelper.instance.deleteCariIslem(islem.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İşlem silindi')),
          );
          _yukleVeriler();
          _cariFiltrele(_seciliCari);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MUHASEBE & CARİ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _yukleVeriler,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Next Gen Summary Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _OzetKartModern(
                              baslik: 'Gelecek (Borç)',
                              deger: _formatPara(_toplamlar['borc']!),
                              icon: Icons.south_east_rounded,
                              renk: const Color(0xFFFF5252),
                              isGlass: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _OzetKartModern(
                              baslik: 'Çıkacak (Alacak)',
                              deger: _formatPara(_toplamlar['alacak']!),
                              icon: Icons.north_east_rounded,
                              renk: const Color(0xFF00E676),
                              isGlass: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _OzetKartModern(
                        baslik: 'Net Durum (Bakiye)',
                        deger: _formatPara(_toplamlar['bakiye']!),
                        icon: Icons.account_balance_wallet_rounded,
                        renk: Colors.amber.shade400,
                        isGlass: false,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),

                // Adaptive Search & Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildCariFilter(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _buildProjeFilter(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Data Table with Premium Styling
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _filtrelenmisIslemler.isEmpty
                        ? _EmptyState()
                        : Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.grey.shade100,
                            ),
                            child: SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowHeight: 56,
                                  dataRowHeight: 64,
                                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                                  columnSpacing: 16,
                                  horizontalMargin: 12,
                                    columns: const [
                                      DataColumn(label: Text('TARİH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
                                      DataColumn(label: Text('CARİ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
                                      DataColumn(label: Text('AÇIKLAMA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
                                      DataColumn(label: Text('DURUM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
                                      DataColumn(label: Text('GELECEK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
                                      DataColumn(label: Text('ÇIKACAK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
                                      DataColumn(label: Text('BAKİYE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
                                      DataColumn(label: Text(' ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
                                    ],
                                  rows: _filtrelenmisIslemler.map((islem) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(DateFormat('dd.MM.yy').format(islem.tarih), style: const TextStyle(fontWeight: FontWeight.w500))),
                                        DataCell(Text(islem.cariHesapUnvan ?? '---', style: const TextStyle(fontWeight: FontWeight.w600))),
                                        DataCell(Text(islem.displayAciklama, style: const TextStyle(fontSize: 11))),
                                        DataCell(_StatusBadge(isBorc: islem.borc > 0)),
                                        DataCell(FittedBox(fit: BoxFit.scaleDown, child: Text(islem.borc > 0 ? _formatPara(islem.borc) : '-', style: TextStyle(color: islem.borc > 0 ? Colors.red.shade700 : Colors.grey, fontWeight: FontWeight.w900)))),
                                        DataCell(FittedBox(fit: BoxFit.scaleDown, child: Text(islem.alacak > 0 ? _formatPara(islem.alacak) : '-', style: TextStyle(color: islem.alacak > 0 ? Colors.green.shade700 : Colors.grey, fontWeight: FontWeight.w900)))),
                                        DataCell(FittedBox(fit: BoxFit.scaleDown, child: Text(_formatPara(islem.bakiye), style: const TextStyle(fontWeight: FontWeight.w700)))),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                                            onPressed: () => _silIslem(islem),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIslemEkleBottomSheet,
        label: const Text('YENİ İŞLEM EKLE'),
        icon: const Icon(Icons.add_rounded, size: 26),
        backgroundColor: const Color(0xFF003399),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showIslemEkleBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('Hızlı İşlem Girişi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CariHesap?>(
                      value: _seciliCari,
                      decoration: const InputDecoration(labelText: 'Cari Hesap Seçimi'),
                      items: _cariHesaplar.map((cari) => DropdownMenuItem(value: cari, child: Text(cari.unvan))).toList(),
                      onChanged: (cari) => setState(() => _seciliCari = cari),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(color: const Color(0xFF003399).withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded, color: Color(0xFF003399)),
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => const CariEkleDialog(),
                        );
                        if (result == true) _yukleVeriler();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Project?>(
                value: _seciliProje,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Proje İlişkilendirme (Opsiyonel)'),
                items: [
                   const DropdownMenuItem(value: null, child: Text('- Proje Yok -')),
                   ..._projeler.map((p) => DropdownMenuItem(value: p, child: Text(p.ad))).toList(),
                ],
                onChanged: (p) => setState(() => _seciliProje = p),
              ),
              const SizedBox(height: 16),
              TextField(controller: _aciklamaController, decoration: const InputDecoration(labelText: 'Açıklama / Not')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _borcController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Borç (Alınacak)', prefixIcon: Icon(Icons.arrow_downward_rounded, color: Colors.red, size: 20)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _alacakController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Alacak (Verilen)', prefixIcon: Icon(Icons.arrow_upward_rounded, color: Colors.green, size: 20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _kaydet();
                    Navigator.pop(context);
                  },
                  child: const Text('İŞLEMİ KAYDET'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCariFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<CariHesap?>(
          isDense: true,
          isExpanded: true,
          value: _seciliCari,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.business_rounded, size: 16),
            hintText: 'Cari Seç',
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tüm Cariler', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
            ..._cariHesaplar.map((c) => DropdownMenuItem(value: c, child: Text(c.unvan, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
          ],
          onChanged: _cariFiltrele,
        ),
      ),
    );
  }

  Widget _buildProjeFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<Project?>(
          isDense: true,
          isExpanded: true,
          value: _seciliProje,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.architecture_rounded, size: 16),
            hintText: 'Proje Seç',
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tüm Projeler', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
            ..._projeler.map((p) => DropdownMenuItem(value: p, child: Text(p.ad, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
          ],
          onChanged: _projeFiltrele,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isBorc;
  const _StatusBadge({required this.isBorc});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBorc ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isBorc ? 'BORÇ' : 'ALACAK',
        style: TextStyle(color: isBorc ? Colors.red.shade700 : Colors.green.shade700, fontWeight: FontWeight.w900, fontSize: 10),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('Henüz işlem bulunmuyor', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _OzetKartModern extends StatelessWidget {
  final String baslik;
  final String deger;
  final IconData icon;
  final Color renk;
  final bool isGlass;
  final bool fullWidth;

  const _OzetKartModern({
    required this.baslik,
    required this.deger,
    required this.icon,
    required this.renk,
    required this.isGlass,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGlass ? Colors.white.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isGlass ? Border.all(color: Colors.white.withOpacity(0.15)) : null,
      ),
      child: Row(
        mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGlass ? Colors.white.withOpacity(0.15) : renk.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isGlass ? Colors.white : renk, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isGlass ? Colors.white70 : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    deger,
                    style: TextStyle(
                      color: isGlass ? Colors.white : Colors.grey.shade900,
                      fontSize: fullWidth ? 22 : 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

