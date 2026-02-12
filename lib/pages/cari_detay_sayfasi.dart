import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cari_islem.dart';
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

      setState(() {
        _islemler = islemler;
        _toplamlar = toplamlar;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatPara(double tutar) {
    try {
      return NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(tutar);
    } catch (e) {
      return '₺${tutar.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cari Detay: ${widget.cariUnvan.toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _yukleVeriler,
          ),
        ],
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
                    baslik: 'GELECEK (BORÇ):',
                    deger: _formatPara(_toplamlar['borc']!),
                    renk: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _OzetKart(
                    baslik: 'ÇIKACAK (ALACAK):',
                    deger: _formatPara(_toplamlar['alacak']!),
                    renk: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _OzetKart(
                    baslik: 'BAKİYE:',
                    deger: _formatPara(_toplamlar['bakiye']!),
                    renk: Colors.yellow,
                  ),
                ),
              ],
            ),
          ),
          // Tablo
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _islemler.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz işlem eklenmemiş',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFE6EBF5)),
                          columns: const [
                            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('TARİH', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('AÇIKLAMA', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('İŞLEM TİPİ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('EVRAK NO', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('VADE', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('VADE BİTİŞ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('BORÇ (G)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ALACAK (Ç)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('BAKİYE', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _islemler.map((islem) {
                            return DataRow(
                              cells: [
                                DataCell(Text('${islem.id}')),
                                DataCell(Text(DateFormat('dd.MM.yyyy', 'tr_TR').format(islem.tarih))),
                                DataCell(Text(islem.displayAciklama)),
                                DataCell(Text(islem.hesapTipi)),
                                DataCell(Text(islem.evrakNo ?? '')),
                                DataCell(Text(islem.vade != null ? DateFormat('dd.MM.yyyy', 'tr_TR').format(islem.vade!) : '')),
                                DataCell(Text(islem.vadeBitis != null ? DateFormat('dd.MM.yyyy', 'tr_TR').format(islem.vadeBitis!) : '')),
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
                      // Excel export - basit bir implementasyon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Excel çıktı özelliği yakında eklenecek')),
                      );
                    },
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text('Excel (CSV) Çıktı Al'),
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
                      // Print - basit bir implementasyon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yazdırma özelliği yakında eklenecek')),
                      );
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Yazdır'),
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
                      // Makbuz oluştur
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Makbuz özelliği yakında eklenecek')),
                      );
                    },
                    icon: const Icon(Icons.receipt, size: 18),
                    label: const Text('Makbuz / Ekstre Oluştur'),
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
                    child: const Text('Geri'),
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


