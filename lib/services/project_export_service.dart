import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/hakedis.dart';
import '../models/project.dart';

class ProjectExportService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL', decimalDigits: 2);

  static String _tr(String? text) {
    if (text == null) return '';
    var result = text;
    var turkishChars = {'İ': 'I', 'ı': 'i', 'Ş': 'S', 'ş': 's', 'Ğ': 'G', 'ğ': 'g', 'Ü': 'U', 'ü': 'u', 'Ö': 'O', 'ö': 'o', 'Ç': 'C', 'ç': 'c'};
    turkishChars.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }

  static Future<void> exportHakedisPDF(Hakedis h, Project p) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(_tr('HAKEDİŞ BELGESİ'), _tr(p.ad)),
              pw.SizedBox(height: 30),
              _buildInfoSection(h, p),
              pw.SizedBox(height: 40),
              _buildDetailTable(h),
              pw.Spacer(),
              _buildFooter(h.tarih),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${_tr(p.ad)}_Hakedis_${_tr(h.baslik)}.pdf',
    );
  }

  static Future<void> exportProjectHakedislerPDF(Project p, List<Hakedis> hakedisler) async {
    final pdf = pw.Document();

    double toplamBrut = 0;
    double toplamNet = 0;
    for (var h in hakedisler) {
      toplamBrut += h.tutar;
      toplamNet += h.netTutar;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(_tr('PROJE HAKEDİŞ RAPORU'), _tr(p.ad)),
          pw.SizedBox(height: 20),
          _buildSummaryCard(toplamBrut, toplamNet, hakedisler.length),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: [_tr('BAŞLIK'), _tr('TARİH'), _tr('BRÜT TUTAR'), _tr('KESİNTİLER'), _tr('NET TUTAR'), _tr('DURUM')],
            data: hakedisler.map((h) {
              return [
                _tr(h.baslik),
                DateFormat('dd.MM.yyyy').format(h.tarih),
                _currencyFormat.format(h.tutar),
                _currencyFormat.format(h.stopajTutari + h.teminatTutari),
                _currencyFormat.format(h.netTutar),
                _tr(h.durum == HakedisDurum.tahsilEdildi ? 'TAHSİL EDİLDİ' : 'BEKLİYOR'),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${_tr(p.ad)}_Tum_Hakedisler.pdf',
    );
  }

  static pw.Widget _buildHeader(String title, String projectName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text(projectName, style: const pw.TextStyle(color: PdfColors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoSection(Hakedis h, Project p) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow(_tr('Proje:'), _tr(p.ad)),
              _infoRow(_tr('Hakediş:'), _tr(h.baslik)),
              _infoRow(_tr('Tarih:'), DateFormat('dd.MM.yyyy').format(h.tarih)),
              _infoRow(_tr('Durum:'), _tr(h.durum == HakedisDurum.tahsilEdildi ? 'TAHSİL EDİLDİ' : 'BEKLİYOR')),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
             crossAxisAlignment: pw.CrossAxisAlignment.start,
             children: [
               pw.Text(_tr('AÇIKLAMA:'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
               pw.SizedBox(height: 4),
               pw.Text(_tr(h.aciklama ?? '-'), style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
             ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 60, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailTable(Hakedis h) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: [_tr('KALEM'), _tr('ORAN'), _tr('TUTAR')],
      data: [
        [_tr('BRÜT TUTAR'), '-', _currencyFormat.format(h.tutar)],
        [_tr('KDV'), '%${h.kdvOrani.toStringAsFixed(1)}', '+ ${_currencyFormat.format(h.kdvTutari)}'],
        [_tr('STOPAJ'), '%${h.stopajOrani.toStringAsFixed(1)}', '- ${_currencyFormat.format(h.stopajTutari)}'],
        [_tr('TEMİNAT'), '%${h.teminatOrani.toStringAsFixed(1)}', '- ${_currencyFormat.format(h.teminatTutari)}'],
        [_tr('NET TAHAKKUK'), '-', _currencyFormat.format(h.netTutar)],
      ],
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
      },
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  static pw.Widget _buildSummaryCard(double brut, double net, int count) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(_tr('Adet'), count.toString()),
          _summaryItem(_tr('Toplam Brüt'), _currencyFormat.format(brut)),
          _summaryItem(_tr('Toplam Net'), _currencyFormat.format(net)),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  static pw.Widget _buildFooter(DateTime date) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_tr('Rapor Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}'), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text(_tr('Belge Tarihi: ${DateFormat('dd.MM.yyyy').format(date)}'), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }
}
