import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String _reason = 'Belirtilmedi';

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
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text(title.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 20))),
                pw.SizedBox(height: 40),
                pw.Text('Tarih: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}', style: pw.TextStyle(font: font)),
                pw.SizedBox(height: 20),
                pw.Text('PERSONEL BİLGİLERİ:', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.Text('Ad Soyad: ${widget.worker.adSoyad}', style: pw.TextStyle(font: font)),
                pw.Text('TC No: ${widget.worker.tcNo ?? '-'}', style: pw.TextStyle(font: font)),
                pw.Text('İşe Giriş: ${DateFormat('dd.MM.yyyy').format(widget.worker.baslangicTarihi)}', style: pw.TextStyle(font: font)),
                pw.Text('İşten Çıkış: ${DateFormat('dd.MM.yyyy').format(_dismissalDate)}', style: pw.TextStyle(font: font)),
                pw.SizedBox(height: 30),
                pw.Text(content, style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 4)),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [pw.Text('İşveren İmza', style: pw.TextStyle(font: boldFont)), pw.SizedBox(height: 40)]),
                    pw.Column(children: [pw.Text('İşçi İmza', style: pw.TextStyle(font: boldFont)), pw.SizedBox(height: 40)]),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İPTAL')),
          ElevatedButton(
            onPressed: () {
              setState(() => onSaved(double.tryParse(controller.text) ?? 0));
              Navigator.pop(context);
            },
            child: const Text('KAYDET'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₺');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(title: Text('${widget.worker.adSoyad} - Belgeler')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Tazminat ve Haklar (Düzenlenebilir)'),
            _buildEditCard('Kıdem Tazminatı', currencyFormat.format(_severancePay), () => _editValue('Kıdem Tazminatı', _severancePay, (v) => _severancePay = v)),
            _buildEditCard('İhbar Tazminatı', currencyFormat.format(_noticePay), () => _editValue('İhbar Tazminatı', _noticePay, (v) => _noticePay = v)),
            _buildEditCard('İzin Ücretleri', currencyFormat.format(_unusedLeavePay), () => _editValue('İzin Ücretleri', _unusedLeavePay, (v) => _unusedLeavePay = v)),
            _buildReasonField(),
            const SizedBox(height: 24),
            _buildSectionHeader('Belge Oluştur'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                _buildDocButton('Çalışma Belgesi', Icons.badge, _generateServiceCertificate),
                _buildDocButton('İbraname', Icons.gavel, _generateReleaseForm),
                _buildDocButton('Tazminat Dökümü', Icons.calculate, _generateCompensationDoc),
                _buildDocButton('Ücret Pusulası', Icons.receipt_long, _generatePayrollDoc),
                _buildDocButton('SGK Bildirgesi', Icons.description_outlined, _generateSgkDoc),
                _buildDocButton('Ödeme Dekontu', Icons.payments_outlined, _generateReceiptDoc),
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
            const Text('Ayrılma Nedeni', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => _reason = v,
              decoration: const InputDecoration(hintText: 'Örn: Emeklilik, İstifa, 4857/25-II...'),
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
          title: Text('$title - Düzenle'),
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
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Belge içeriğini buraya yazın...',
            ),
          ),
        ),
      ),
    );
  }

  void _generateServiceCertificate() {
    final content = 'Sayın ${widget.worker.adSoyad}, işyerimizde ${DateFormat('dd.MM.yyyy').format(widget.worker.baslangicTarihi)} tarihinden ${DateFormat('dd.MM.yyyy').format(_dismissalDate)} tarihine kadar "${widget.worker.pozisyon ?? 'Saha Personeli'}" görevinde çalışmıştır. Ayrılma nedeni: $_reason. Bu belge, ilgilinin isteği üzerine düzenlenmiştir.';
    _showDocumentEditor('Çalışma Belgesi', content);
  }

  void _generateReleaseForm() {
    final content = 'İşyerinden ${DateFormat('dd.MM.yyyy').format(_dismissalDate)} tarihinde ayrılırken; almış olduğum maaş, kıdem tazminatı, ihbar tazminatı ve diğer tüm sosyal haklarımı eksiksiz olarak teslim aldığımı, işverenden herhangi bir hak ve alacağımın kalmadığını beyan ederek işvereni tamamen ibra ederim.';
    _showDocumentEditor('İbraname', content);
  }

  void _generateCompensationDoc() {
    final currency = NumberFormat.currency(symbol: '₺');
    final content = 'PERSONEL HAK VE ALACAK DÖKÜMÜ:\n\n'
        '1. Kıdem Tazminatı: ${currency.format(_severancePay)}\n'
        '2. İhbar Tazminatı: ${currency.format(_noticePay)}\n'
        '3. İzin Ücretleri: ${currency.format(_unusedLeavePay)}\n\n'
        'TOPLAM ÖDENEN: ${currency.format(_severancePay + _noticePay + _unusedLeavePay)}\n\n'
        'İşbu döküm personelin iş akdi sonlandığında hak ettiği yasal alacakları göstermektedir.';
    _showDocumentEditor('Tazminat Hesap Dökümü', content);
  }

  void _generatePayrollDoc() {
    final content = 'ÜCRET HESAP PUSULASI:\n\n'
        'Personelin görev süresi boyunca tahakkuk eden son ay ücreti ve ek ödemeleri aşağıda belirtilen banka hesaplarına veya elden teslim edilmiştir.\n\n'
        'Ödeme Kalemi: Kıdem/İhbar/Maaş\n'
        'Açıklama: İş akdi feshi neticesinde yapılan toplu ödeme.';
    _showDocumentEditor('Ücret Hesap Pusulası', content);
  }

  void _generateSgkDoc() {
    final content = 'SGK İŞTEN AYRILIŞ BİLDİRGESİ ÖZETİ:\n\n'
        'Personel: ${widget.worker.adSoyad}\n'
        'TC No: ${widget.worker.tcNo ?? "---"}\n'
        'Ayrılış Tarihi: ${DateFormat('dd.MM.yyyy').format(_dismissalDate)}\n'
        'Ayrılış Nedeni: $_reason\n\n'
        'Bu döküm SGK sistemine girilen işten ayrılış bildiriminin bir kopyasıdır.';
    _showDocumentEditor('SGK Bildirgesi', content);
  }

  void _generateReceiptDoc() {
    final currency = NumberFormat.currency(symbol: '₺');
    final content = 'BANKA ÖDEME DEKONTU / TEDİYE MAKBUZU:\n\n'
        'Ödeme Yapılan: ${widget.worker.adSoyad}\n'
        'Tutar: ${currency.format(_severancePay + _noticePay + _unusedLeavePay)}\n'
        'Açıklama: Maaş, kıdem, ihbar ve tüm yan hakların toplu tasfiye ödemesidir.\n\n'
        'Ödeme Tarihi: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}';
    _showDocumentEditor('Ödeme Dekontu', content);
  }
}
