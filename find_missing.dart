import 'dart:io';

void main() {
  final l10nFile = File('lib/l10n/app_localizations.dart');
  final l10nContent = l10nFile.readAsStringSync();
  final definedMatches = RegExp(r'String\s+(?:get\s+)?([a-zA-Z0-9_]+)').allMatches(l10nContent);
  final defined = definedMatches.map((m) => m.group(1)).toSet();

  final dir = Directory('lib/pages');
  final used = <String>{};
  final usagePattern = RegExp(r'AppLocalizations\.of\(context\)!\.([a-zA-Z0-9_]+)');

  for (final file in dir.listSync(recursive: true).whereType<File>()) {
    if (file.path.endsWith('.dart')) {
      final content = file.readAsStringSync();
      final matches = usagePattern.allMatches(content);
      for (final match in matches) {
        used.add(match.group(1)!);
      }
    }
  }

  final missing = used.difference(defined);
  if (missing.isEmpty) {
    print('No missing keys!');
  } else {
    print('Missing keys in app_localizations.dart:');
    for (final key in missing) {
      print(key);
    }
  }
}
