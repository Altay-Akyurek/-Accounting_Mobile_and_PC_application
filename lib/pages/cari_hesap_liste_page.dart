import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/cari_hesap.dart';
import '../services/database_helper.dart';
import 'cari_hesap_ekle_page.dart';
import '../widgets/banner_ad_widget.dart';

class CariHesapListePage extends StatefulWidget {
  const CariHesapListePage({super.key});

  @override
  State<CariHesapListePage> createState() => _CariHesapListePageState();
}

class _CariHesapListePageState extends State<CariHesapListePage> {
  List<CariHesap> _cariHesaplar = [];
  List<CariHesap> _filtrelenmisCariHesaplar = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _yukleCariHesaplar();
  }

  Future<void> _yukleCariHesaplar() async {
    setState(() => _isLoading = true);
    try {
      final cariHesaplar = await DatabaseHelper.instance.getAllCariHesaplar();
      setState(() {
        _cariHesaplar = cariHesaplar;
        _filtrelenmisCariHesaplar = cariHesaplar;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString()))));
    }
  }

  void _aramaYap(String query) {
    setState(() {
      _filtrelenmisCariHesaplar = _cariHesaplar.where((cari) {
        final q = query.toLowerCase();
        return cari.unvan.toLowerCase().contains(q) ||
               (cari.vergiNo?.toLowerCase().contains(q) ?? false) ||
               (cari.telefon?.toLowerCase().contains(q) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cariAccounts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _yukleCariHesaplar,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtrelenmisCariHesaplar.isEmpty
                    ? _buildEmptyState()
                    : _buildCariGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CariHesapEklePage()),
          );
          if (result == true) _yukleCariHesaplar();
        },
        icon: const Icon(Icons.person_add_rounded),
        label: Text(AppLocalizations.of(context)!.addNewCari),
        backgroundColor: const Color(0xFF003399),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF003399),
      child: TextField(
        controller: _searchController,
        onChanged: _aramaYap,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchCariHint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          Text(
            _cariHesaplar.isEmpty ? AppLocalizations.of(context)!.noCariAccountsYet : AppLocalizations.of(context)!.noResultsFound,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCariGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.8,
      ),
      itemCount: _filtrelenmisCariHesaplar.length,
      itemBuilder: (context, index) {
        final cari = _filtrelenmisCariHesaplar[index];
        return _CariCard(
          cari: cari,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CariHesapEklePage(cariHesap: cari)),
            );
            if (result == true) _yukleCariHesaplar();
          },
          onDelete: () => _silCariOnay(cari),
        );
      },
    );
  }

  Future<void> _silCariOnay(CariHesap cari) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConfirmTitle),
        content: Text(AppLocalizations.of(context)!.deleteCariConfirm(cari.unvan)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel_caps)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete_caps),
          ),
        ],
      ),
    );

    if (onay == true && cari.id != null) {
      try {
        await DatabaseHelper.instance.deleteCariHesap(cari.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.cariAccountDeleted)),
          );
          _yukleCariHesaplar();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.deleteFailed(e.toString()))),
          );
        }
      }
    }
  }
}

class _CariCard extends StatelessWidget {
  final CariHesap cari;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CariCard({required this.cari, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bakiyeColor = cari.bakiye > 0 ? Colors.red : cari.bakiye < 0 ? Colors.green : Colors.grey;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF003399).withOpacity(0.1),
                    child: Text(cari.unvan[0].toUpperCase(), style: const TextStyle(color: Color(0xFF003399), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cari.unvan, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (cari.vergiNo != null && cari.vergiNo!.isNotEmpty)
                          Text('${AppLocalizations.of(context)!.taxNo_short}: ${cari.vergiNo}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cari.isKasa ? AppLocalizations.of(context)!.netCashKasa_caps : AppLocalizations.of(context)!.currentBalance_caps, 
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: Localizations.localeOf(context).toString(),
                            symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : '\$',
                          ).format(cari.bakiye),
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: bakiyeColor),
                        ),
                      ],
                    ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
