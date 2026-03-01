import 'dart:io';
import 'dart:convert';

void main() {
  final keysToReplaceTr = {
    'deleteCariConfirm': '{arg} carisini silmek istediğinize emin misiniz?',
    'deleteFailed': '{arg} silinemedi.',
    'deleteInvoiceConfirm': '{arg} faturasını silmek istediğinize emin misiniz?',
    'deleteRecordConfirm': '{arg} kaydını silmek istediğinize emin misiniz?',
    'newItemType': 'Yeni {arg}',
    'editItemType': '{arg} Düzenle',
    'hakedisSettleConfirm': '{count} adet hakediş ve toplam {amount} tutarı tahsil edilecek. Onaylıyor musunuz?',
    'laborSettleConfirm': '{count} adet işçilik ve toplam {amount} tutarı ödenecek. Onaylıyor musunuz?',
    'cariSettleConfirm': '{count} adet cari işlem ve toplam {amount} tutarı kapatılacak. Onaylıyor musunuz?',
    'laborSummaryDetail': 'Çalışılan: {worked} | İzinli: {leave} | Pazar: {sunday}',
    'noIncomeExpenseYet': 'Henüz {arg} bulunmuyor.',
  };

  final keysToReplaceEn = {
    'deleteCariConfirm': 'Are you sure you want to delete account {arg}?',
    'deleteFailed': 'Failed to delete {arg}.',
    'deleteInvoiceConfirm': 'Are you sure you want to delete invoice {arg}?',
    'deleteRecordConfirm': 'Are you sure you want to delete record {arg}?',
    'newItemType': 'New {arg}',
    'editItemType': 'Edit {arg}',
    'hakedisSettleConfirm': '{count} progress payments totaling {amount} will be collected. Confirm?',
    'laborSettleConfirm': '{count} labor payments totaling {amount} will be paid. Confirm?',
    'cariSettleConfirm': '{count} account operations totaling {amount} will be closed. Confirm?',
    'laborSummaryDetail': 'Worked: {worked} | Leave: {leave} | Sunday: {sunday}',
    'noIncomeExpenseYet': 'No {arg} found yet.',
  };

  final placeholderConfigs = {
    'deleteCariConfirm': {'arg': {'type': 'String'}},
    'deleteFailed': {'arg': {'type': 'String'}},
    'deleteInvoiceConfirm': {'arg': {'type': 'String'}},
    'deleteRecordConfirm': {'arg': {'type': 'String'}},
    'newItemType': {'arg': {'type': 'String'}},
    'editItemType': {'arg': {'type': 'String'}},
    'hakedisSettleConfirm': {'count': {'type': 'int'}, 'amount': {'type': 'String'}},
    'laborSettleConfirm': {'count': {'type': 'int'}, 'amount': {'type': 'String'}},
    'cariSettleConfirm': {'count': {'type': 'int'}, 'amount': {'type': 'String'}},
    'laborSummaryDetail': {'worked': {'type': 'int'}, 'leave': {'type': 'int'}, 'sunday': {'type': 'int'}},
    'noIncomeExpenseYet': {'arg': {'type': 'String'}},
  };

  void updateArb(String path, Map<String, String> replacements) {
    final file = File(path);
    if (!file.existsSync()) return;
    final content = file.readAsStringSync();
    var jsonMap = jsonDecode(content) as Map<String, dynamic>;
    
    for (final key in replacements.keys) {
      jsonMap[key] = replacements[key]!;
      jsonMap['@$key'] = {
        'placeholders': placeholderConfigs[key]
      };
    }
    
    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(jsonMap));
    print('Updated $path');
  }

  updateArb('lib/l10n/app_tr.arb', keysToReplaceTr);
  updateArb('lib/l10n/app_en.arb', keysToReplaceEn);
}
