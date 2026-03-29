import 'package:flutter/material.dart';
import '../models/cari_hesap.dart';
import '../services/database_helper.dart';
import '../l10n/app_localizations.dart';

class CariEkleDialog extends StatefulWidget {
  final CariHesap? cariHesap;

  const CariEkleDialog({super.key, this.cariHesap});

  @override
  State<CariEkleDialog> createState() => _CariEkleDialogState();
}

class _CariEkleDialogState extends State<CariEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _unvanController = TextEditingController();
  final _vergiNoController = TextEditingController();
  final _vergiDairesiController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cariHesap != null) {
      _unvanController.text = widget.cariHesap!.unvan;
      _vergiNoController.text = widget.cariHesap!.vergiNo ?? '';
      _vergiDairesiController.text = widget.cariHesap!.vergiDairesi ?? '';
      _telefonController.text = widget.cariHesap!.telefon ?? '';
      _emailController.text = widget.cariHesap!.email ?? '';
      _adresController.text = widget.cariHesap!.adres ?? '';
    }
  }

  @override
  void dispose() {
    _unvanController.dispose();
    _vergiNoController.dispose();
    _vergiDairesiController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _adresController.dispose();
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
      final cariHesap = CariHesap(
        id: widget.cariHesap?.id,
        unvan: _unvanController.text.trim(),
        vergiNo: _vergiNoController.text.trim().isEmpty
            ? null
            : _vergiNoController.text.trim(),
        vergiDairesi: _vergiDairesiController.text.trim().isEmpty
            ? null
            : _vergiDairesiController.text.trim(),
        telefon: _telefonController.text.trim().isEmpty
            ? null
            : _telefonController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        adres: _adresController.text.trim().isEmpty
            ? null
            : _adresController.text.trim(),
        bakiye: widget.cariHesap?.bakiye ?? 0.0,
        olusturmaTarihi: widget.cariHesap?.olusturmaTarihi,
      );

      if (widget.cariHesap == null) {
        await DatabaseHelper.instance.insertCariHesap(cariHesap);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.cariAccountAdded)),
          );
        }
      } else {
        await DatabaseHelper.instance.updateCariHesap(cariHesap);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.cariAccountUpdated)),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
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
    return AlertDialog(
      title: Text(widget.cariHesap == null ? AppLocalizations.of(context)!.newCariAccountDialog : AppLocalizations.of(context)!.editCariAccountDialog),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _unvanController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.titleLabelStar,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!.titleIsRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vergiNoController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.taxNo,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vergiDairesiController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.taxOffice,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefonController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.phone,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.email,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _adresController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.address,
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _kaydet,
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}


