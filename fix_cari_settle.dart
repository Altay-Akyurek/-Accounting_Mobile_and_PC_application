import 'dart:io';
import 'dart:convert';

void main() {
  void update(String path, String text) {
    if (!File(path).existsSync()) return;
    var jsonMap = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    jsonMap['cariSettleConfirm'] = text;
    jsonMap['@cariSettleConfirm'] = {
      'placeholders': {
        'count': {'type': 'int'}
      }
    };
    File(path).writeAsStringSync(JsonEncoder.withIndent('  ').convert(jsonMap));
  }
  update('lib/l10n/app_tr.arb', '{count} adet cari işlem kapatılacak. Onaylıyor musunuz?');
  update('lib/l10n/app_en.arb', '{count} account operations will be closed. Confirm?');
}
