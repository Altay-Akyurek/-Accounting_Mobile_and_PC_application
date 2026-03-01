import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../models/gelir_gider.dart';
import '../models/cari_hesap.dart';
import '../models/project.dart';
import '../services/database_helper.dart';

class GelirGiderEklePage extends StatefulWidget {
  final GelirGider? gelirGider;
  final GelirGiderTipi? tipi;

  const GelirGiderEklePage({super.key, this.gelirGider, this.tipi});

  @override
  State<GelirGiderEklePage> createState() => _GelirGiderEklePageState();
}

class _GelirGiderEklePageState extends State<GelirGiderEklePage> {
  final _formKey = GlobalKey<FormState>();
  final _baslikController = TextEditingController();
  final _tutarController = TextEditingController();
  final _tarihController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _faturaNoController = TextEditingController();

  DateTime _tarih = DateTime.now();
  CariHesap? _seciliCariHesap;
  Project? _seciliProje;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.gelirGider != null) {
      _baslikController.text = widget.gelirGider!.baslik;
      _tutarController.text = widget.gelirGider!.tutar.toString();
      _tarih = widget.gelirGider!.tarih;
      _tarihController.text = DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(_tarih);
      _kategoriController.text = widget.gelirGider!.kategori ?? '';
      _aciklamaController.text = widget.gelirGider!.aciklama ?? '';
      _faturaNoController.text = widget.gelirGider!.faturaNo ?? '';
      if (widget.gelirGider!.cariHesapId != null) {
        _yukleCariHesap(widget.gelirGider!.cariHesapId!);
      }
      if (widget.gelirGider!.projectId != null) {
        _yukleProje(widget.gelirGider!.projectId!);
      }
    } else {
      _tarihController.text = DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(_tarih);
    }
  }

  Future<void> _yukleCariHesap(int id) async {
    final cari = await DatabaseHelper.instance.getCariHesap(id);
    if (cari != null) {
      setState(() {
        _seciliCariHesap = cari;
      });
    }
  }

  Future<void> _yukleProje(int id) async {
    final projects = await DatabaseHelper.instance.getAllProjects();
    final p = projects.where((proj) => proj.id == id).firstOrNull;
    if (p != null) {
      setState(() {
        _seciliProje = p;
      });
    }
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null) {
      setState(() {
        _tarih = secilen;
        _tarihController.text = DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(_tarih);
      });
    }
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _tutarController.dispose();
    _tarihController.dispose();
    _kategoriController.dispose();
    _aciklamaController.dispose();
    _faturaNoController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final gelirGider = GelirGider(
        id: widget.gelirGider?.id,
        tipi: widget.gelirGider?.tipi ?? widget.tipi ?? GelirGiderTipi.gelir,
        baslik: _baslikController.text.trim(),
        tutar: double.tryParse(_tutarController.text.replaceAll(',', '.')) ?? 0.0,
        tarih: _tarih,
        kategori: _kategoriController.text.trim().isEmpty ? null : _kategoriController.text.trim(),
        cariHesapId: _seciliCariHesap?.id,
        cariHesapUnvan: _seciliCariHesap?.unvan,
        aciklama: _aciklamaController.text.trim().isEmpty ? null : _aciklamaController.text.trim(),
        faturaNo: _faturaNoController.text.trim().isEmpty ? null : _faturaNoController.text.trim(),
        projectId: _seciliProje?.id,
        olusturmaTarihi: widget.gelirGider?.olusturmaTarihi,
      );

      if (widget.gelirGider == null) {
        await DatabaseHelper.instance.insertGelirGider(gelirGider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.recordAdded)),
          );
        }
      } else {
        await DatabaseHelper.instance.updateGelirGider(gelirGider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.recordUpdated)),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorPrefix}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipi = widget.gelirGider?.tipi ?? widget.tipi ?? GelirGiderTipi.gelir;
    final tipiText = tipi == GelirGiderTipi.gelir ? AppLocalizations.of(context)!.income : AppLocalizations.of(context)!.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gelirGider == null ? AppLocalizations.of(context)!.newItemType(tipiText) : AppLocalizations.of(context)!.editItemType(tipiText)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _baslikController,
                      decoration: InputDecoration(
                        labelText: '${AppLocalizations.of(context)!.titleLabel} *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.titleRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tutarController,
                      decoration: InputDecoration(
                        labelText: '${AppLocalizations.of(context)!.amountLabel} *',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.amountRequired;
                        }
                        final tutar = double.tryParse(value.replaceAll(',', '.'));
                        if (tutar == null || tutar <= 0) {
                          return AppLocalizations.of(context)!.pleaseEnterValidAmount;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tarihController,
                      decoration: InputDecoration(
                        labelText: '${AppLocalizations.of(context)!.tableDate} *',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: _tarihSec,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseSelectDate;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kategoriController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.categoryLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_seciliCariHesap?.unvan ?? AppLocalizations.of(context)!.selectCariAccountOptional),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final cariHesaplar = await DatabaseHelper.instance.getAllCariHesaplar();
                        if (mounted && cariHesaplar.isNotEmpty) {
                          final secilen = await showDialog<CariHesap>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.selectCariAccount),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: cariHesaplar.length,
                                  itemBuilder: (context, index) {
                                    final cari = cariHesaplar[index];
                                    return ListTile(
                                      title: Text(cari.unvan),
                                      onTap: () => Navigator.pop(context, cari),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                          if (secilen != null) {
                            setState(() {
                              _seciliCariHesap = secilen;
                            });
                          }
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_seciliProje?.ad ?? AppLocalizations.of(context)!.selectProjectOptional),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final projects = await DatabaseHelper.instance.getAllProjects();
                        if (mounted && projects.isNotEmpty) {
                          final secilen = await showDialog<Project>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.selectProject),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: projects.length,
                                  itemBuilder: (context, index) {
                                    final p = projects[index];
                                    return ListTile(
                                      title: Text(p.ad),
                                      onTap: () => Navigator.pop(context, p),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                          if (secilen != null) {
                            setState(() {
                              _seciliProje = secilen;
                            });
                          }
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _faturaNoController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.invoiceNo,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aciklamaController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _kaydet,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(AppLocalizations.of(context)!.save),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


