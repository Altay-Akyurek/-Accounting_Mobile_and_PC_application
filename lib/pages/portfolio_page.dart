import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _PortfolioPageState extends State<PortfolioPage> {
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
    _loadPortfolioData();
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
      _completedProjectsCount = allProjects.where((p) => p.durum == ProjectStatus.tamamlandi).length;
      _suspendedProjectsCount = allProjects.where((p) => p.durum == ProjectStatus.askida).length;
      
      _activeWorkers = allWorkers.where((Worker w) => w.aktif).toList();

      // Olayları Topla
      _timelineEvents = [];
      
      // 1. Proje Olayları
      for (var p in allProjects) {
        _timelineEvents.add(_TimelineEvent(
          date: p.baslangicTarihi,
          title: '${p.ad} Başlatıldı',
          type: _TimelineEventType.projectStart,
        ));
        if (p.durum == ProjectStatus.tamamlandi) {
          _timelineEvents.add(_TimelineEvent(
            date: p.olusturmaTarihi.add(const Duration(days: 30)), // Örnek bitiş veya varsa bitiş tarihi
            title: '${p.ad} Tamamlandı',
            type: _TimelineEventType.projectEnd,
          ));
        } else if (p.durum == ProjectStatus.askida) {
           _timelineEvents.add(_TimelineEvent(
            date: DateTime.now(), // Askıya alınma tarihi olmadığı için şimdiki zaman (örnek)
            title: '${p.ad} Askıya Alındı',
            type: _TimelineEventType.projectSuspend,
          ));
        }
      }

      // 2. İşçi Olayları
      for (var w in allWorkers) {
        _timelineEvents.add(_TimelineEvent(
          date: w.baslangicTarihi,
          title: '${w.adSoyad} Ekibe Katıldı',
          type: _TimelineEventType.workerJoin,
        ));
        if (!w.aktif && w.istenCikisTarihi != null) {
          _timelineEvents.add(_TimelineEvent(
            date: w.istenCikisTarihi!,
            title: '${w.adSoyad} Ayrıldı',
            type: _TimelineEventType.workerLeave,
          ));
        }
      }

      // 3. Hakediş Olayları (Tahsil Edilenler)
      for (var h in allHakedisler) {
        if (h.durum == HakedisDurum.tahsilEdildi) {
          _timelineEvents.add(_TimelineEvent(
            date: h.tarih,
            title: '${h.baslik} Tahsil Edildi',
            type: _TimelineEventType.payment,
          ));
        }
      }

      // 4. Gider Olayları (Önemli Giderler)
      for (var gg in allGelirGider) {
        if (gg.tipi == GelirGiderTipi.gider && gg.tutar > 10000) { // Sadece 10000 TL üstü önemli giderleri göster
          _timelineEvents.add(_TimelineEvent(
            date: gg.tarih,
            title: '${gg.baslik} Ödemesi yapıldı',
            type: _TimelineEventType.expense,
          ));
        }
      }

      // Kronolojik sırala ve son 10 olay
      _timelineEvents.sort((a, b) => b.date.compareTo(a.date));
      _timelineEvents = _timelineEvents.take(10).toList();

    } catch (e) {
      debugPrint('Portföy veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Şirket Portföyü')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şirket Portföyü'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPortfolioData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProjectStats(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Şirket Özeti'),
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Finansal Sağlık'),
                    _buildFinancialHealth(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Projelerimiz'),
                    _buildProjectsGrid(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Ekibimiz'),
                    _buildTeamList(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Kilometre Taşları'),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF011627),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.engineering_rounded,
            size: 80,
            color: Color(0xFF2EC4B6),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vizyoner Çözümler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_activeProjectsCount Aktif Proje ile Geleceği İnşa Ediyoruz',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStats() {
    return Row(
      children: [
        _buildStatItem('Aktif', _activeProjectsCount, const Color(0xFF2EC4B6)),
        const SizedBox(width: 8),
        _buildStatItem('Tamamlanan', _completedProjectsCount, Colors.blue),
        const SizedBox(width: 8),
        _buildStatItem('Askıda', _suspendedProjectsCount, Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tahsilat / Borç Oranı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('%${(ratio * 100).toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF2EC4B6))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.red.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2EC4B6)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Yeşil: Tahsilatlar, Kırmızı: Bekleyen Borçlar', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final double revenue = _financialSummary['gelir'] ?? 0;
    final double debt = _financialSummary['gider'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Text(
        'Şirketimiz, finansal yönetim alanında uzman personeliyle sektöre liderlik etmektedir. '
        'Bugüne kadar ${currencyFormat.format(revenue)} değerinde hakediş tahsilatı gerçekleştirilmiş '
        've şu an ${currencyFormat.format(debt)} tutarında işçilik borcu yönetilmektedir.',
        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
      ),
    );
  }

  Widget _buildProjectsGrid() {
    if (_recentProjects.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text('Henüz proje kaydı bulunmuyor.'),
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business_rounded, color: Color(0xFF2EC4B6)),
              const SizedBox(height: 8),
              Text(
                project.ad,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildTeamList() {
    if (_activeWorkers.isEmpty) {
      return const Text('Henüz aktif çalışan bulunmuyor.');
    }

    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Column(
      children: _activeWorkers.map((member) {
        final double debt = _workerDebts[member.adSoyad]?['amount'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFF0F2F5),
                child: Icon(Icons.person, color: Color(0xFF011627)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.adSoyad, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(member.maasTuru == WorkerSalaryType.aylik ? 'Aylık Personel' : 'Yevmiyeli Personel', 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(debt),
                    style: TextStyle(
                      color: debt > 0 ? const Color(0xFFE71D36) : const Color(0xFF2EC4B6),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Bekleyen Maaş',
                    style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMilestones() {
    if (_timelineEvents.isEmpty) {
      return const Text('Kilometre taşı bulunmuyor.');
    }

    return Column(
      children: _timelineEvents.map((event) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  DateFormat('dd MMM yy', 'tr_TR').format(event.date), 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 12),
                Icon(_getEventIcon(event.type), size: 12, color: _getEventColor(event.type)),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.05))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      _getEventSub(event.type),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
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

  String _getEventSub(_TimelineEventType type) {
    switch (type) {
      case _TimelineEventType.projectStart: return 'Yeni Proje Başlatıldı';
      case _TimelineEventType.projectEnd: return 'Proje Başarıyla Tamamlandı';
      case _TimelineEventType.projectSuspend: return 'Proje Geçici Olarak Durduruldu';
      case _TimelineEventType.workerJoin: return 'Yeni Ekip Arkadaşı Katıldı';
      case _TimelineEventType.workerLeave: return 'Ekip Arkadaşı Ayrıldı';
      case _TimelineEventType.payment: return 'Finansal Tahsilat Yapıldı';
      case _TimelineEventType.expense: return 'Yüksek Tutarlı Gider Kaydı';
      default: return 'Bilinmeyen Olay';
    }
  }
}
