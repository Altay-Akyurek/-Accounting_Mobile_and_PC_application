import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/gelir_gider.dart';
import '../services/database_helper.dart';
import 'gelir_gider_ekle_page.dart';

class GelirGiderListePage extends StatefulWidget {
  const GelirGiderListePage({super.key});

  @override
  State<GelirGiderListePage> createState() => _GelirGiderListePageState();
}

class _GelirGiderListePageState extends State<GelirGiderListePage> with SingleTickerProviderStateMixin {
  List<GelirGider> _gelirGiderler = [];
  List<GelirGider> _filtrelenmisGelirGiderler = [];
  bool _isLoading = true;
  late TabController _tabController;
  GelirGiderTipi _seciliTip = GelirGiderTipi.gelir;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _seciliTip = _tabController.index == 0 ? GelirGiderTipi.gelir : GelirGiderTipi.gider;
          _filtrele();
        });
      }
    });
    _yukleGelirGiderler();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _yukleGelirGiderler() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gelirGiderler = await DatabaseHelper.instance.getAllGelirGider();
      setState(() {
        _gelirGiderler = gelirGiderler;
        _filtrele();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filtrele() {
    setState(() {
      _filtrelenmisGelirGiderler = _gelirGiderler.where((g) => g.tipi == _seciliTip).toList();
    });
  }

  String _formatPara(double tutar) {
    final locale = Localizations.localeOf(context).toString();
    try {
      return NumberFormat.currency(
        locale: locale,
        symbol: locale == 'tr' ? '₺' : '\$',
        decimalDigits: 2,
      ).format(tutar);
    } catch (e) {
      return (locale == 'tr' ? '₺' : '\$') + tutar.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.incomeExpense),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.incomes, icon: const Icon(Icons.trending_up)),
            Tab(text: AppLocalizations.of(context)!.expenses, icon: const Icon(Icons.trending_down)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GelirGiderEklePage(tipi: _seciliTip),
                ),
              );
              if (result == true) {
                _yukleGelirGiderler();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filtrelenmisGelirGiderler.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _seciliTip == GelirGiderTipi.gelir ? Icons.trending_up : Icons.trending_down,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noIncomeExpenseYet(_seciliTip == GelirGiderTipi.gelir ? AppLocalizations.of(context)!.income : AppLocalizations.of(context)!.expense),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _yukleGelirGiderler,
                  child: ListView.builder(
                    itemCount: _filtrelenmisGelirGiderler.length,
                    itemBuilder: (context, index) {
                      final item = _filtrelenmisGelirGiderler[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.tipi == GelirGiderTipi.gelir ? Colors.green : Colors.red,
                            child: Icon(
                              item.tipi == GelirGiderTipi.gelir ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(item.baslik, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.kategori != null && item.kategori!.isNotEmpty)
                                Text('${AppLocalizations.of(context)!.categoryLabel}: ${item.kategori}'),
                              if (item.cariHesapUnvan != null && item.cariHesapUnvan!.isNotEmpty)
                                Text('${AppLocalizations.of(context)!.cariLabel}: ${item.cariHesapUnvan}'),
                              Text('${AppLocalizations.of(context)!.dateLabel}: ${DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(item.tarih)}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatPara(item.tutar),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: item.tipi == GelirGiderTipi.gelir ? Colors.green : Colors.red,
                                ),
                              ),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text(AppLocalizations.of(context)!.edit),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GelirGiderEklePage(gelirGider: item),
                                      ),
                                    ).then((result) {
                                      if (result == true) _yukleGelirGiderler();
                                    });
                                  } else if (value == 'delete') {
                                    _silGelirGider(item);
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GelirGiderEklePage(gelirGider: item),
                              ),
                            ).then((result) {
                              if (result == true) _yukleGelirGiderler();
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
              builder: (_) => GelirGiderEklePage(tipi: _seciliTip),
            ),
          );
          if (result == true) {
            _yukleGelirGiderler();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _silGelirGider(GelirGider item) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConfirmTitle),
        content: Text(AppLocalizations.of(context)!.deleteRecordConfirm(item.baslik)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (onay == true && item.id != null) {
      try {
        await DatabaseHelper.instance.deleteGelirGider(item.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.recordDeleted)),
          );
          _yukleGelirGiderler();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString()))),
          );
        }
      }
    }
  }
}


