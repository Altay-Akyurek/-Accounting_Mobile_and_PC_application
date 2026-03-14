import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/cari_hesap.dart';
import '../services/database_helper.dart';
import '../utils/error_handler.dart';
import 'package:intl/intl.dart';

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSummaryHeader(),
                          const SizedBox(height: 32),
                          _sectionTitle(AppLocalizations.of(context)!.generalInfo),
                          _buildCard([
                            _buildTextField(_unvanController, AppLocalizations.of(context)!.accountTitle, Icons.business_rounded, 
                                validator: (v) => v?.isEmpty ?? true ? AppLocalizations.of(context)!.titleRequired : null),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_vergiNoController, 'Vergi No', Icons.badge_rounded, keyboardType: TextInputType.number)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(_vergiDairesiController, 'Vergi Dairesi', Icons.account_balance_rounded)),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _sectionTitle(AppLocalizations.of(context)!.contactInfo),
                          _buildCard([
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_telefonController, 'Telefon', Icons.phone_rounded, keyboardType: TextInputType.phone)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField(_emailController, 'E-posta', Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(_adresController, AppLocalizations.of(context)!.address, Icons.location_on_rounded, maxLines: 2),
                          ]),
                          const SizedBox(height: 32),
                          _sectionTitle(AppLocalizations.of(context)!.financialSettings),
                          _buildCard([
                             _buildTextField(_bakiyeController, AppLocalizations.of(context)!.startingBalance, Icons.account_balance_wallet_rounded, 
                                 keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                             const SizedBox(height: 12),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                               decoration: BoxDecoration(
                                 color: Colors.grey.shade50,
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               child: SwitchListTile(
                                 title: Text(AppLocalizations.of(context)!.cashAccount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF011627))),
                                 subtitle: Text(AppLocalizations.of(context)!.markAsCashInfo, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                 value: _isKasa,
                                 onChanged: (val) => setState(() => _isKasa = val),
                                 activeColor: const Color(0xFF2EC4B6),
                                 contentPadding: EdgeInsets.zero,
                               ),
                             ),
                          ]),
                          const SizedBox(height: 48),
                          _buildSaveButton(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF011627),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      title: Text(
        widget.cariHesap == null 
          ? AppLocalizations.of(context)!.addNewCari.toUpperCase() 
          : AppLocalizations.of(context)!.editCariRecord.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSummaryHeader() {
    final double bakiye = double.tryParse(_bakiyeController.text) ?? (widget.cariHesap?.bakiye ?? 0.0);
    final bool isReceivable = bakiye < 0;
    final bool isPayable = bakiye > 0;
    final Color statusColor = isPayable ? const Color(0xFFE71D36) : isReceivable ? const Color(0xFF2EC4B6) : Colors.grey;
    final String statusLabel = isPayable 
        ? (AppLocalizations.of(context)!.localeName == 'tr' ? 'BORÇLU DURUMDA' : 'PAYABLE STATUS')
        : isReceivable 
          ? (AppLocalizations.of(context)!.localeName == 'tr' ? 'ALACAKLI DURUMDA' : 'RECEIVABLE STATUS')
          : (AppLocalizations.of(context)!.localeName == 'tr' ? 'DENGE DURUMUNDA' : 'BALANCED');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF011627),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF011627).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 3),
            ),
            child: Center(
              child: Text(
                _unvanController.text.isNotEmpty ? _unvanController.text[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _unvanController.text.isEmpty ? (AppLocalizations.of(context)!.localeName == 'tr' ? 'Yeni Hesap' : 'New Account') : _unvanController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.currentBalance_caps,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                      locale: Localizations.localeOf(context).toString(),
                      symbol: Localizations.localeOf(context).toString() == 'tr' ? '₺' : '\$',
                    ).format(bakiye.abs()),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(), 
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {TextInputType? keyboardType, String? Function(String?)? validator, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF011627)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF2EC4B6), size: 18),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2EC4B6), width: 1.5)),
            errorStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2EC4B6).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _kaydet,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2EC4B6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 22),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 20),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.completeRecord.toUpperCase(), 
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)
            ),
          ],
        ),
      ),
    );
  }
}
