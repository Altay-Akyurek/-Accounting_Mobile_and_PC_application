import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/stok.dart';
import '../services/database_helper.dart';

class StokEklePage extends StatefulWidget {
  final Stok? stok;

  const StokEklePage({super.key, this.stok});

  @override
  State<StokEklePage> createState() => _StokEklePageState();
}

class _StokEklePageState extends State<StokEklePage> {
  final _formKey = GlobalKey<FormState>();
  final _kodController = TextEditingController();
  final _adController = TextEditingController();
  final _birimController = TextEditingController();
  final _stokMiktariController = TextEditingController();
  final _kritikStokSeviyesiController = TextEditingController();
  final _alisFiyatiController = TextEditingController();
  final _satisFiyatiController = TextEditingController();
  final _kdvOraniController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _aciklamaController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.stok != null) {
      _kodController.text = widget.stok!.kod;
      _adController.text = widget.stok!.ad;
      _birimController.text = widget.stok!.birim ?? 'Adet';
      _stokMiktariController.text = widget.stok!.stokMiktari?.toString() ?? '';
      _kritikStokSeviyesiController.text = widget.stok!.kritikStokSeviyesi?.toString() ?? '';
      _alisFiyatiController.text = widget.stok!.alisFiyati?.toString() ?? '';
      _satisFiyatiController.text = widget.stok!.satisFiyati?.toString() ?? '';
      _kdvOraniController.text = widget.stok!.kdvOrani?.toString() ?? '20';
      _kategoriController.text = widget.stok!.kategori ?? '';
      _aciklamaController.text = widget.stok!.aciklama ?? '';
    }
  }

  @override
  void dispose() {
    _kodController.dispose();
    _adController.dispose();
    _birimController.dispose();
    _stokMiktariController.dispose();
    _kritikStokSeviyesiController.dispose();
    _alisFiyatiController.dispose();
    _satisFiyatiController.dispose();
    _kdvOraniController.dispose();
    _kategoriController.dispose();
    _aciklamaController.dispose();
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
      final stok = Stok(
        id: widget.stok?.id,
        kod: _kodController.text.trim(),
        ad: _adController.text.trim(),
        birim: _birimController.text.trim().isEmpty ? 'Adet' : _birimController.text.trim(),
        stokMiktari: double.tryParse(_stokMiktariController.text.replaceAll(',', '.')) ?? 0.0,
        kritikStokSeviyesi: _kritikStokSeviyesiController.text.trim().isEmpty
            ? null
            : double.tryParse(_kritikStokSeviyesiController.text.replaceAll(',', '.')),
        alisFiyati: _alisFiyatiController.text.trim().isEmpty
            ? null
            : double.tryParse(_alisFiyatiController.text.replaceAll(',', '.')),
        satisFiyati: _satisFiyatiController.text.trim().isEmpty
            ? null
            : double.tryParse(_satisFiyatiController.text.replaceAll(',', '.')),
        kdvOrani: double.tryParse(_kdvOraniController.text.replaceAll(',', '.')) ?? 20.0,
        kategori: _kategoriController.text.trim().isEmpty ? null : _kategoriController.text.trim(),
        aciklama: _aciklamaController.text.trim().isEmpty ? null : _aciklamaController.text.trim(),
        olusturmaTarihi: widget.stok?.olusturmaTarihi,
      );

      if (widget.stok == null) {
        await DatabaseHelper.instance.insertStok(stok);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.recordAdded)),
          );
        }
      } else {
        await DatabaseHelper.instance.updateStok(stok);
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString()))),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stok == null ? AppLocalizations.of(context)!.newStock : AppLocalizations.of(context)!.editStock),
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
                      controller: _kodController,
                      decoration: InputDecoration(
                        labelText: '${AppLocalizations.of(context)!.stockCode} *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.stockCodeRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adController,
                      decoration: InputDecoration(
                        labelText: '${AppLocalizations.of(context)!.stockName} *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.stockNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _birimController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.unit,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _kategoriController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.categoryLabel,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stokMiktariController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.stockAmount,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _kritikStokSeviyesiController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.criticalStockLevel,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _alisFiyatiController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.purchasePriceLabel,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _satisFiyatiController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.salePriceLabel,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kdvOraniController,
                      decoration: InputDecoration(
                        labelText: '${AppLocalizations.of(context)!.vatRate} (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aciklamaController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        border: OutlineInputBorder(),
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


