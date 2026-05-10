import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return;

  libDir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('safe_haptic.dart')) {
      var content = entity.readAsStringSync();
      var changed = false;

      if (content.contains('HapticFeedback.')) {
        content = content.replaceAll('HapticFeedback.', 'SafeHaptic.');
        if (!content.contains("import '../utils/safe_haptic.dart';")) {
          // Add import (this is a bit naive but should work for most cases in this project)
          // Find the last import
          final lastImportIndex = content.lastIndexOf('import \'');
          if (lastImportIndex != -1) {
            final endOfImport = content.indexOf(';', lastImportIndex);
            if (endOfImport != -1) {
              // Try to find the correct relative path
              final depth = entity.path.split(Platform.pathSeparator).length - 2;
              final prefix = depth == 0 ? './' : '../' * depth;
              final importPath = "import '${prefix}utils/safe_haptic.dart';\n";
              content = content.substring(0, endOfImport + 1) + '\n' + importPath + content.substring(endOfImport + 1);
            }
          }
        }
        changed = true;
      }

      if (changed) {
        entity.writeAsStringSync(content);
        print('Updated: ${entity.path}');
      }
    }
  });
}
