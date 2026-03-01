import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/stok.dart';
import '../services/database_helper.dart';
import 'stok_ekle_page.dart';

class StokListePage extends StatefulWidget {
  const StokListePage({super.key});

  @override
  State<StokListePage> createState() => _StokListePageState();
}

class _StokListePageState extends State<StokListePage> {
  List<Stok> _stoklar = [];
  List<Stok> _filtrelenmisStoklar = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _yukleStoklar();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _yukleStoklar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stoklar = await DatabaseHelper.instance.getAllStoklar();
      setState(() {
        _stoklar = stoklar;
        _filtrelenmisStoklar = stoklar;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _aramaYap(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtrelenmisStoklar = _stoklar;
      } else {
        final lowerQuery = query.toLowerCase();
        _filtrelenmisStoklar = _stoklar.where((stok) {
          return stok.ad.toLowerCase().contains(lowerQuery) ||
              stok.kod.toLowerCase().contains(lowerQuery) ||
              (stok.kategori != null && stok.kategori!.toLowerCase().contains(lowerQuery));
        }).toList();
      }
    });
  }

  Future<void> _silStok(Stok stok) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConfirmTitle),
        content: Text(AppLocalizations.of(context)!.deleteRecordConfirm(stok.ad)),
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

    if (onay == true && stok.id != null) {
      try {
        await DatabaseHelper.instance.deleteStok(stok.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.recordDeleted)),
          );
          _yukleStoklar();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.stockManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StokEklePage()),
              );
              if (result == true) {
                _yukleStoklar();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.search,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _aramaYap('');
                        },
                      )
                    : null,
              ),
              onChanged: _aramaYap,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtrelenmisStoklar.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _stoklar.isEmpty ? AppLocalizations.of(context)!.noStocksYet : AppLocalizations.of(context)!.noSearchResultFound,
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _yukleStoklar,
                        child: ListView.builder(
                          itemCount: _filtrelenmisStoklar.length,
                          itemBuilder: (context, index) {
                            final stok = _filtrelenmisStoklar[index];
                            final kritikSeviye = stok.kritikStokSeviyesi != null &&
                                stok.stokMiktari != null &&
                                stok.stokMiktari! <= stok.kritikStokSeviyesi!;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: kritikSeviye ? Colors.red[50] : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: kritikSeviye ? Colors.red : Colors.blue,
                                  child: Text(
                                    stok.ad.isNotEmpty ? stok.ad[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(stok.ad, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${AppLocalizations.of(context)!.code}: ${stok.kod}'),
                                    if (stok.kategori != null && stok.kategori!.isNotEmpty)
                                      Text('${AppLocalizations.of(context)!.categoryLabel}: ${stok.kategori}'),
                                    Text('${AppLocalizations.of(context)!.stockLabel}: ${stok.stokMiktari ?? 0.0} ${stok.birim}'),
                                    if (stok.satisFiyati != null)
                                      Text('${AppLocalizations.of(context)!.salePriceLabel}: ${NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : '\$', decimalDigits: 2).format(stok.satisFiyati ?? 0.0)}'),
                                  ],
                                ),
                                trailing: PopupMenuButton(
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
                                        MaterialPageRoute(builder: (_) => StokEklePage(stok: stok)),
                                      ).then((result) {
                                        if (result == true) _yukleStoklar();
                                      });
                                    } else if (value == 'delete') {
                                      _silStok(stok);
                                    }
                                  },
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StokEklePage(stok: stok)),
                                  ).then((result) {
                                    if (result == true) _yukleStoklar();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StokEklePage()),
          );
          if (result == true) {
            _yukleStoklar();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


