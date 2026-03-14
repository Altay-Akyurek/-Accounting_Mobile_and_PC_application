import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/cari_hesap.dart';
import '../services/database_helper.dart';
import '../services/sync_manager.dart';
import 'dart:async';
import 'cari_hesap_ekle_page.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/error_handler.dart';

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
  StreamSubscription? _syncSubscription;
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  final int _perPage = 20;
  List<CariHesap> _displayedCariHesaplar = [];
  Set<int> _workerCariIds = {};

  @override
  void initState() {
    super.initState();
    _yukleCariHesaplar();
    
    _syncSubscription = SyncManager.instance.onSyncCompleted.listen((_) {
      if (mounted) {
        _yukleCariHesaplar();
      }
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    if (_displayedCariHesaplar.length < _filtrelenmisCariHesaplar.length) {
      setState(() {
        int nextCount = _displayedCariHesaplar.length + _perPage;
        if (nextCount > _filtrelenmisCariHesaplar.length) {
          nextCount = _filtrelenmisCariHesaplar.length;
        }
        _displayedCariHesaplar = _filtrelenmisCariHesaplar.sublist(0, nextCount);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _syncSubscription?.cancel();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _yukleCariHesaplar() async {
    setState(() => _isLoading = true);
    try {
      final cariHesaplar = await DatabaseHelper.instance.getAllCariHesaplar();
      final workers = await DatabaseHelper.instance.getAllWorkers();
      setState(() {
        _workerCariIds = workers.map((w) => w.cariHesapId).whereType<int>().toSet();
        _cariHesaplar = cariHesaplar;
        _filtrelenmisCariHesaplar = cariHesaplar;
        _displayedCariHesaplar = _filtrelenmisCariHesaplar.sublist(0, _filtrelenmisCariHesaplar.length > _perPage ? _perPage : _filtrelenmisCariHesaplar.length);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
    }
  }

  void _aramaYap(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _filtrelenmisCariHesaplar = _cariHesaplar.where((cari) {
          final q = query.toLowerCase();
          return cari.unvan.toLowerCase().contains(q) ||
                 (cari.vergiNo?.toLowerCase().contains(q) ?? false) ||
                 (cari.telefon?.toLowerCase().contains(q) ?? false);
        }).toList();
        _displayedCariHesaplar = _filtrelenmisCariHesaplar.sublist(0, _filtrelenmisCariHesaplar.length > _perPage ? _perPage : _filtrelenmisCariHesaplar.length);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildInteractiveHeader(),
          _buildQuickFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _filtrelenmisCariHesaplar.isEmpty
                        ? _buildEmptyState()
                        : _buildCariGrid(),
                  ),
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
        backgroundColor: const Color(0xFF011627),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildInteractiveHeader() {

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF011627),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Text(
                AppLocalizations.of(context)!.cariAccounts.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
              ),
              IconButton(
                onPressed: _yukleCariHesaplar,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _aramaYap,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchCariHint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2EC4B6)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _currentFilter = 'all';

  Widget _buildQuickFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip('all', AppLocalizations.of(context)!.all, Icons.dashboard_rounded),
          _buildFilterChip('receivable', AppLocalizations.of(context)!.customerReceivables, Icons.arrow_downward_rounded),
          _buildFilterChip('payable', AppLocalizations.of(context)!.supplierPayables, Icons.arrow_upward_rounded),
          _buildFilterChip('cash', AppLocalizations.of(context)!.mainCashStatus, Icons.account_balance_wallet_rounded),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, IconData icon) {
    bool isSelected = _currentFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _currentFilter = id;
            _applyComplexFilter();
          });
        },
        selectedColor: const Color(0xFF011627),
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
    );
  }

  void _applyComplexFilter() {
    setState(() {
      _filtrelenmisCariHesaplar = _cariHesaplar.where((cari) {
        // Search filter
        bool matchesSearch = true;
        if (_searchController.text.isNotEmpty) {
          final q = _searchController.text.toLowerCase();
          matchesSearch = cari.unvan.toLowerCase().contains(q) ||
                         (cari.vergiNo?.toLowerCase().contains(q) ?? false);
        }

        if (!matchesSearch) return false;

        // Quick filter
        switch (_currentFilter) {
          case 'receivable': return !cari.isKasa && cari.bakiye < 0;
          case 'payable': return !cari.isKasa && cari.bakiye > 0;
          case 'cash': return cari.isKasa;
          default: return true;
        }
      }).toList();
      _displayedCariHesaplar = _filtrelenmisCariHesaplar.sublist(0, _filtrelenmisCariHesaplar.length > _perPage ? _perPage : _filtrelenmisCariHesaplar.length);
    });
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
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.8,
      ),
      itemCount: _displayedCariHesaplar.length + (_displayedCariHesaplar.length < _filtrelenmisCariHesaplar.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _displayedCariHesaplar.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
        }
        
        final cari = _displayedCariHesaplar[index];
        final bool isWorker = _workerCariIds.contains(cari.id);
        
        return _CariCard(
          cari: cari,
          isWorker: isWorker,
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
  final bool isWorker;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CariCard({
    required this.cari, 
    required this.isWorker,
    required this.onTap, 
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    final bool isReceivable = cari.bakiye < 0;
    final bool isPayable = cari.bakiye > 0;
    final bakiyeColor = isPayable ? const Color(0xFFE71D36) : isReceivable ? const Color(0xFF2EC4B6) : Colors.grey;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bakiyeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          cari.unvan[0].toUpperCase(), 
                          style: TextStyle(color: bakiyeColor, fontWeight: FontWeight.w900, fontSize: 18)
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cari.unvan, 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF011627)), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cari.isKasa 
                              ? AppLocalizations.of(context)!.cashAccount.toUpperCase() 
                              : (isWorker 
                                 ? (AppLocalizations.of(context)!.localeName == 'tr' ? 'ÇALIŞAN' : 'STAFF')
                                 : (isPayable ? (AppLocalizations.of(context)!.localeName == 'tr' ? 'TEDARİKÇİLER' : 'SUPPLIERS') : (AppLocalizations.of(context)!.localeName == 'tr' ? 'MÜŞTERİLER' : 'CUSTOMERS'))),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    _buildPopupMenu(context),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          cari.isKasa ? AppLocalizations.of(context)!.netCashKasa_caps : AppLocalizations.of(context)!.currentBalance_caps, 
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            NumberFormat.currency(
                              locale: Localizations.localeOf(context).toString(),
                              symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : '\$',
                            ).format(cari.bakiye.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.w900, 
                              fontSize: 18, 
                              color: bakiyeColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
