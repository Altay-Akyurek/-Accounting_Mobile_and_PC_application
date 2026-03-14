import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/database_helper.dart';
import '../models/worker.dart';
import '../models/project.dart';
import '../models/stok.dart';
import '../models/cari_hesap.dart';
import '../models/hakedis.dart';
import '../models/gelir_gider.dart';

enum _TimelineEventType { projectStart, projectEnd, projectSuspend, workerJoin, workerLeave, payment, expense }

class _TimelineEvent {
  final DateTime date;
  final String title;
  final _TimelineEventType type;

  _TimelineEvent({required this.date, required this.title, required this.type});
}

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = true;
  
  int _activeProjectsCount = 0;
  int _completedProjectsCount = 0;
  int _suspendedProjectsCount = 0;
  Map<String, double> _financialSummary = {};
  List<Worker> _activeWorkers = [];
  Map<String, dynamic> _workerDebts = {};
  List<Project> _recentProjects = [];
  List<_TimelineEvent> _timelineEvents = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _loadPortfolioData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolioData() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> results = await Future.wait([
        _db.getAllProjects(),
        _db.getGlobalFinancialSummary(),
        _db.getAllWorkers(),
        _db.getAllHakedisler(),
        _db.getAllGelirGider(),
        _db.getDetailedFinancialAnalysis(
          DateTime.now().subtract(const Duration(days: 365 * 10)), 
          DateTime.now()
        ),
      ]);

      final List<Project> allProjects = results[0] as List<Project>;
      _financialSummary = results[1] as Map<String, double>;
      final List<Worker> allWorkers = results[2] as List<Worker>;
      final List<Hakedis> allHakedisler = results[3] as List<Hakedis>;
      final List<GelirGider> allGelirGider = results[4] as List<GelirGider>;
      final Map<String, dynamic> analysis = results[5] as Map<String, dynamic>;

      _workerDebts = analysis['worker_breakdown'] as Map<String, dynamic>? ?? {};

      _recentProjects = allProjects.reversed.take(4).toList();
      _activeProjectsCount = allProjects.where((p) => p.durum == ProjectStatus.aktif).length;
      _completedProjectsCount = allProjects.where((p) => p.durum == ProjectStatus.bitti).length;
      _suspendedProjectsCount = allProjects.where((p) => p.durum == ProjectStatus.askida).length;
      
      _activeWorkers = allWorkers.where((Worker w) => w.aktif).toList();

      // Olayları Topla
      _timelineEvents = [];
      
      // 1. Proje Olayları
      for (var p in allProjects) {
        _timelineEvents.add(_TimelineEvent(
          date: p.baslangicTarihi,
          title: p.ad,
          type: _TimelineEventType.projectStart,
        ));
        if (p.durum == ProjectStatus.bitti) {
          _timelineEvents.add(_TimelineEvent(
            date: p.olusturmaTarihi.add(const Duration(days: 30)),
            title: p.ad,
            type: _TimelineEventType.projectEnd,
          ));
        } else if (p.durum == ProjectStatus.askida) {
           _timelineEvents.add(_TimelineEvent(
            date: DateTime.now(),
            title: p.ad,
            type: _TimelineEventType.projectSuspend,
          ));
        }
      }

      // 2. İşçi Olayları
      for (var w in allWorkers) {
        _timelineEvents.add(_TimelineEvent(
          date: w.baslangicTarihi,
          title: w.adSoyad,
          type: _TimelineEventType.workerJoin,
        ));
        if (!w.aktif && w.istenCikisTarihi != null) {
          _timelineEvents.add(_TimelineEvent(
            date: w.istenCikisTarihi!,
            title: w.adSoyad,
            type: _TimelineEventType.workerLeave,
          ));
        }
      }

      // 3. Hakediş Olayları (Tahsil Edilenler)
      for (var h in allHakedisler) {
        if (h.durum == HakedisDurum.tahsilEdildi) {
          _timelineEvents.add(_TimelineEvent(
            date: h.tarih,
            title: h.baslik,
            type: _TimelineEventType.payment,
          ));
        }
      }

      // 4. Gider Olayları (Önemli Giderler)
      for (var gg in allGelirGider) {
        if (gg.tipi == GelirGiderTipi.gider && gg.tutar > 10000) {
          _timelineEvents.add(_TimelineEvent(
            date: gg.tarih,
            title: gg.baslik,
            type: _TimelineEventType.expense,
          ));
        }
      }

      // Kronolojik sırala ve son 10 olay
      _timelineEvents.sort((a, b) => b.date.compareTo(a.date));
      _timelineEvents = _timelineEvents.take(10).toList();

    } catch (e) {
      // debugPrint('Portföy veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.companyPortfolio)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.companyPortfolio)),
      body: RefreshIndicator(
        onRefresh: _loadPortfolioData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildHeader(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedSection(0, _buildProjectStats()),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(1, _buildSectionTitle(AppLocalizations.of(context)!.companySummary)),
                    _buildAnimatedSection(1, _buildSummaryCard()),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(2, _buildSectionTitle(AppLocalizations.of(context)!.financialHealth)),
                    _buildAnimatedSection(2, _buildFinancialHealth()),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(3, _buildSectionTitle(AppLocalizations.of(context)!.ourProjects)),
                    _buildAnimatedSection(3, _buildProjectsGrid()),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(4, _buildSectionTitle(AppLocalizations.of(context)!.ourTeam)),
                    _buildTeamList(),
                    const SizedBox(height: 24),
                    _buildAnimatedSection(5, _buildSectionTitle(AppLocalizations.of(context)!.milestones)),
                    _buildMilestones(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(int index, Widget child, {bool useScale = false}) {
    final Animation<double> animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        (0.1 + (index * 0.08)).clamp(0.0, 1.0),
        (0.6 + (index * 0.08)).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
    );

    Widget animatedChild = FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );

    if (useScale) {
      animatedChild = ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
        child: animatedChild,
      );
    }

    return animatedChild;
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF011627), Color(0xFF012A4A)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF011627).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2EC4B6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.engineering_rounded,
              size: 64,
              color: Color(0xFF2EC4B6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.visionarySolutions,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppLocalizations.of(context)!.buildingFutureWithXActiveProjects(_activeProjectsCount),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStats() {
    return Row(
      children: [
        _buildStatItem(AppLocalizations.of(context)!.active, _activeProjectsCount, const Color(0xFF2EC4B6)),
        const SizedBox(width: 8),
        _buildStatItem(AppLocalizations.of(context)!.completed, _completedProjectsCount, Colors.blue),
        const SizedBox(width: 8),
        _buildStatItem(AppLocalizations.of(context)!.suspended, _suspendedProjectsCount, Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Interactive feedback
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.15), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialHealth() {
    final double revenue = _financialSummary['gelir'] ?? 0;
    final double debt = _financialSummary['gider'] ?? 0;
    final double total = revenue + debt;
    final double ratio = total > 0 ? (revenue / total) : 0;

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.collectionDebtRatio,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF011627)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EC4B6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '%${(ratio * 100).toInt()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2EC4B6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _animationController.isAnimating || _animationController.isCompleted
              ? TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: ratio),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.fastOutSlowIn,
                  builder: (context, value, child) {
                    return Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2EC4B6), Color(0xFF2AB7AA)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2EC4B6).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : const SizedBox(height: 12),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.greenCollectionsRedDebts,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF011627),
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final locale = Localizations.localeOf(context).toString();
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: locale,
      symbol: locale == 'tr' ? '₺' : '\$',
      decimalDigits: 0,
    );
    final double revenue = _financialSummary['gelir'] ?? 0;
    final double debt = _financialSummary['gider'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        AppLocalizations.of(context)!.companyOverviewText(currencyFormat.format(revenue), currencyFormat.format(debt)),
        style: TextStyle(
          fontSize: 15,
          height: 1.7,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProjectsGrid() {
    if (_recentProjects.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(AppLocalizations.of(context)!.noProjectRecordsYet),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _recentProjects.length,
      itemBuilder: (context, index) {
        final project = _recentProjects[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EC4B6).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business_rounded, color: Color(0xFF2EC4B6), size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    project.ad,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: -0.2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildTeamList() {
    if (_activeWorkers.isEmpty) {
      return Text(AppLocalizations.of(context)!.noActiveWorkersYet);
    }

    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Column(
      children: List.generate(_activeWorkers.length, (index) {
        final member = _activeWorkers[index];
        final double debt = _workerDebts[member.adSoyad]?['amount'] ?? 0;

        return _buildAnimatedSection(4 + index, Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade50),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  _buildAnimatedSection(index + 5, Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF011627).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF011627), size: 24),
                  ), useScale: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.adSoyad,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.maasTuru == WorkerSalaryType.aylik ? AppLocalizations.of(context)!.monthlyPersonnel : AppLocalizations.of(context)!.dailyPersonnel, 
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: debt > 0 ? const Color(0xFFE71D36).withOpacity(0.08) : const Color(0xFF2EC4B6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(debt),
                          style: TextStyle(
                            color: debt > 0 ? const Color(0xFFE71D36) : const Color(0xFF2EC4B6),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.pendingSalary.toUpperCase(),
                          style: TextStyle(
                            color: debt > 0 ? const Color(0xFFE71D36).withOpacity(0.6) : const Color(0xFF2EC4B6).withOpacity(0.6),
                            fontSize: 9, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ), useScale: true);
      }).toList(),
    );
  }

  Widget _buildMilestones() {
    if (_timelineEvents.isEmpty) {
      return Text(AppLocalizations.of(context)!.noMilestonesYet);
    }

    return Column(
      children: List.generate(_timelineEvents.length, (index) {
        final event = _timelineEvents[index];
        final color = _getEventColor(event.type);
        return _buildAnimatedSection(6 + index, Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('dd MMM', Localizations.localeOf(context).toString()).format(event.date), 
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade800, fontSize: 12)
                    ),
                    Text(
                      DateFormat('yyyy', Localizations.localeOf(context).toString()).format(event.date), 
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade400, fontSize: 10)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                const SizedBox(height: 14),
                _buildAnimatedSection(index + 7, Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
                ), useScale: true),
                Container(
                  width: 2,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withOpacity(0.3), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedSection(index + 8, Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade50),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getEventIcon(event.type), size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getEventSubText(context, event),
                                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ),
          ],
        ), useScale: true);
      }).toList(),
    );
  }

  IconData _getEventIcon(_TimelineEventType type) {
    switch (type) {
      case _TimelineEventType.projectStart: return Icons.rocket_launch_rounded;
      case _TimelineEventType.projectEnd: return Icons.check_circle_rounded;
      case _TimelineEventType.projectSuspend: return Icons.pause_circle_rounded;
      case _TimelineEventType.workerJoin: return Icons.person_add_rounded;
      case _TimelineEventType.workerLeave: return Icons.person_remove_rounded;
      case _TimelineEventType.payment: return Icons.payments_rounded;
      case _TimelineEventType.expense: return Icons.shopping_cart_checkout_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  Color _getEventColor(_TimelineEventType type) {
    switch (type) {
      case _TimelineEventType.projectStart: return const Color(0xFF2EC4B6);
      case _TimelineEventType.projectEnd: return Colors.blue;
      case _TimelineEventType.projectSuspend: return Colors.orange;
      case _TimelineEventType.workerJoin: return Colors.indigo;
      case _TimelineEventType.workerLeave: return Colors.red;
      case _TimelineEventType.payment: return Colors.green;
      case _TimelineEventType.expense: return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  String _getEventSubText(BuildContext context, _TimelineEvent event) {
    switch (event.type) {
      case _TimelineEventType.projectStart: return AppLocalizations.of(context)!.newProjectStarted;
      case _TimelineEventType.projectEnd: return AppLocalizations.of(context)!.projectCompletedSuccessfully;
      case _TimelineEventType.projectSuspend: return AppLocalizations.of(context)!.projectSuspendedTemporarily;
      case _TimelineEventType.workerJoin: return AppLocalizations.of(context)!.newTeamMemberJoined;
      case _TimelineEventType.workerLeave: return AppLocalizations.of(context)!.teamMemberLeft;
      case _TimelineEventType.payment: return AppLocalizations.of(context)!.financialCollectionMade;
      case _TimelineEventType.expense: return AppLocalizations.of(context)!.highAmountExpenseRecord;
      default: return AppLocalizations.of(context)!.unknownEvent;
    }
  }
}
