import 'package:flutter/material.dart';
import '../models/cari_hesap.dart';
import '../services/database_helper.dart';

class CariHesapEklePage extends StatefulWidget {
  final CariHesap? cariHesap;

  const CariHesapEklePage({super.key, this.cariHesap});

  @override
  State<CariHesapEklePage> createState() => _CariHesapEklePageState();
}

class _CariHesapEklePageState extends State<CariHesapEklePage> {
  final _formKey = GlobalKey<FormState>();
  final _unvanController = TextEditingController();
  final _vergiNoController = TextEditingController();
  final _vergiDairesiController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresController = TextEditingController();
  final _bakiyeController = TextEditingController();

  bool _isLoading = false;
  bool _isKasa = false;

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
      _bakiyeController.text = widget.cariHesap!.bakiye.toString();
      _isKasa = widget.cariHesap!.isKasa;
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
    _bakiyeController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final bakiye = double.tryParse(_bakiyeController.text) ?? 0.0;
      final cariHesap = CariHesap(
        id: widget.cariHesap?.id,
        unvan: _unvanController.text.trim(),
        vergiNo: _vergiNoController.text.trim().isEmpty ? null : _vergiNoController.text.trim(),
        vergiDairesi: _vergiDairesiController.text.trim().isEmpty ? null : _vergiDairesiController.text.trim(),
        telefon: _telefonController.text.trim().isEmpty ? null : _telefonController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        adres: _adresController.text.trim().isEmpty ? null : _adresController.text.trim(),
        bakiye: bakiye,
        isKasa: _isKasa,
        olusturmaTarihi: widget.cariHesap?.olusturmaTarihi,
      );

      if (widget.cariHesap == null) {
        await DatabaseHelper.instance.insertCariHesap(cariHesap);
      } else {
        await DatabaseHelper.instance.updateCariHesap(cariHesap);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.cariHesap == null ? 'YENİ CARİ KAYIT' : 'CARİ KAYIT DÜZENLE'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('Genel Bilgiler'),
                        _buildCard([
                          _buildTextField(_unvanController, 'Cari Ünvan *', Icons.business_rounded, validator: (v) => v?.isEmpty ?? true ? 'Ünvan zorunludur' : null),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(_vergiNoController, 'Vergi No', Icons.badge_rounded, keyboardType: TextInputType.number)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField(_vergiDairesiController, 'Vergi Dairesi', Icons.account_balance_rounded)),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 32),
                        _sectionTitle('İletişim Bilgileri'),
                        _buildCard([
                          Row(
                            children: [
                              Expanded(child: _buildTextField(_telefonController, 'Telefon', Icons.phone_rounded, keyboardType: TextInputType.phone)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField(_emailController, 'E-posta', Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(_adresController, 'Adres', Icons.location_on_rounded, maxLines: 3),
                        ]),
                        const SizedBox(height: 32),
                        _sectionTitle('Finansal Ayarlar'),
                        _buildCard([
                          _buildTextField(_bakiyeController, 'Başlangıç Bakiyesi', Icons.account_balance_wallet_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Kasa Hesabı', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Bu hesabı kasa olarak işaretle (Girişler gelire eklenir)'),
                            value: _isKasa,
                            onChanged: (val) => setState(() => _isKasa = val),
                            activeColor: const Color(0xFF003399),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ]),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: _kaydet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003399),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('KAYDI TAMAMLA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title.toUpperCase(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF003399), size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
