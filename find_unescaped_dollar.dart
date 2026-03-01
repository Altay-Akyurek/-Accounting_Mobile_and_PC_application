import 'dart:io';

void main() {
  final dir = Directory('lib/pages');
  final pattern1 = RegExp(r"'\$'");
  final pattern2 = RegExp(r'"\$"');

  for (final file in dir.listSync(recursive: true).whereType<File>()) {
    if (file.path.endsWith('.dart')) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (pattern1.hasMatch(line) || pattern2.hasMatch(line)) {
          print('${file.path}:${i + 1}: $line');
        }
      }
    }
  }
}
