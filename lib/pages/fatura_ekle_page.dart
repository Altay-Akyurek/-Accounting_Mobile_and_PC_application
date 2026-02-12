import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fatura.dart';
import '../models/cari_hesap.dart';
import '../services/database_helper.dart';
import 'cari_hesap_liste_page.dart';

class FaturaEklePage extends StatefulWidget {
  final Fatura? fatura;
  final FaturaTipi? tipi;

  const FaturaEklePage({super.key, this.fatura, this.tipi});

  @override
  State<FaturaEklePage> createState() => _FaturaEklePageState();
}

class _FaturaEklePageState extends State<FaturaEklePage> {
  final _formKey = GlobalKey<FormState>();
  final _faturaNoController = TextEditingController();
  final _tarihController = TextEditingController();
  final _vadeTarihiController = TextEditingController();
  final _aciklamaController = TextEditingController();

  DateTime _tarih = DateTime.now();
  DateTime? _vadeTarihi;
  CariHesap? _seciliCariHesap;
  List<FaturaKalemi> _kalemler = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.fatura != null) {
      _faturaNoController.text = widget.fatura!.faturaNo;
      _tarih = widget.fatura!.tarih;
      _tarihController.text = DateFormat('dd.MM.yyyy', 'tr_TR').format(_tarih);
      _vadeTarihi = widget.fatura!.vadeTarihi;
      if (_vadeTarihi != null) {
        _vadeTarihiController.text = DateFormat('dd.MM.yyyy', 'tr_TR').format(_vadeTarihi!);
      }
      _aciklamaController.text = widget.fatura!.aciklama ?? '';
      _kalemler = List.from(widget.fatura!.kalemler);
      if (widget.fatura!.cariHesapId != null) {
        _yukleCariHesap(widget.fatura!.cariHesapId!);
      }
    } else {
      _tarihController.text = DateFormat('dd.MM.yyyy', 'tr_TR').format(_tarih);
      _faturaNoController.text = _olusturFaturaNo();
    }
  }

  String _olusturFaturaNo() {
    final tip = widget.tipi ?? FaturaTipi.satis;
    final prefix = tip == FaturaTipi.satis ? 'SF' : 'AF';
    final tarih = DateFormat('yyyyMMdd', 'tr_TR').format(DateTime.now());
    return '$prefix-$tarih-001';
  }

  Future<void> _yukleCariHesap(int id) async {
    final cari = await DatabaseHelper.instance.getCariHesap(id);
    if (cari != null) {
      setState(() {
        _seciliCariHesap = cari;
      });
    }
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null) {
      setState(() {
        _tarih = secilen;
        _tarihController.text = DateFormat('dd.MM.yyyy', 'tr_TR').format(_tarih);
      });
    }
  }

  Future<void> _vadeTarihiSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _vadeTarihi ?? _tarih,
      firstDate: _tarih,
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null) {
      setState(() {
        _vadeTarihi = secilen;
        _vadeTarihiController.text = DateFormat('dd.MM.yyyy', 'tr_TR').format(_vadeTarihi!);
      });
    }
  }

  Future<void> _cariHesapSec() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CariHesapListePage()),
    );
    // Cari hesap seçimi için modal dialog kullanılabilir
  }

  void _hesaplaToplamlar() {
    double toplamTutar = 0.0;
    double toplamKdv = 0.0;

    for (var kalem in _kalemler) {
      toplamTutar += kalem.tutar;
      toplamKdv += kalem.kdvTutari;
    }

    setState(() {
      // Toplamlar hesaplandı
    });
  }

  double _getToplamTutar() {
    return _kalemler.fold(0.0, (sum, kalem) => sum + kalem.tutar);
  }

  double _getToplamKdv() {
    return _kalemler.fold(0.0, (sum, kalem) => sum + kalem.kdvTutari);
  }

  double _getGenelToplam() {
    return _getToplamTutar() + _getToplamKdv();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_kalemler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir kalem eklemelisiniz')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fatura = Fatura(
        id: widget.fatura?.id,
        faturaNo: _faturaNoController.text.trim(),
        tipi: widget.fatura?.tipi ?? widget.tipi ?? FaturaTipi.satis,
        cariHesapId: _seciliCariHesap?.id,
        cariHesapUnvan: _seciliCariHesap?.unvan,
        tarih: _tarih,
        vadeTarihi: _vadeTarihi,
        toplamTutar: _getToplamTutar(),
        kdvTutari: _getToplamKdv(),
        genelToplam: _getGenelToplam(),
        aciklama: _aciklamaController.text.trim().isEmpty
            ? null
            : _aciklamaController.text.trim(),
        kalemler: _kalemler,
        olusturmaTarihi: widget.fatura?.olusturmaTarihi,
      );

      if (widget.fatura == null) {
        await DatabaseHelper.instance.insertFatura(fatura);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fatura başarıyla eklendi')),
          );
        }
      } else {
        await DatabaseHelper.instance.updateFatura(fatura);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fatura başarıyla güncellendi')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipi = widget.fatura?.tipi ?? widget.tipi ?? FaturaTipi.satis;
    final tipiText = tipi == FaturaTipi.satis ? 'Satış' : 'Alış';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fatura == null ? 'Yeni $tipiText Faturası' : '$tipiText Faturası Düzenle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _faturaNoController,
                      decoration: const InputDecoration(
                        labelText: 'Fatura No *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Fatura no zorunludur';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tarihController,
                            decoration: const InputDecoration(
                              labelText: 'Tarih *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: _tarihSec,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tarih seçiniz';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _vadeTarihiController,
                            decoration: const InputDecoration(
                              labelText: 'Vade Tarihi',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: _vadeTarihiSec,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_seciliCariHesap?.unvan ?? 'Cari Hesap Seç'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        // Basit bir dialog ile cari hesap seçimi
                        final cariHesaplar = await DatabaseHelper.instance.getAllCariHesaplar();
                        if (mounted && cariHesaplar.isNotEmpty) {
                          final secilen = await showDialog<CariHesap>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cari Hesap Seç'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: cariHesaplar.length,
                                  itemBuilder: (context, index) {
                                    final cari = cariHesaplar[index];
                                    return ListTile(
                                      title: Text(cari.unvan),
                                      onTap: () => Navigator.pop(context, cari),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                          if (secilen != null) {
                            setState(() {
                              _seciliCariHesap = secilen;
                            });
                          }
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aciklamaController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fatura Kalemleri',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _kalemEkle();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Kalem Ekle'),
                        ),
                      ],
                    ),
                    if (_kalemler.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text('Henüz kalem eklenmemiş'),
                        ),
                      )
                    else
                      ..._kalemler.asMap().entries.map((entry) {
                        final index = entry.key;
                        final kalem = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(kalem.stokAdi ?? 'Kalem ${index + 1}'),
                            subtitle: Text(
                              'Miktar: ${kalem.miktar} ${kalem.birim} - Fiyat: ${kalem.birimFiyat.toStringAsFixed(2)} ₺',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${kalem.genelTutar.toStringAsFixed(2)} ₺',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _kalemler.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                            onTap: () => _kalemDuzenle(index),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Ara Toplam:'),
                                Text(
                                  '${_getToplamTutar().toStringAsFixed(2)} ₺',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('KDV Toplam:'),
                                Text(
                                  '${_getToplamKdv().toStringAsFixed(2)} ₺',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Genel Toplam:',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_getGenelToplam().toStringAsFixed(2)} ₺',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _kaydet,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _kalemEkle() {
    _kalemDuzenle(-1);
  }

  void _kalemDuzenle(int index) {
    FaturaKalemi? mevcutKalem;
    if (index >= 0 && index < _kalemler.length) {
      mevcutKalem = _kalemler[index];
    }

    final stokAdiController = TextEditingController(text: mevcutKalem?.stokAdi ?? '');
    final miktarController = TextEditingController(text: mevcutKalem?.miktar.toString() ?? '');
    final birimController = TextEditingController(text: mevcutKalem?.birim ?? 'Adet');
    final birimFiyatController = TextEditingController(text: mevcutKalem?.birimFiyat.toString() ?? '');
    final kdvOraniController = TextEditingController(text: mevcutKalem?.kdvOrani.toString() ?? '20');
    final aciklamaController = TextEditingController(text: mevcutKalem?.aciklama ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void hesapla() {
            final miktar = double.tryParse(miktarController.text.replaceAll(',', '.')) ?? 0.0;
            final birimFiyat = double.tryParse(birimFiyatController.text.replaceAll(',', '.')) ?? 0.0;
            final kdvOrani = double.tryParse(kdvOraniController.text.replaceAll(',', '.')) ?? 20.0;

            final tutar = miktar * birimFiyat;
            final kdvTutari = tutar * (kdvOrani / 100);
            final genelTutar = tutar + kdvTutari;

            setDialogState(() {});
          }

          return AlertDialog(
            title: Text(index >= 0 ? 'Kalem Düzenle' : 'Yeni Kalem'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: stokAdiController,
                    decoration: const InputDecoration(labelText: 'Stok Adı', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: miktarController,
                          decoration: const InputDecoration(labelText: 'Miktar', border: OutlineInputBorder()),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => hesapla(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: birimController,
                          decoration: const InputDecoration(labelText: 'Birim', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: birimFiyatController,
                    decoration: const InputDecoration(labelText: 'Birim Fiyat', border: OutlineInputBorder()),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => hesapla(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: kdvOraniController,
                    decoration: const InputDecoration(labelText: 'KDV Oranı (%)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => hesapla(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aciklamaController,
                    decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final miktar = double.tryParse(miktarController.text.replaceAll(',', '.')) ?? 0.0;
                  final birimFiyat = double.tryParse(birimFiyatController.text.replaceAll(',', '.')) ?? 0.0;
                  final kdvOrani = double.tryParse(kdvOraniController.text.replaceAll(',', '.')) ?? 20.0;

                  final tutar = miktar * birimFiyat;
                  final kdvTutari = tutar * (kdvOrani / 100);
                  final genelTutar = tutar + kdvTutari;

                  final kalem = FaturaKalemi(
                    id: mevcutKalem?.id,
                    stokAdi: stokAdiController.text.trim().isEmpty ? null : stokAdiController.text.trim(),
                    stokId: mevcutKalem?.stokId,
                    miktar: miktar,
                    birim: birimController.text.trim().isEmpty ? 'Adet' : birimController.text.trim(),
                    birimFiyat: birimFiyat,
                    kdvOrani: kdvOrani,
                    tutar: tutar,
                    kdvTutari: kdvTutari,
                    genelTutar: genelTutar,
                    aciklama: aciklamaController.text.trim().isEmpty ? null : aciklamaController.text.trim(),
                  );

                  setState(() {
                    if (index >= 0 && index < _kalemler.length) {
                      _kalemler[index] = kalem;
                    } else {
                      _kalemler.add(kalem);
                    }
                  });

                  Navigator.pop(context);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }
}


