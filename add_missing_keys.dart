import 'dart:io';
import 'dart:convert';

void main() {
  final used = <String>{};
  final usagePattern = RegExp(r'AppLocalizations\.of\(context\)!\.([a-zA-Z0-9_]+)');
  final dir = Directory('lib/pages');
  for (final file in dir.listSync(recursive: true).whereType<File>()) {
    if (file.path.endsWith('.dart')) {
      final matches = usagePattern.allMatches(file.readAsStringSync());
      for (final match in matches) used.add(match.group(1)!);
    }
  }

  void updateArb(String path) {
    final file = File(path);
    if (!file.existsSync()) return;
    final content = file.readAsStringSync();
    var jsonMap = jsonDecode(content) as Map<String, dynamic>;
    
    int added = 0;
    for (final key in used) {
      if (!jsonMap.containsKey(key) && !jsonMap.containsKey('@$key')) {
        jsonMap[key] = key; // temporary placeholder translation
        added++;
      }
    }
    
    if (added > 0) {
      final encoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync(encoder.convert(jsonMap));
      print('Added $added keys to $path');
    } else {
      print('No new keys needed for $path');
    }
  }

  updateArb('lib/l10n/app_en.arb');
  updateArb('lib/l10n/app_tr.arb');
}
