import 'dart:isolate';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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

  static double _calculateLaborCostIsolate(Puantaj p, Worker w) {
    if (p.status == PuantajStatus.izinsiz) return 0;
    double hourlyRate = 0;
    if (w.maasTuru == WorkerSalaryType.saatlik) {
      hourlyRate = w.maasTutari;
    } else if (w.maasTuru == WorkerSalaryType.gunluk) {
      hourlyRate = w.maasTutari / 8;
    } else if (w.maasTuru == WorkerSalaryType.aylik) {
      hourlyRate = w.maasTutari / 240;
    }
    return (p.saat * hourlyRate) + (p.mesai * hourlyRate * 1.5);
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
    Function(String)? onStatusUpdate,
    bool Function()? isCancelled,
  }) async {
    final translations = {
      'workerReport': filterWorkerId != null ? l10n.workerReport_caps(workerMap[filterWorkerId]?.adSoyad ?? '') : '',
      'workerSummaryReport': l10n.workerSummaryReport_caps,
      'totalWorkHours': l10n.totalWorkHours(''),
      'unknown': l10n.unknown,
      'date': l10n.date,
      'project': l10n.project,
      'hour': l10n.hour,
      'mesai': l10n.mesai,
      'amountLabel': l10n.amountLabel,
      'total': l10n.total,
    };

    onStatusUpdate?.call(l10n.localeName == 'tr' ? "Fontlar hazırlanıyor..." : "Preparing fonts...");
    
    Uint8List? regBytes;
    Uint8List? boldBytes;
    
    try {
      // Safe attempt in main thread with 2s timeout
      // Wrap in a future that completes with null on timeout
      final List<Uint8List?> fontResults = await Future.wait([
        PdfGoogleFonts.robotoRegular().then((f) => _getFontBytes(f)).timeout(const Duration(seconds: 2), onTimeout: () => null),
        PdfGoogleFonts.robotoBold().then((f) => _getFontBytes(f)).timeout(const Duration(seconds: 2), onTimeout: () => null),
      ]);
      regBytes = fontResults[0];
      boldBytes = fontResults[1];
    } catch (e) {
      debugPrint("Main thread font prep error: $e");
    }

    onStatusUpdate?.call(l10n.localeName == 'tr' ? "İşlem başlatılıyor..." : "Starting process...");
    
    final receivePort = ReceivePort();
    final params = {
      'sendPort': receivePort.sendPort,
      'puantajlar': puantajlar,
      'workerMap': workerMap,
      'projectNames': projectNames,
      'startDate': startDate,
      'endDate': endDate,
      'totalCost': totalCost,
      'totalHours': totalHours,
      'filterWorkerId': filterWorkerId,
      'translations': translations,
      'locale': l10n.localeName,
      'regBytes': regBytes,
      'boldBytes': boldBytes,
    };

    final isolate = await Isolate.spawn(_generateWorkerPdfIsolate, params);
    
    try {
      await for (var msg in receivePort) {
        if (isCancelled?.call() ?? false) {
          receivePort.close();
          isolate.kill();
          return;
        }
        if (msg is String) {
          if (msg.startsWith("ERROR:")) {
            receivePort.close();
            isolate.kill();
            throw Exception(msg.substring(6));
          } else if (msg.startsWith("STATUS:")) {
            onStatusUpdate?.call(msg.substring(7));
          }
        } else if (msg is Uint8List) {
          receivePort.close();
          isolate.kill();
          
          String namePart = filterWorkerId != null ? '${_tr(workerMap[filterWorkerId]?.adSoyad) ?? 'Isci'}_' : '';
          String prefix = filterWorkerId != null ? (l10n.localeName == 'tr' ? 'Raporu' : 'Report') : (l10n.localeName == 'tr' ? 'Isci_Ozet_Raporu' : 'Worker_Summary_Report');
          String fileName = '${namePart}${prefix}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';

          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => msg,
            name: fileName,
          );
          break;
        }
      }
    } catch (e) {
      receivePort.close();
      isolate.kill();
      rethrow;
    }
  }

  static Future<void> _generateWorkerPdfIsolate(Map<String, dynamic> params) async {
    final SendPort sendPort = params['sendPort'];
    try {
      final RootIsolateToken? token = params['token'];
      if (token != null) {
        BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      }

      sendPort.send(params['locale'] == 'tr' ? "STATUS:Veriler işleniyor..." : "STATUS:Processing data...");
      final List<Puantaj> puantajlar = params['puantajlar'];
      final Map<int, Worker> workerMap = params['workerMap'];
      final Map<int, String> projectNames = params['projectNames'];
      final DateTime startDate = params['startDate'];
      final DateTime endDate = params['endDate'];
      final double totalCost = params['totalCost'];
      final double totalHours = params['totalHours'];
      final int? filterWorkerId = params['filterWorkerId'];
      final Map<String, String> translations = params['translations'];
      final String locale = params['locale'];
      final Uint8List? regBytes = params['regBytes'];
      final Uint8List? boldBytes = params['boldBytes'];

      sendPort.send(params['locale'] == 'tr' ? "STATUS:Fontlar hazırlanıyor..." : "STATUS:Preparing fonts...");
      pw.Font fontRegular;
      pw.Font fontBold;

      // Use passed bytes or fallback to Helvetica (Fastest, no network)
      if (regBytes != null && boldBytes != null) {
        fontRegular = pw.Font.ttf(regBytes.buffer.asByteData());
        fontBold = pw.Font.ttf(boldBytes.buffer.asByteData());
      } else {
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      sendPort.send(params['locale'] == 'tr' ? "STATUS:PDF oluşturuluyor..." : "STATUS:Generating PDF...");

      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(
        locale: locale,
        symbol: locale == 'tr' ? 'TL' : '\$',
        decimalDigits: 2,
      );

      // Set default theme with fonts
      final theme = pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      );

      // Grouping
      Map<int, List<Puantaj>> groupedPuantaj = {};
      for (var p in puantajlar) {
        if (filterWorkerId == null || p.workerId == filterWorkerId) {
          groupedPuantaj.putIfAbsent(p.workerId, () => []).add(p);
        }
      }

      final sortedWorkerIds = groupedPuantaj.keys.toList()
        ..sort((a, b) => (_tr(workerMap[a]?.adSoyad) ?? '').compareTo(_tr(workerMap[b]?.adSoyad) ?? ''));

      // If no data for selected range, handle gracefully
      if (sortedWorkerIds.isEmpty) {
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Center(
              child: pw.Text(locale == 'tr' ? "Seçili tarihler arasında kayıt bulunamadı." : "No records found for selected dates.", style: pw.TextStyle(font: fontRegular)),
            ),
          ),
        );
        final bytes = await pdf.save();
        sendPort.send(bytes);
        return;
      }

      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeaderIsolate(translations, currencyFormat, startDate, endDate, totalCost, totalHours, locale, filterWorkerId != null ? _tr(workerMap[filterWorkerId]?.adSoyad) : null),
          build: (context) => [
            pw.SizedBox(height: 20),
            ...sortedWorkerIds.expand((workerId) {
              final worker = workerMap[workerId];
              final puantajs = groupedPuantaj[workerId]!;
              return _buildWorkerSectionIsolate(translations, currencyFormat, worker, puantajs, projectNames, locale);
            }),
          ],
        ),
      );

      sendPort.send(params['locale'] == 'tr' ? "STATUS:Dosya kaydediliyor..." : "STATUS:Saving file...");
      final bytes = await pdf.save();
      sendPort.send(bytes);
    } catch (e, stack) {
      sendPort.send("ERROR:Isolate Error: $e\nStack Trace: $stack");
    }
  }

  static pw.Widget _buildHeaderIsolate(Map<String, String> translations, NumberFormat currencyFormat, DateTime start, DateTime end, double cost, double hours, String locale, [String? workerName]) {
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
              pw.Text(_tr(workerName != null ? translations['workerReport'] : translations['workerSummaryReport']), 
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
              pw.Text(_tr('${hours.toString()} ${locale == 'tr' ? 'Saat Çalışma' : 'Hours Work'}'), style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildWorkerSectionIsolate(Map<String, String> translations, NumberFormat currencyFormat, Worker? worker, List<Puantaj> puantajs, Map<int, String> projectNames, String locale) {
    double workerTotalHours = 0;
    double workerTotalCost = 0;
    for (var p in puantajs) {
      workerTotalHours += p.saat;
      if (worker != null) {
        workerTotalCost += _calculateLaborCostIsolate(p, worker);
      }
    }

    return [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        color: PdfColors.grey200,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_tr(worker?.adSoyad ?? translations['unknown']), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(_tr('${workerTotalHours.toString()} ${locale == 'tr' ? 'Saat' : 'Hours'} | ${currencyFormat.format(workerTotalCost)}'), style: pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: const pw.TextStyle(fontSize: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        headers: [_tr(translations['date']), _tr(translations['project']), _tr(translations['hour']), _tr(translations['mesai']), _tr(translations['amountLabel'])],
        data: puantajs.map((p) {
          final cost = worker != null ? _calculateLaborCostIsolate(p, worker) : 0.0;
          return [
            DateFormat('dd.MM.yyyy').format(p.tarih),
            _tr(projectNames[p.projectId] ?? '-'),
            p.saat.toString(),
            p.mesai.toString(),
            _tr(currencyFormat.format(cost)),
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 15),
    ];
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
    final translations = {
      'workerReport': filterWorkerId != null ? l10n.workerReport_caps(workerMap[filterWorkerId]?.adSoyad ?? '') : '',
      'workerSummaryReport': l10n.workerSummaryReport_caps,
      'personal': l10n.personal,
      'date': l10n.date,
      'project': l10n.project,
      'hour': l10n.hour,
      'mesai': l10n.mesai,
      'amountLabel': l10n.amountLabel,
      'unknown': l10n.unknown,
      'total': l10n.total,
    };

    final params = {
      'puantajlar': puantajlar,
      'workerMap': workerMap,
      'projectNames': projectNames,
      'startDate': startDate,
      'endDate': endDate,
      'filterWorkerId': filterWorkerId,
      'translations': translations,
    };

    final Uint8List? bytes = await compute(_generateExcelBytes, params);

    if (bytes != null) {
      String namePart = filterWorkerId != null ? '${_tr(workerMap[filterWorkerId]?.adSoyad) ?? 'Isci'}_' : '';
      String prefix = filterWorkerId != null ? (l10n.localeName == 'tr' ? 'Ozet' : 'Summary') : (l10n.localeName == 'tr' ? 'Isci_Ozet_Raporu' : 'Worker_Summary_Report');
      String fileName = '${namePart}${prefix}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx';

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }

  static Future<Uint8List?> _generateExcelBytes(Map<String, dynamic> params) async {
    final List<Puantaj> puantajlar = params['puantajlar'];
    final Map<int, Worker> workerMap = params['workerMap'];
    final Map<int, String> projectNames = params['projectNames'];
    final DateTime startDate = params['startDate'];
    final DateTime endDate = params['endDate'];
    final int? filterWorkerId = params['filterWorkerId'];
    final Map<String, String> translations = params['translations'];

    var excel = Excel.createExcel();
    var sheetName = translations['workerSummaryReport'] ?? 'Report';
    var sheet = excel[sheetName];
    excel.delete('Sheet1');

    // Header Style
    CellStyle headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#011627'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.appendRow([TextCellValue(translations['workerReport']!.isEmpty ? translations['workerSummaryReport']! : translations['workerReport']!)]);
    sheet.appendRow([TextCellValue('${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}')]);
    sheet.appendRow([]);

    // Column Headers
    sheet.appendRow([
      TextCellValue(translations['personal']!),
      TextCellValue(translations['date']!),
      TextCellValue(translations['project']!),
      TextCellValue(translations['hour']!),
      TextCellValue(translations['mesai']!),
      TextCellValue(translations['amountLabel']!),
    ]);

    // Apply header style
    for (int i = 0; i < 6; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3)).cellStyle = headerStyle;
    }

    // Grouping
    Map<int, List<Puantaj>> groupedPuantaj = {};
    for (var p in puantajlar) {
      if (filterWorkerId == null || p.workerId == filterWorkerId) {
        groupedPuantaj.putIfAbsent(p.workerId, () => []).add(p);
      }
    }

    final sortedWorkerIds = groupedPuantaj.keys.toList()
      ..sort((a, b) => (workerMap[a]?.adSoyad ?? '').compareTo(workerMap[b]?.adSoyad ?? ''));

    double totalAmount = 0;
    double totalHours = 0;
    double totalMesai = 0;

    for (var workerId in sortedWorkerIds) {
      final worker = workerMap[workerId];
      final puantajs = groupedPuantaj[workerId]!;
      
      for (var p in puantajs) {
        final cost = worker != null ? _calculateLaborCostIsolate(p, worker) : 0.0;
        totalAmount += cost;
        totalHours += p.saat;
        totalMesai += p.mesai;
        
        sheet.appendRow([
          TextCellValue(worker?.adSoyad ?? translations['unknown']!),
          TextCellValue(DateFormat('dd.MM.yyyy').format(p.tarih)),
          TextCellValue(projectNames[p.projectId] ?? '-'),
          DoubleCellValue(p.saat.toDouble()),
          DoubleCellValue(p.mesai.toDouble()),
          DoubleCellValue(cost),
        ]);
      }
    }

    // Append Total Row
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue(translations['total'] ?? 'TOTAL'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalHours),
      DoubleCellValue(totalMesai),
      DoubleCellValue(totalAmount),
    ]);

    // Style Total Row
    int lastRow = sheet.maxRows - 1;
    CellStyle totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#F0F0F0'),
    );
    for (int i = 0; i < 6; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: lastRow)).cellStyle = totalStyle;
    }

    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 25);
    sheet.setColumnWidth(3, 10);
    sheet.setColumnWidth(4, 10);
    sheet.setColumnWidth(5, 15);

    final bytes = excel.save();
    return bytes != null ? Uint8List.fromList(bytes) : null;
  }

  static Uint8List? _getFontBytes(pw.Font font) {
    try {
      return (font as dynamic).ttf.font.buffer.asUint8List();
    } catch (_) {
      try {
        return (font as dynamic).contents.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    }
  }
}
