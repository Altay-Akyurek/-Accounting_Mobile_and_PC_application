import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fatura.dart';
import '../services/database_helper.dart';
import 'fatura_ekle_page.dart';

class FaturaListePage extends StatefulWidget {
  const FaturaListePage({super.key});

  @override
  State<FaturaListePage> createState() => _FaturaListePageState();
}

class _FaturaListePageState extends State<FaturaListePage> with SingleTickerProviderStateMixin {
  List<Fatura> _faturalar = [];
  List<Fatura> _filtrelenmisFaturalar = [];
  bool _isLoading = true;
  late TabController _tabController;
  FaturaTipi _seciliTip = FaturaTipi.satis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _seciliTip = _tabController.index == 0 ? FaturaTipi.satis : FaturaTipi.alis;
          _filtrele();
        });
      }
    });
    _yukleFaturalar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _yukleFaturalar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final faturalar = await DatabaseHelper.instance.getAllFaturalar();
      setState(() {
        _faturalar = faturalar;
        _filtrele();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _filtrele() {
    setState(() {
      _filtrelenmisFaturalar = _faturalar.where((f) => f.tipi == _seciliTip).toList();
    });
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
        title: const Text('Faturalar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Satış Faturaları', icon: Icon(Icons.arrow_upward)),
            Tab(text: 'Alış Faturaları', icon: Icon(Icons.arrow_downward)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FaturaEklePage(tipi: _seciliTip),
                ),
              );
              if (result == true) {
                _yukleFaturalar();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filtrelenmisFaturalar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz fatura eklenmemiş',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _yukleFaturalar,
                  child: ListView.builder(
                    itemCount: _filtrelenmisFaturalar.length,
                    itemBuilder: (context, index) {
                      final fatura = _filtrelenmisFaturalar[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _seciliTip == FaturaTipi.satis ? Colors.green : Colors.blue,
                            child: Text(
                              fatura.faturaNo.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            fatura.faturaNo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fatura.cariHesapUnvan != null && fatura.cariHesapUnvan!.isNotEmpty)
                                Text('Cari: ${fatura.cariHesapUnvan}'),
                              Text('Tarih: ${DateFormat('dd.MM.yyyy', 'tr_TR').format(fatura.tarih)}'),
                              Text(
                                'Toplam: ${_formatPara(fatura.genelToplam)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _seciliTip == FaturaTipi.satis ? Colors.green : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Düzenle'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Sil', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FaturaEklePage(fatura: fatura),
                                  ),
                                ).then((result) {
                                  if (result == true) _yukleFaturalar();
                                });
                              } else if (value == 'delete') {
                                _silFatura(fatura);
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FaturaEklePage(fatura: fatura),
                              ),
                            ).then((result) {
                              if (result == true) _yukleFaturalar();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FaturaEklePage(tipi: _seciliTip),
            ),
          );
          if (result == true) {
            _yukleFaturalar();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _silFatura(Fatura fatura) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text('${fatura.faturaNo} numaralı faturayı silmek istediğinize emin misiniz?'),
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

    if (onay == true && fatura.id != null) {
      try {
        await DatabaseHelper.instance.deleteFatura(fatura.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fatura silindi')),
          );
          _yukleFaturalar();
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
}


