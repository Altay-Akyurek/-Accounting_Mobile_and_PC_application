import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/worker.dart';

class WorkerDocumentsPage extends StatefulWidget {
  final Worker worker;
  const WorkerDocumentsPage({super.key, required this.worker});

  @override
  State<WorkerDocumentsPage> createState() => _WorkerDocumentsPageState();
}

class _WorkerDocumentsPageState extends State<WorkerDocumentsPage> {
  late DateTime _dismissalDate;
  late double _severancePay;
  late double _noticePay;
  late double _unusedLeavePay;
  String _reason = '';

  @override
  void initState() {
    super.initState();
    _dismissalDate = widget.worker.istenCikisTarihi ?? DateTime.now();
    
    // Initial calculations
    final daysWorked = _dismissalDate.difference(widget.worker.baslangicTarihi).inDays;
    double monthlySalary = 0;
    if (widget.worker.maasTuru == WorkerSalaryType.aylik) monthlySalary = widget.worker.maasTutari;
    else if (widget.worker.maasTuru == WorkerSalaryType.gunluk) monthlySalary = widget.worker.maasTutari * 30;
    else monthlySalary = widget.worker.maasTutari * 225 / 12;

    _severancePay = daysWorked >= 365 ? (daysWorked / 365) * monthlySalary : 0;
    
    int weeks = 0;
    if (daysWorked < 180) weeks = 2;
    else if (daysWorked < 540) weeks = 4;
    else if (daysWorked < 1080) weeks = 6;
    else weeks = 8;
    _noticePay = (weeks * 7) * (monthlySalary / 30);
    
    // Yıllık izin ücreti: Her yıl için yaklaşık 14 gün hak ediş
    _unusedLeavePay = daysWorked >= 365 ? (daysWorked / 365) * 14 * (monthlySalary / 30) : 0;
  }

  Future<void> _generatePdf(String title, String content) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pwContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 20))),
                pw.SizedBox(height: 40),
                pw.Text('${AppLocalizations.of(context)!.tableDate}: ${DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(DateTime.now())}', style: pw.TextStyle(font: font)),
                pw.SizedBox(height: 20),
                pw.Text(AppLocalizations.of(context)!.personnelInfo, style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.Text('${AppLocalizations.of(context)!.nameSurname}: ${widget.worker.adSoyad}', style: pw.TextStyle(font: font)),
                pw.Text('${AppLocalizations.of(context)!.idNo}: ${widget.worker.tcNo ?? '-'}', style: pw.TextStyle(font: font)),
                pw.Text('${AppLocalizations.of(context)!.startingDate}: ${DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(widget.worker.baslangicTarihi)}', style: pw.TextStyle(font: font)),
                pw.Text('${AppLocalizations.of(context)!.dismissed}: ${DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(_dismissalDate)}', style: pw.TextStyle(font: font)),
                pw.SizedBox(height: 30),
                pw.Text(content, style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 4)),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [pw.Text(AppLocalizations.of(context)!.employerSignature, style: pw.TextStyle(font: boldFont)), pw.SizedBox(height: 40)]),
                    pw.Column(children: [pw.Text(AppLocalizations.of(context)!.workerSignature, style: pw.TextStyle(font: boldFont)), pw.SizedBox(height: 40)]),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _editValue(String title, double initialValue, Function(double) onSaved) {
    final controller = TextEditingController(text: initialValue.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '₺'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              setState(() => onSaved(double.tryParse(controller.text) ?? 0));
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final currencyFormat = NumberFormat.currency(
      locale: locale,
      symbol: locale == 'tr' ? '₺' : '\$',
    );
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.workerDocuments(widget.worker.adSoyad))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(AppLocalizations.of(context)!.severanceAndRights),
            _buildEditCard(AppLocalizations.of(context)!.severancePay, currencyFormat.format(_severancePay), () => _editValue(AppLocalizations.of(context)!.severancePay, _severancePay, (v) => _severancePay = v)),
            _buildEditCard(AppLocalizations.of(context)!.noticePay, currencyFormat.format(_noticePay), () => _editValue(AppLocalizations.of(context)!.noticePay, _noticePay, (v) => _noticePay = v)),
            _buildEditCard(AppLocalizations.of(context)!.leavePay, currencyFormat.format(_unusedLeavePay), () => _editValue(AppLocalizations.of(context)!.leavePay, _unusedLeavePay, (v) => _unusedLeavePay = v)),
            _buildReasonField(),
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.createDocument),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                _buildDocButton(AppLocalizations.of(context)!.serviceCertificate, Icons.badge, _generateServiceCertificate),
                _buildDocButton(AppLocalizations.of(context)!.releaseForm, Icons.gavel, _generateReleaseForm),
                _buildDocButton(AppLocalizations.of(context)!.compensationBreakdown, Icons.calculate, _generateCompensationDoc),
                _buildDocButton(AppLocalizations.of(context)!.payrollPusula, Icons.receipt_long, _generatePayrollDoc),
                _buildDocButton(AppLocalizations.of(context)!.sgkStatement, Icons.description_outlined, _generateSgkDoc),
                _buildDocButton(AppLocalizations.of(context)!.paymentReceipt, Icons.payments_outlined, _generateReceiptDoc),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
    );
  }

  Widget _buildEditCard(String title, String value, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.black.withOpacity(0.05))),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF011627))),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 16, color: Colors.blue),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReasonField() {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.black.withOpacity(0.05))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.separationReason, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => _reason = v,
              decoration: InputDecoration(hintText: AppLocalizations.of(context)!.reasonHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.05))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF011627), size: 28),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentEditor(String title, String initialContent) {
    final controller = TextEditingController(text: initialContent);
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.editDocument(title)),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                _generatePdf(title, controller.text);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: AppLocalizations.of(context)!.editDocumentContentHint,
            ),
          ),
        ),
      ),
    );
  }

  void _generateServiceCertificate() {
    final name = widget.worker.adSoyad;
    final startDate = DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(widget.worker.baslangicTarihi);
    final endDate = DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(_dismissalDate);
    final position = widget.worker.pozisyon ?? AppLocalizations.of(context)!.fieldWorker;
    final reason = _reason.isEmpty ? AppLocalizations.of(context)!.notEntered : _reason;

    final content = AppLocalizations.of(context)!.serviceCertificate_template(name, startDate, endDate, position, reason);
    _showDocumentEditor(AppLocalizations.of(context)!.serviceCertificate, content);
  }

  void _generateReleaseForm() {
    final date = DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(_dismissalDate);
    final content = AppLocalizations.of(context)!.releaseForm_template(date);
    _showDocumentEditor(AppLocalizations.of(context)!.releaseForm, content);
  }

  void _generateCompensationDoc() {
    final locale = Localizations.localeOf(context).toString();
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: locale == 'tr' ? '₺' : '\$',
    );
    final content = AppLocalizations.of(context)!.compensationBreakdown_template(
      currency.format(_severancePay),
      currency.format(_noticePay),
      currency.format(_unusedLeavePay),
      currency.format(_severancePay + _noticePay + _unusedLeavePay),
    );
    _showDocumentEditor(AppLocalizations.of(context)!.compensationBreakdown, content);
  }

  void _generatePayrollDoc() {
    final content = AppLocalizations.of(context)!.payrollPusula_template;
    _showDocumentEditor(AppLocalizations.of(context)!.payrollPusula, content);
  }

  void _generateSgkDoc() {
    final name = widget.worker.adSoyad;
    final tcNo = widget.worker.tcNo ?? "---";
    final date = DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(_dismissalDate);
    final reason = _reason.isEmpty ? AppLocalizations.of(context)!.notEntered : _reason;

    final content = AppLocalizations.of(context)!.sgkStatement_template(name, tcNo, date, reason);
    _showDocumentEditor(AppLocalizations.of(context)!.sgkStatement, content);
  }

  void _generateReceiptDoc() {
    final locale = Localizations.localeOf(context).toString();
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: locale == 'tr' ? '₺' : '\$',
    );
    final name = widget.worker.adSoyad;
    final amount = currency.format(_severancePay + _noticePay + _unusedLeavePay);
    final date = DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString()).format(DateTime.now());

    final content = AppLocalizations.of(context)!.paymentReceipt_template(name, amount, date);
    _showDocumentEditor(AppLocalizations.of(context)!.paymentReceipt, content);
  }
}
