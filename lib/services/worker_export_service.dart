import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/worker.dart';
import '../services/database_helper.dart';

class WorkerExportService {
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

  static Future<void> exportToPDF({
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
          _buildHeader(startDate, endDate, totalCost, totalHours, filterWorkerId != null ? _tr(workerMap[filterWorkerId]?.adSoyad) : null),
          pw.SizedBox(height: 20),
          ...sortedWorkerIds.map((workerId) {
            final worker = workerMap[workerId];
            final puantajs = groupedPuantaj[workerId]!;
            return _buildWorkerSection(worker, puantajs, projectNames);
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

  static pw.Widget _buildHeader(DateTime start, DateTime end, double cost, double hours, [String? workerName]) {
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
              pw.Text(_tr(workerName != null ? '$workerName OZET RAPORU' : 'ISCI OZET RAPORU'), 
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
              pw.Text(_currencyFormat.format(cost), style: pw.TextStyle(color: PdfColors.teal200, fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Text(_tr('$hours Saat Toplam Calisma'), style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWorkerSection(Worker? worker, List<Puantaj> puantajs, Map<int, String> projectNames) {
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
                pw.Text(_tr(worker?.adSoyad ?? 'Bilinmiyor'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_tr('Toplam: $workerTotalHours Saat | ${_currencyFormat.format(workerTotalCost)}'), style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            headers: [_tr('TARIH'), _tr('PROJE'), _tr('SAAT'), _tr('MESAI'), _tr('TUTAR')],
            data: puantajs.map((p) {
              final cost = worker != null ? DatabaseHelper.instance.calculateLaborCost(p, worker) : 0.0;
              return [
                DateFormat('dd.MM.yyyy').format(p.tarih),
                _tr(projectNames[p.projectId] ?? '-'),
                p.saat.toString(),
                p.mesai.toString(),
                _currencyFormat.format(cost),
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Future<void> exportToExcel({
    required DateTime startDate,
    required DateTime endDate,
    required List<Puantaj> puantajlar,
    required Map<int, Worker> workerMap,
    required Map<int, String> projectNames,
    int? filterWorkerId,
  }) async {
    var excel = Excel.createExcel();
    var sheet = excel['Isci Ozet Raporu'];
    excel.delete('Sheet1');

    // Header Style
    CellStyle headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#011627'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.appendRow([TextCellValue(filterWorkerId != null ? '${_tr(workerMap[filterWorkerId]?.adSoyad) ?? ''} ÖZET RAPORU' : 'İŞÇİ ÖZET RAPORU')]);
    sheet.appendRow([TextCellValue('${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}')]);
    sheet.appendRow([]);

    // Column Headers
    sheet.appendRow([
      TextCellValue('PERSONEL'),
      TextCellValue('TARİH'),
      TextCellValue('PROJE'),
      TextCellValue('SAAT'),
      TextCellValue('MESAİ'),
      TextCellValue('TUTAR'),
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
          TextCellValue(worker?.adSoyad ?? 'Bilinmiyor'),
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
