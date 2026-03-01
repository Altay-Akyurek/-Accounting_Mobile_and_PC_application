import 'dart:io';

void main() {
  final methods = {
    'deleteInvoiceConfirm': '  String deleteInvoiceConfirm(String arg);',
    'deleteRecordConfirm': '  String deleteRecordConfirm(String arg);',
    'newItemType': '  String newItemType(String arg);',
    'editItemType': '  String editItemType(String arg);',
    'hakedisSettleConfirm': '  String hakedisSettleConfirm(int count, String amount);',
    'laborSettleConfirm': '  String laborSettleConfirm(int count, String amount);',
    'cariSettleConfirm': '  String cariSettleConfirm(int count, String amount);',
    'noIncomeExpenseYet': '  String noIncomeExpenseYet(String arg);',
    'laborSummaryDetail': '  String laborSummaryDetail(int worked, int leave, int sunday);',
  };

  final methodsTr = {
    'deleteInvoiceConfirm': '  @override\n  String deleteInvoiceConfirm(String arg) => "\\\$arg numaralı faturayı silmek istediğinize emin misiniz?";',
    'deleteRecordConfirm': '  @override\n  String deleteRecordConfirm(String arg) => "\\\$arg kaydını silmek istediğinize emin misiniz?";',
    'newItemType': '  @override\n  String newItemType(String arg) => "Yeni \\\$arg";',
    'editItemType': '  @override\n  String editItemType(String arg) => "\\\$arg Düzenle";',
    'hakedisSettleConfirm': '  @override\n  String hakedisSettleConfirm(int count, String amount) => "\\\$count adet hakediş ve toplam \\\$amount tutarı tahsil edilecek. Onaylıyor musunuz?";',
    'laborSettleConfirm': '  @override\n  String laborSettleConfirm(int count, String amount) => "\\\$count adet işçilik ve toplam \\\$amount tutarı ödenecek. Onaylıyor musunuz?";',
    'cariSettleConfirm': '  @override\n  String cariSettleConfirm(int count, String amount) => "\\\$count adet cari işlem ve toplam \\\$amount tutarı kapatılacak. Onaylıyor musunuz?";',
    'noIncomeExpenseYet': '  @override\n  String noIncomeExpenseYet(String arg) => "Henüz \\\$arg bulunmuyor.";',
    'laborSummaryDetail': '  @override\n  String laborSummaryDetail(int worked, int leave, int sunday) => "Çalışılan: \\\$worked | İzinli: \\\$leave | Pazar: \\\$sunday";',
  };

  final methodsEn = {
    'deleteInvoiceConfirm': '  @override\n  String deleteInvoiceConfirm(String arg) => "Are you sure you want to delete invoice \\\$arg?";',
    'deleteRecordConfirm': '  @override\n  String deleteRecordConfirm(String arg) => "Are you sure you want to delete record \\\$arg?";',
    'newItemType': '  @override\n  String newItemType(String arg) => "New \\\$arg";',
    'editItemType': '  @override\n  String editItemType(String arg) => "Edit \\\$arg";',
    'hakedisSettleConfirm': '  @override\n  String hakedisSettleConfirm(int count, String amount) => "\\\$count progress payments totaling \\\$amount will be collected. Confirm?";',
    'laborSettleConfirm': '  @override\n  String laborSettleConfirm(int count, String amount) => "\\\$count labor payments totaling \\\$amount will be paid. Confirm?";',
    'cariSettleConfirm': '  @override\n  String cariSettleConfirm(int count, String amount) => "\\\$count account operations totaling \\\$amount will be closed. Confirm?";',
    'noIncomeExpenseYet': '  @override\n  String noIncomeExpenseYet(String arg) => "No \\\$arg found yet.";',
    'laborSummaryDetail': '  @override\n  String laborSummaryDetail(int worked, int leave, int sunday) => "Worked: \\\$worked | Leave: \\\$leave | Sunday: \\\$sunday";',
  };

  void fixFile(String path, Map<String, String> replacements) {
    final file = File(path);
    if (!file.existsSync()) return;
    
    final lines = file.readAsLinesSync();
    final newLines = <String>[];
    
    bool skippingOverride = false;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      
      if (line.trim() == '@override') {
        final nextLine = (i + 1 < lines.length) ? lines[i + 1] : '';
        bool replaced = false;
        for (final key in replacements.keys) {
          if (nextLine.contains('String get $key ')) {
            newLines.add(replacements[key]!);
            skippingOverride = true; 
            replaced = true;
            break;
          }
        }
        if (!replaced) newLines.add(line);
      } else if (skippingOverride) {
        skippingOverride = false;
        continue;
      } else {
        bool replaced = false;
        for (final key in replacements.keys) {
          if (line.contains('String get $key;')) {
            newLines.add(replacements[key]!);
            replaced = true;
            break;
          }
        }
        if (!replaced) newLines.add(line);
      }
    }
    file.writeAsStringSync(newLines.join('\\n'));
  }

  fixFile('lib/l10n/app_localizations.dart', methods);
  fixFile('lib/l10n/app_localizations_tr.dart', methodsTr);
  fixFile('lib/l10n/app_localizations_en.dart', methodsEn);
}
