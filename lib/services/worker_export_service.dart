import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/worker.dart';
import '../services/database_helper.dart';
import '../l10n/app_localizations.dart';

class WorkerExportService {
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

  static Future<void> exportToPDF({
    required AppLocalizations l10n,
    required DateTime startDate,
    required DateTime endDate,
    required List<Puantaj> puantajlar,
    required Map<int, Worker> workerMap,
    required Map<int, String> projectNames,
    required double totalCost,
    required double totalHours,
    int? filterWorkerId,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = _getCurrencyFormat(l10n);
    
    // Grouping
    Map<int, List<Puantaj>> groupedPuantaj = {};
    for (var p in puantajlar) {
      if (filterWorkerId == null || p.workerId == filterWorkerId) {
        groupedPuantaj.putIfAbsent(p.workerId, () => []).add(p);
      }
    }

    final sortedWorkerIds = groupedPuantaj.keys.toList()
      ..sort((a, b) => (_tr(workerMap[a]?.adSoyad) ?? '').compareTo(_tr(workerMap[b]?.adSoyad) ?? ''));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(l10n, currencyFormat, startDate, endDate, totalCost, totalHours, filterWorkerId != null ? _tr(workerMap[filterWorkerId]?.adSoyad) : null),
          pw.SizedBox(height: 20),
          ...sortedWorkerIds.map((workerId) {
            final worker = workerMap[workerId];
            final puantajs = groupedPuantaj[workerId]!;
            return _buildWorkerSection(l10n, currencyFormat, worker, puantajs, projectNames);
          }),
        ],
      ),
    );

    String fileName = filterWorkerId != null 
        ? '${_tr(workerMap[filterWorkerId]?.adSoyad) ?? 'Isci'}_Raporu_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf'
        : 'Isci_Ozet_Raporu_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  static pw.Widget _buildHeader(AppLocalizations l10n, NumberFormat currencyFormat, DateTime start, DateTime end, double cost, double hours, [String? workerName]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blueGrey900,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_tr(workerName != null ? l10n.workerReport_caps(workerName) : l10n.workerSummaryReport_caps), 
                style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Text(
                '${DateFormat('dd.MM.yyyy').format(start)} - ${DateFormat('dd.MM.yyyy').format(end)}',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(currencyFormat.format(cost), style: pw.TextStyle(color: PdfColors.teal200, fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Text(_tr(l10n.totalWorkHours(hours.toString())), style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWorkerSection(AppLocalizations l10n, NumberFormat currencyFormat, Worker? worker, List<Puantaj> puantajs, Map<int, String> projectNames) {
    double workerTotalHours = 0;
    double workerTotalCost = 0;
    for (var p in puantajs) {
      workerTotalHours += p.saat;
      if (worker != null) {
        workerTotalCost += DatabaseHelper.instance.calculateLaborCost(p, worker);
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            color: PdfColors.grey200,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(_tr(worker?.adSoyad ?? l10n.unknown), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_tr(l10n.totalHoursAndAmount(workerTotalHours.toString(), currencyFormat.format(workerTotalCost))), style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            headers: [_tr(l10n.date), _tr(l10n.project), _tr(l10n.hour), _tr(l10n.mesai), _tr(l10n.amountLabel)],
            data: puantajs.map((p) {
              final cost = worker != null ? DatabaseHelper.instance.calculateLaborCost(p, worker) : 0.0;
              return [
                DateFormat('dd.MM.yyyy').format(p.tarih),
                _tr(projectNames[p.projectId] ?? '-'),
                p.saat.toString(),
                p.mesai.toString(),
                _tr(currencyFormat.format(cost)),
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Future<void> exportToExcel({
    required AppLocalizations l10n,
    required DateTime startDate,
    required DateTime endDate,
    required List<Puantaj> puantajlar,
    required Map<int, Worker> workerMap,
    required Map<int, String> projectNames,
    int? filterWorkerId,
  }) async {
    var excel = Excel.createExcel();
    var sheetName = l10n.workerSummaryReport_caps;
    var sheet = excel[sheetName];
    excel.delete('Sheet1');

    // Header Style
    CellStyle headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#011627'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.appendRow([TextCellValue(filterWorkerId != null ? (l10n.workerReport_caps(_tr(workerMap[filterWorkerId]?.adSoyad) ?? '')) : l10n.workerSummaryReport_caps)]);
    sheet.appendRow([TextCellValue('${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}')]);
    sheet.appendRow([]);

    // Column Headers
    sheet.appendRow([
      TextCellValue(l10n.personal),
      TextCellValue(l10n.date),
      TextCellValue(l10n.project),
      TextCellValue(l10n.hour),
      TextCellValue(l10n.mesai),
      TextCellValue(l10n.amountLabel),
    ]);

    // Apply header style (row 4, columns 0-5)
    for (int i = 0; i < 6; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3)).cellStyle = headerStyle;
    }

    // Sorting and grouping like in UI
    Map<int, List<Puantaj>> groupedPuantaj = {};
    for (var p in puantajlar) {
      if (filterWorkerId == null || p.workerId == filterWorkerId) {
        groupedPuantaj.putIfAbsent(p.workerId, () => []).add(p);
      }
    }

    final sortedWorkerIds = groupedPuantaj.keys.toList()
      ..sort((a, b) => (workerMap[a]?.adSoyad ?? '').compareTo(workerMap[b]?.adSoyad ?? ''));

    for (var workerId in sortedWorkerIds) {
      final worker = workerMap[workerId];
      final puantajs = groupedPuantaj[workerId]!;
      
      for (var p in puantajs) {
        final cost = worker != null ? DatabaseHelper.instance.calculateLaborCost(p, worker) : 0.0;
        sheet.appendRow([
          TextCellValue(worker?.adSoyad ?? l10n.unknown),
          TextCellValue(DateFormat('dd.MM.yyyy').format(p.tarih)),
          TextCellValue(projectNames[p.projectId] ?? '-'),
          DoubleCellValue(p.saat.toDouble()),
          DoubleCellValue(p.mesai.toDouble()),
          DoubleCellValue(cost),
        ]);
      }
    }

    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 25);
    sheet.setColumnWidth(3, 10);
    sheet.setColumnWidth(4, 10);
    sheet.setColumnWidth(5, 15);

    final bytes = excel.save();
    if (bytes != null) {
      String fileName = filterWorkerId != null 
          ? '${_tr(workerMap[filterWorkerId]?.adSoyad) ?? 'Isci'}_Ozet_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx'
          : 'Isci_Ozet_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx';

      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: fileName,
      );
    }
  }
}
