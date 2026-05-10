import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Error: lib directory not found');
    return;
  }

  libDir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final newContent = content.replaceAllMapped(
        RegExp(r'withValues\(alpha: ([0-9.]+)\)'),
        (match) => 'withOpacity(${match.group(1)})',
      );

      if (content != newContent) {
        entity.writeAsStringSync(newContent);
        print('Updated: ${entity.path}');
      }
    }
  });
}
