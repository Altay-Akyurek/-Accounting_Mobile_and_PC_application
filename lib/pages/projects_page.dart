import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../services/database_helper.dart';
import 'project_detail_page.dart';
import '../models/cari_hesap.dart';
import '../widgets/cari_ekle_dialog.dart';
import '../widgets/banner_ad_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await DatabaseHelper.instance.getAllProjects();
    final cariler = await DatabaseHelper.instance.getAllCariHesaplar();
    setState(() {
      _projects = projects;
      _cariHesaplar = cariler;
      _isLoading = false;
    });
  }

  String _formatPara(double tutar) {
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.projects),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProjects,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatusFilter(),
                Expanded(
                  child: _projects.isEmpty ? _buildEmptyState() : _buildProjectGrid(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProjectDialog,
        icon: const Icon(Icons.add_business_rounded),
        label: Text(AppLocalizations.of(context)!.newProjectCard),
        backgroundColor: const Color(0xFF003399),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const BannerAdWidget(),
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
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          if (_filterStatus == null)
            ElevatedButton(
              onPressed: _showAddProjectDialog,
              child: Text(AppLocalizations.of(context)!.createFirstProject),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          FilterChip(
            label: Text(AppLocalizations.of(context)!.all),
            selected: _filterStatus == null,
            onSelected: (val) => setState(() => _filterStatus = null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(AppLocalizations.of(context)!.active),
            selected: _filterStatus == ProjectStatus.aktif,
            onSelected: (val) => setState(() => _filterStatus = ProjectStatus.aktif),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(AppLocalizations.of(context)!.suspended),
            selected: _filterStatus == ProjectStatus.askida,
            onSelected: (val) => setState(() => _filterStatus = ProjectStatus.askida),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(AppLocalizations.of(context)!.completed),
            selected: _filterStatus == ProjectStatus.tamamlandi,
            onSelected: (val) => setState(() => _filterStatus = ProjectStatus.tamamlandi),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid() { // Renamed internally for consistency if needed, but keeping name for now
    final filteredProjects = _filterStatus == null ? _projects : _projects.where((p) => p.durum == _filterStatus).toList();

    if (filteredProjects.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: filteredProjects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        return _ProjectCard(
          project: project,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProjectDetailPage(project: project)),
            );
            _loadProjects();
          },
          onDelete: () => _confirmDeleteProject(project),
        );
      },
    );
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteProject),
        content: Text(AppLocalizations.of(context)!.deleteProjectConfirm(project.ad)),
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

    if (confirmed == true && project.id != null) {
      await DatabaseHelper.instance.deleteProject(project.id!);
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.projectDeleted)),
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
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.newProjectCard, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.projectName, prefixIcon: const Icon(Icons.business_rounded)),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CariHesap?>(
                        value: selectedCari,
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.customerFirm, prefixIcon: const Icon(Icons.person_rounded)),
                        items: _cariHesaplar.map((c) => DropdownMenuItem(value: c, child: Text(c.unvan))).toList(),
                        onChanged: (val) => setModalState(() => selectedCari = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(color: const Color(0xFF003399).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: IconButton(
                        icon: const Icon(Icons.add_rounded, color: Color(0xFF003399)),
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.estimatedBudget, prefixIcon: const Icon(Icons.payments_rounded)),
                ),
                const SizedBox(height: 24),
                Text(AppLocalizations.of(context)!.status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                SegmentedButton<ProjectStatus>(
                  segments: [
                    ButtonSegment(value: ProjectStatus.aktif, label: Text(AppLocalizations.of(context)!.active), icon: const Icon(Icons.play_circle_outline)),
                    ButtonSegment(value: ProjectStatus.askida, label: Text(AppLocalizations.of(context)!.suspended), icon: const Icon(Icons.pause_circle_outline)),
                    ButtonSegment(value: ProjectStatus.tamamlandi, label: Text(AppLocalizations.of(context)!.completed), icon: const Icon(Icons.check_circle_outline)),
                  ],
                  selected: {selectedStatus},
                  onSelectionChanged: (val) => setModalState(() => selectedStatus = val.first),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                          if (context.mounted) {
                            Navigator.pop(context);
                            _loadProjects();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.projectCreated), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString())),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.enterProjectName)),
                        );
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.saveProject),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        ? Colors.blue.shade700
        : project.durum == ProjectStatus.tamamlandi
            ? Colors.green.shade700
            : Colors.amber.shade700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (project.durum == ProjectStatus.aktif
                              ? AppLocalizations.of(context)!.active
                              : project.durum == ProjectStatus.tamamlandi
                                  ? AppLocalizations.of(context)!.completed
                                  : AppLocalizations.of(context)!.suspended)
                          .toUpperCase(),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
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
                            Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                project.ad,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(project.baslangicTarihi),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.budgetLabel, style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      Text(
                        NumberFormat.currency(
                          locale: Localizations.localeOf(context).toString(),
                          symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : r'$',
                          decimalDigits: 0,
                        ).format(project.toplamButce),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF003399).withOpacity(0.05), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF003399), size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
