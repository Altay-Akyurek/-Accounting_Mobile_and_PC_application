import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../services/database_helper.dart';
import '../services/sync_manager.dart';
import 'dart:async';
import 'project_detail_page.dart';
import '../models/cari_hesap.dart';
import '../widgets/cari_ekle_dialog.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/error_handler.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<Project> _projects = [];
  List<CariHesap> _cariHesaplar = [];
  ProjectStatus? _filterStatus;
  bool _isLoading = true;
  StreamSubscription? _syncSubscription;
  final ScrollController _scrollController = ScrollController();
  final int _perPage = 20;
  List<Project> _displayedProjects = [];
  List<Project> _filteredProjects = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
    
    _syncSubscription = SyncManager.instance.onSyncCompleted.listen((_) {
      if (mounted) {
        _loadProjects();
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
    if (_displayedProjects.length < _filteredProjects.length) {
      setState(() {
        int nextCount = _displayedProjects.length + _perPage;
        if (nextCount > _filteredProjects.length) {
          nextCount = _filteredProjects.length;
        }
        _displayedProjects = _filteredProjects.sublist(0, nextCount);
      });
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await DatabaseHelper.instance.getAllProjects();
    final cariler = await DatabaseHelper.instance.getAllCariHesaplar();
    setState(() {
      _projects = projects;
      _cariHesaplar = cariler;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    _filteredProjects = _projects.where((p) {
      bool matchesStatus = _filterStatus == null || p.durum == _filterStatus;
      bool matchesSearch = p.ad.toLowerCase().contains(query) || 
                          (p.cariHesapUnvan?.toLowerCase().contains(query) ?? false);
      return matchesStatus && matchesSearch;
    }).toList();
    
    _displayedProjects = _filteredProjects.sublist(
      0, 
      _filteredProjects.length > _perPage ? _perPage : _filteredProjects.length
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverHeader(),
                SliverToBoxAdapter(child: _buildStatusFilter()),
                if (_filteredProjects.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _displayedProjects.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                          }
                          final project = _displayedProjects[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _ProjectCard(
                              project: project,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProjectDetailPage(project: project)),
                                );
                                _loadProjects();
                              },
                              onDelete: () => _confirmDeleteProject(project),
                            ),
                          );
                        },
                        childCount: _displayedProjects.length + (_displayedProjects.length < _filteredProjects.length ? 1 : 0),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProjectDialog,
        icon: const Icon(Icons.add_business_rounded),
        label: Text(AppLocalizations.of(context)!.newProjectCard.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        backgroundColor: const Color(0xFF011627),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF011627),
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 32, left: 24, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        AppLocalizations.of(context)!.projects.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2.0),
                      ),
                    ),
                  IconButton(
                    onPressed: _loadProjects,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildHeaderStat(AppLocalizations.of(context)!.all, _projects.length.toString(), Icons.layers_rounded),
                  const SizedBox(width: 12),
                  _buildHeaderStat(
                    AppLocalizations.of(context)!.active, 
                    _projects.where((p) => p.durum == ProjectStatus.aktif).length.toString(), 
                    Icons.play_circle_filled_rounded,
                    color: const Color(0xFF2EC4B6)
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() => _applyFilter()),
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
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon, {Color color = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.withOpacity(0.5), size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w900)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip(null, AppLocalizations.of(context)!.all),
          _buildFilterChip(ProjectStatus.aktif, AppLocalizations.of(context)!.active),
          _buildFilterChip(ProjectStatus.askida, AppLocalizations.of(context)!.suspended),
          _buildFilterChip(ProjectStatus.bitti, AppLocalizations.of(context)!.completed),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ProjectStatus? status, String label) {
    bool isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        onSelected: (val) => setState(() {
          _filterStatus = status;
          _applyFilter();
        }),
        selectedColor: const Color(0xFF011627),
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          Text(
            _filterStatus == null 
              ? AppLocalizations.of(context)!.noProjectsDefined 
              : AppLocalizations.of(context)!.noProjectsInStatus(_filterStatus!.name),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(AppLocalizations.of(context)!.deleteProject, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(AppLocalizations.of(context)!.deleteProjectConfirm(project.ad)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel_caps, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete_caps, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirmed == true && project.id != null) {
      await DatabaseHelper.instance.deleteProject(project.id!);
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.projectDeleted), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddProjectDialog() {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    ProjectStatus selectedStatus = ProjectStatus.aktif;
    CariHesap? selectedCari;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 24),
                  Text(AppLocalizations.of(context)!.newProjectCard, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 32),
                  _buildInputLabel(AppLocalizations.of(context)!.projectName),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: _inputDecoration(Icons.business_rounded),
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel(AppLocalizations.of(context)!.customerFirm),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<CariHesap?>(
                          value: selectedCari,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          decoration: _inputDecoration(Icons.person_rounded),
                          items: _cariHesaplar.map((c) => DropdownMenuItem(value: c, child: Text(c.unvan))).toList(),
                          onChanged: (val) => setModalState(() => selectedCari = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) => const CariEkleDialog(),
                          );
                          if (result == true) {
                            final cariler = await DatabaseHelper.instance.getAllCariHesaplar();
                            setState(() => _cariHesaplar = cariler);
                            setModalState(() {});
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel(AppLocalizations.of(context)!.estimatedBudget),
                  TextField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: _inputDecoration(Icons.payments_rounded, suffix: '₺'),
                  ),
                  const SizedBox(height: 32),
                  _buildInputLabel(AppLocalizations.of(context)!.status),
                  SegmentedButton<ProjectStatus>(
                    segments: [
                      ButtonSegment(value: ProjectStatus.aktif, label: Text(AppLocalizations.of(context)!.active), icon: const Icon(Icons.play_circle_outline)),
                      ButtonSegment(value: ProjectStatus.askida, label: Text(AppLocalizations.of(context)!.suspended), icon: const Icon(Icons.pause_circle_outline)),
                      ButtonSegment(value: ProjectStatus.bitti, label: Text(AppLocalizations.of(context)!.completed), icon: const Icon(Icons.check_circle_outline)),
                    ],
                    selected: {selectedStatus},
                    onSelectionChanged: (val) => setModalState(() => selectedStatus = val.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: const Color(0xFF011627),
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        try {
                          final newProject = Project(
                            ad: nameController.text,
                            toplamButce: double.tryParse(budgetController.text) ?? 0.0,
                            durum: selectedStatus,
                            baslangicTarihi: DateTime.now(),
                            cariHesapId: selectedCari?.id,
                            cariHesapUnvan: selectedCari?.unvan,
                          );
                          await DatabaseHelper.instance.insertProject(newProject);
                          if (mounted) {
                            Navigator.pop(context);
                            _loadProjects();
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
                      backgroundColor: const Color(0xFF2EC4B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.saveProject.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label.toUpperCase(), style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  InputDecoration _inputDecoration(IconData icon, {String? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF2EC4B6), size: 18),
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2EC4B6))),
    );
  }
}
class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = project.durum == ProjectStatus.aktif
        ? const Color(0xFF2EC4B6)
        : project.durum == ProjectStatus.bitti
            ? Colors.green
            : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        (project.durum == ProjectStatus.aktif
                                ? AppLocalizations.of(context)!.active
                                : project.durum == ProjectStatus.bitti
                                    ? AppLocalizations.of(context)!.completed
                                    : AppLocalizations.of(context)!.suspended)
                            .toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.0),
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project.ad,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF011627), letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  project.cariHesapUnvan ?? AppLocalizations.of(context)!.unknown,
                  style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.budgetLabel.toUpperCase(), style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: Localizations.localeOf(context).toString(),
                            symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : '\$',
                            decimalDigits: 0,
                          ).format(project.toplamButce),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF011627)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF011627).withOpacity(0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF011627), size: 18),
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
}
