import 'dart:io';

void main() {
  final file = File('pubspec.yaml');
  final lines = file.readAsLinesSync();

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('version:')) {
      final parts = line.split('+');
      if (parts.length == 2) {
        final versionName = parts[0].split(':').last.trim();
        final versionCode = int.tryParse(parts[1].trim()) ?? 0;
        final newVersionCode = versionCode + 1;
        lines[i] = 'version: $versionName+$newVersionCode';
        print('✅ Version updated: $versionName+$newVersionCode');
      }
      break;
    }
  }

  file.writeAsStringSync(lines.join('\n'));
}
