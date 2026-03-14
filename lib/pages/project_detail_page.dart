import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../models/hakedis.dart';
import '../models/gelir_gider.dart';
import '../models/cari_islem.dart';
import '../models/worker.dart';
import '../services/database_helper.dart';
import '../services/project_export_service.dart';
import '../services/premium_manager.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/error_handler.dart';

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

  double _toplamGider = 0;
  double _netKar = 0;
  double _tahsilEdilenHakedis = 0;
  double _toplamHakedis = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final hakedisler = await DatabaseHelper.instance.getHakedisByProjectId(widget.project.id!);
    final gelirGiderler = await DatabaseHelper.instance.getGelirGiderByProjectId(widget.project.id!);
    final cariIslemler = await DatabaseHelper.instance.getCariIslemlerByProjectId(widget.project.id!);
    final puantajlar = await DatabaseHelper.instance.getPuantajByProjectId(widget.project.id!);
    final workers = await DatabaseHelper.instance.getAllWorkers();

    if (!mounted) return;

    double gelir = 0;
    double gider = 0;
    double tahsilEdilen = 0;
    double toplamH = 0;

    for (var h in hakedisler) {
      toplamH += h.netTutar;
      if (h.durum == HakedisDurum.tahsilEdildi) {
        gelir += h.netTutar;
        tahsilEdilen += h.netTutar;
      }
    }

    for (var gg in gelirGiderler) {
      if (gg.tipi == GelirGiderTipi.gelir) gelir += gg.tutar;
      if (gg.tipi == GelirGiderTipi.gider) gider += gg.tutar;
    }

    for (var islem in cariIslemler) {
      if (!(islem.aciklama.contains('Hakediş Tahsilatı'))) {
        gelir += islem.borc;
      }
      gider += islem.alacak;
    }

    for (var p in puantajlar) {
      final worker = workers.firstWhere((w) => w.id == p.workerId, orElse: () => Worker(adSoyad: AppLocalizations.of(context)!.unknown, baslangicTarihi: DateTime.now()));
      gider += DatabaseHelper.instance.calculateLaborCost(p, worker);
    }

    setState(() {
      _hakedisler = hakedisler;
      _gelirGiderler = gelirGiderler;
      _cariIslemler = cariIslemler;
      _puantajlar = puantajlar;
      _workers = workers;
      _toplamGider = gider;
      _toplamHakedis = toplamH;
      _netKar = gelir - gider;
      _tahsilEdilenHakedis = tahsilEdilen;
      _isLoading = false;
    });
  }

  String _formatPara(double tutar) {
    if (!mounted) return "0.00";
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.currency(
      locale: locale,
      symbol: locale == 'tr' ? '₺' : '\$',
      decimalDigits: 2,
    ).format(tutar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverHeader(),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    Container(
                      color: const Color(0xFF011627),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF2EC4B6),
                        indicatorWeight: 4,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
                        tabs: [
                          Tab(text: AppLocalizations.of(context)!.summary.toUpperCase()),
                          Tab(text: AppLocalizations.of(context)!.hakedisler.toUpperCase()),
                          Tab(text: AppLocalizations.of(context)!.expenses.toUpperCase()),
                        ],
                        onTap: (index) => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildHakedisTab(),
                  _buildExpensesTab(),
                ],
              ),
            ),
      floatingActionButton: _tabController.index == 1 
          ? FloatingActionButton.extended(
              onPressed: _showAddHakedisDialog,
              icon: const Icon(Icons.add_chart_rounded),
              label: Text(AppLocalizations.of(context)!.newHakedis.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              backgroundColor: const Color(0xFF011627),
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF011627),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white70),
          onPressed: () {
             if (PremiumManager.instance.checkPremium(context)) {
                  final l10n = AppLocalizations.of(context)!;
                  final sortedHakedisler = List<Hakedis>.from(_hakedisler)..sort((a, b) => b.tarih.compareTo(a.tarih));
                  ProjectExportService.exportProjectHakedislerPDF(l10n, widget.project, sortedHakedisler);
                }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EC4B6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  widget.project.ad.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF2EC4B6), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.netProfit.toUpperCase(),
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2.0),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatPara(_netKar),
                  style: TextStyle(
                    color: _netKar >= 0 ? const Color(0xFF2EC4B6) : const Color(0xFFFF3366),
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderSmallStat(AppLocalizations.of(context)!.collected, _formatPara(_tahsilEdilenHakedis), Icons.check_circle_rounded, CrossAxisAlignment.start),
                    _buildHeaderSmallStat(AppLocalizations.of(context)!.totalExpense, _formatPara(_toplamGider), Icons.trending_down_rounded, CrossAxisAlignment.end),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSmallStat(String label, String value, IconData icon, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (align == CrossAxisAlignment.start) ...[Icon(icon, size: 12, color: Colors.white30), const SizedBox(width: 4)],
            Text(label.toUpperCase(), style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            if (align == CrossAxisAlignment.end) ...[const SizedBox(width: 4), Icon(icon, size: 12, color: Colors.white30)],
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final butceKullanimi = widget.project.toplamButce > 0 ? (_toplamGider / widget.project.toplamButce) : 0.0;
    final karOrani = (_tahsilEdilenHakedis > 0) ? (_netKar / _tahsilEdilenHakedis * 100) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildBudgetCard(butceKullanimi),
        const SizedBox(height: 16),
        _buildProfitabilityCard(karOrani),
        const SizedBox(height: 24),
        _buildInfoSection(),
      ],
    );
  }

  Widget _buildBudgetCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.projectBudgetUsage.toUpperCase(), style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(height: 24),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress > 1 ? 1 : progress,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFF2EC4B6).withOpacity(0.1),
                      color: progress > 1 ? Colors.orange : const Color(0xFF2EC4B6),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text("${(progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF011627))),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(fit: BoxFit.scaleDown, child: Text(_formatPara(_toplamGider), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF011627)))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "/ ${_formatPara(widget.project.toplamButce)}", 
                        style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 13)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitabilityCard(double ratio) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ratio >= 0 ? const Color(0xFF2EC4B6) : const Color(0xFFFF3366),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.profitabilityRatio.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900)),
                Text("%${ratio.toStringAsFixed(1)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.projectDetails.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
          const SizedBox(height: 24),
          _buildDetailRow(AppLocalizations.of(context)!.startingDate, DateFormat('dd.MM.yyyy').format(widget.project.baslangicTarihi)),
          _buildDetailRow(
            AppLocalizations.of(context)!.status, 
            widget.project.durum.name.toUpperCase(),
            isStatus: true,
          ),
          _buildDetailRow(AppLocalizations.of(context)!.description, widget.project.aciklama ?? AppLocalizations.of(context)!.notEntered),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 13)),
          GestureDetector(
            onTap: isStatus ? _showStatusPicker : null,
            child: Row(
              children: [
                Text(
                  value, 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    color: isStatus ? const Color(0xFF2EC4B6) : const Color(0xFF011627), 
                    fontSize: 13
                  )
                ),
                if (isStatus) const SizedBox(width: 4),
                if (isStatus) const Icon(Icons.edit_note_rounded, color: Color(0xFF2EC4B6), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.changeProjectStatus.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
            const SizedBox(height: 24),
            _buildStatusOption(ProjectStatus.aktif, AppLocalizations.of(context)!.active, Icons.play_circle_fill_rounded, const Color(0xFF2EC4B6)),
            _buildStatusOption(ProjectStatus.askida, AppLocalizations.of(context)!.suspended, Icons.pause_circle_filled_rounded, Colors.orange),
            _buildStatusOption(ProjectStatus.bitti, AppLocalizations.of(context)!.completed, Icons.check_circle_rounded, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(ProjectStatus status, String label, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () async {
        widget.project.durum = status;
        await DatabaseHelper.instance.updateProject(widget.project);
        if (mounted) {
          Navigator.pop(context);
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.statusUpdated(label))),
          );
        }
      },
    );
  }

  Widget _buildHakedisTab() {
    if (_hakedisler.isEmpty) return _buildEmptyState(Icons.receipt_long_rounded, AppLocalizations.of(context)!.noHakedisYet);
    final sorted = List<Hakedis>.from(_hakedisler)..sort((a, b) => b.tarih.compareTo(a.tarih));
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _buildTransactionCard(sorted[index]),
    );
  }

  Widget _buildTransactionCard(Hakedis h) {
    final isCollected = h.durum == HakedisDurum.tahsilEdildi;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCollected ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isCollected ? Icons.check_circle_rounded : Icons.history_rounded, color: isCollected ? Colors.green : Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.baslik, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF011627))),
                Text(DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(h.tarih), style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatPara(h.netTutar), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF011627))),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCollected ? AppLocalizations.of(context)!.collected_caps : AppLocalizations.of(context)!.pending_caps,
                    style: TextStyle(color: isCollected ? Colors.green : Colors.orange, fontWeight: FontWeight.w900, fontSize: 9),
                  ),
                  const SizedBox(width: 8),
                  _buildHakedisActions(h),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHakedisActions(Hakedis h) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
      onSelected: (val) async {
        if (val == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.delete),
              content: Text(AppLocalizations.of(context)!.deleteHakedisConfirm(h.baslik)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (confirm == true) {
            await DatabaseHelper.instance.deleteHakedis(h.id!);
            _loadData();
          }
        } else if (val == 'status') {
          h.durum = h.durum == HakedisDurum.tahsilEdildi ? HakedisDurum.bekliyor : HakedisDurum.tahsilEdildi;
          await DatabaseHelper.instance.updateHakedis(h);
          _loadData();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              Icon(h.durum == HakedisDurum.tahsilEdildi ? Icons.pending_actions_rounded : Icons.check_circle_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Text(h.durum == HakedisDurum.tahsilEdildi ? AppLocalizations.of(context)!.markAsPending : AppLocalizations.of(context)!.markAsCollected),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    final List<Map<String, dynamic>> allExpenses = [];
    for (var gg in _gelirGiderler) if (gg.tipi == GelirGiderTipi.gider) allExpenses.add({'id': gg.id, 'name': gg.baslik, 'amount': gg.tutar, 'date': gg.tarih, 'type': 'GİDER', 'model': gg});
    for (var islem in _cariIslemler) if (islem.alacak > 0) allExpenses.add({'id': islem.id, 'name': islem.aciklama, 'amount': islem.alacak, 'date': islem.tarih, 'type': 'CARİ', 'model': islem});
    for (var p in _puantajlar) {
      final worker = _workers.firstWhere((w) => w.id == p.workerId, orElse: () => Worker(adSoyad: AppLocalizations.of(context)!.unknown, baslangicTarihi: DateTime.now()));
      allExpenses.add({'id': p.id, 'name': AppLocalizations.of(context)!.laborPayment, 'amount': DatabaseHelper.instance.calculateLaborCost(p, worker), 'date': p.tarih, 'type': 'İŞÇİLİK', 'subtitle': 'Puantaj Kaydı (${worker.adSoyad})', 'model': p});
    }
    allExpenses.sort((a,b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (allExpenses.isEmpty) return _buildEmptyState(Icons.payments_rounded, AppLocalizations.of(context)!.noExpensesYet);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: allExpenses.length,
      itemBuilder: (context, index) {
        final exp = allExpenses[index];
        Color iconColor = const Color(0xFFFF3366);
        IconData iconData = Icons.remove_circle_outline_rounded;

        if (exp['type'] == 'CARİ') {
          iconColor = Colors.blue;
          iconData = Icons.sync_alt_rounded;
        } else if (exp['type'] == 'İŞÇİLİK') {
          iconColor = Colors.purple;
          iconData = Icons.engineering_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.08), shape: BoxShape.circle),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exp['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF011627))),
                    Text(
                      exp['subtitle'] ?? '${exp['type'] == 'CARİ' ? (exp['model'] as CariIslem).cariHesapUnvan ?? 'Cari' : exp['type']} • ${DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(exp['date'] as DateTime)}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "- ${_formatPara(exp['amount'] as double)}",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFFFF3366)),
                  ),
                  if (exp['type'] != 'İŞÇİLİK') 
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                      onPressed: () => _deleteExpense(exp),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteExpense(Map<String, dynamic> exp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text(AppLocalizations.of(context)!.deleteRecordConfirm(exp['name'])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      if (exp['type'] == 'GİDER') {
        await DatabaseHelper.instance.deleteGelirGider(exp['id']);
      } else if (exp['type'] == 'CARİ') {
        await DatabaseHelper.instance.deleteCariIslem(exp['id']);
      }
      _loadData();
    }
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddHakedisDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final kdvController = TextEditingController();
    final stopajController = TextEditingController();
    final teminatController = TextEditingController();
    final noteController = TextEditingController();
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.hakedisEntry,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF011627), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 32),
                  _buildAddHakedisInput(
                    controller: titleController,
                    icon: Icons.title_rounded,
                    hint: AppLocalizations.of(context)!.hakedisTitle,
                  ),
                  const SizedBox(height: 16),
                  _buildAddHakedisInput(
                    controller: amountController,
                    icon: Icons.payments_rounded,
                    hint: AppLocalizations.of(context)!.hakedisAmountExcVat,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Vergi ve Kesinti Oranları (%)",
                    style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildAddHakedisInput(controller: kdvController, hint: 'KDV', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAddHakedisInput(controller: stopajController, hint: 'Stopaj', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAddHakedisInput(controller: teminatController, hint: 'Teminat', keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: Color(0xFF011627), onPrimary: Colors.white, onSurface: Color(0xFF011627)),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF011627), size: 24),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hakediş Tarihi", style: TextStyle(color: Colors.black.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(selectedDate),
                              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildAddHakedisInput(
                    controller: noteController,
                    icon: Icons.notes_rounded,
                    hint: "Açıklama / Not (Opsiyonel)",
                    maxLines: 3,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                        try {
                          final h = Hakedis(
                            projectId: widget.project.id!,
                            projectAd: widget.project.ad,
                            baslik: titleController.text,
                            tutar: double.parse(amountController.text.replaceAll(',', '.')),
                            kdvOrani: double.tryParse(kdvController.text) ?? 20.0,
                            stopajOrani: double.tryParse(stopajController.text) ?? 0.0,
                            teminatOrani: double.tryParse(teminatController.text) ?? 0.0,
                            tarih: selectedDate,
                            aciklama: noteController.text,
                          );
                          await DatabaseHelper.instance.insertHakedis(h);
                          if (mounted) {
                            Navigator.pop(context);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.projectCreated), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e)), backgroundColor: Colors.red));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.enterProjectName)));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF011627),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFF011627).withOpacity(0.4),
                    ),
                    child: Text("HAKEDİŞİ KAYDET", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddHakedisInput({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade700, size: 22) : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF011627), width: 1.5)),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label.toUpperCase(), style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  InputDecoration _inputDecoration(IconData icon, {String? suffix, String? hint}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF2EC4B6), size: 18),
      suffixText: suffix,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2EC4B6))),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
