import 'dart:io';

void main() {
  void fixNewlines(String path) {
    final file = File(path);
    if (!file.existsSync()) return;
    
    var content = file.readAsStringSync();
    // Replace literal '\n' characters with actual newlines
    content = content.replaceAll(r'\n', '\n');
    file.writeAsStringSync(content);
    print('Fixed newlines in $path');
  }

  fixNewlines('lib/l10n/app_localizations.dart');
  fixNewlines('lib/l10n/app_localizations_tr.dart');
  fixNewlines('lib/l10n/app_localizations_en.dart');
}
