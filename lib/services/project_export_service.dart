import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/hakedis.dart';
import '../models/project.dart';
import '../l10n/app_localizations.dart';

class ProjectExportService {
  static String _tr(String? text) {
    if (text == null) return '';
    var result = text;
    var turkishChars = {'İ': 'I', 'ı': 'i', 'Ş': 'S', 'ş': 's', 'Ğ': 'G', 'ğ': 'g', 'Ü': 'U', 'ü': 'u', 'Ö': 'O', 'ö': 'o', 'Ç': 'C', 'ç': 'c'};
    turkishChars.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }

  static NumberFormat _getCurrencyFormat(AppLocalizations l10n) {
    final locale = l10n.localeName;
    return NumberFormat.currency(
      locale: locale,
      symbol: locale == 'tr' ? 'TL' : '\$',
      decimalDigits: 2,
    );
  }

  static Future<void> exportHakedisPDF(AppLocalizations l10n, Hakedis h, Project p) async {
    final pdf = pw.Document();
    final currencyFormat = _getCurrencyFormat(l10n);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(_tr(l10n.hakedisDocument_caps), _tr(p.ad)),
              pw.SizedBox(height: 30),
              _buildInfoSection(l10n, h, p),
              pw.SizedBox(height: 40),
              _buildDetailTable(l10n, currencyFormat, h),
              pw.Spacer(),
              _buildFooter(l10n, h.tarih),
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

  static Future<void> exportProjectHakedislerPDF(AppLocalizations l10n, Project p, List<Hakedis> hakedisler) async {
    final pdf = pw.Document();
    final currencyFormat = _getCurrencyFormat(l10n);

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
          _buildHeader(_tr(l10n.projectHakedisReport_caps), _tr(p.ad)),
          pw.SizedBox(height: 20),
          _buildSummaryCard(l10n, currencyFormat, toplamBrut, toplamNet, hakedisler.length),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: [_tr(l10n.titleLabel), _tr(l10n.date), _tr(l10n.brutAmount_caps), _tr(l10n.deductions), _tr(l10n.netAccrual_caps), _tr(l10n.status)],
            data: hakedisler.map((h) {
              return [
                _tr(h.baslik),
                DateFormat('dd.MM.yyyy').format(h.tarih),
                currencyFormat.format(h.tutar),
                currencyFormat.format(h.stopajTutari + h.teminatTutari),
                currencyFormat.format(h.netTutar),
                _tr(h.durum == HakedisDurum.tahsilEdildi ? l10n.collected_caps : l10n.pending_caps),
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

  static pw.Widget _buildInfoSection(AppLocalizations l10n, Hakedis h, Project p) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('${l10n.project}:', _tr(p.ad)),
              _infoRow('${l10n.hakedis_short}:', _tr(h.baslik)),
              _infoRow('${l10n.date}:', DateFormat('dd.MM.yyyy').format(h.tarih)),
              _infoRow('${l10n.status}:', _tr(h.durum == HakedisDurum.tahsilEdildi ? l10n.collected_caps : l10n.pending_caps)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
             crossAxisAlignment: pw.CrossAxisAlignment.start,
             children: [
               pw.Text('${l10n.description}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
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
          pw.SizedBox(width: 70, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailTable(AppLocalizations l10n, NumberFormat currencyFormat, Hakedis h) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: [_tr(l10n.item), _tr(l10n.rate), _tr(l10n.amountLabel)],
      data: [
        [_tr(l10n.brutAmount_caps), '-', currencyFormat.format(h.tutar)],
        [_tr(l10n.vat), '%${h.kdvOrani.toStringAsFixed(1)}', '+ ${currencyFormat.format(h.kdvTutari)}'],
        [_tr(l10n.stopaj), '%${h.stopajOrani.toStringAsFixed(1)}', '- ${currencyFormat.format(h.stopajTutari)}'],
        [_tr(l10n.teminat), '%${h.teminatOrani.toStringAsFixed(1)}', '- ${currencyFormat.format(h.teminatTutari)}'],
        [_tr(l10n.netAccrual_caps), '-', currencyFormat.format(h.netTutar)],
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

  static pw.Widget _buildSummaryCard(AppLocalizations l10n, NumberFormat currencyFormat, double brut, double net, int count) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(l10n.quantity, count.toString()),
          _summaryItem(l10n.totalBrut, currencyFormat.format(brut)),
          _summaryItem(l10n.totalNet, currencyFormat.format(net)),
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

  static pw.Widget _buildFooter(AppLocalizations l10n, DateTime date) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_tr(l10n.reportDateLabel(DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()))), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text(_tr(l10n.documentDateLabel(DateFormat('dd.MM.yyyy').format(date))), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }
}
