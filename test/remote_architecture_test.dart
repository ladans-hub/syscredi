import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'domínio/aplicação remotos independentes de Flutter, SDK e HTTP',
    () {
      final root = Directory('lib/features/api');
      for (final file
          in root
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final relative = file.path.substring(root.path.length + 1);
        final layer = relative.split('/').first;
        final source = file.readAsStringSync();
        final imports = RegExp(
          "(?:import|export) '([^']+)'",
        ).allMatches(source).map((match) => match[1]!);
        for (final dependency in imports) {
          if (['domain', 'application'].contains(layer)) {
            expect(
              dependency.startsWith('package:'),
              isFalse,
              reason: '${file.path}: $dependency',
            );
            expect(
              dependency.contains('infrastructure') ||
                  dependency.contains('presentation'),
              isFalse,
              reason: file.path,
            );
          }
          if (layer == 'domain') {
            expect(
              dependency.contains('application'),
              isFalse,
              reason: file.path,
            );
          }
          if (layer == 'presentation') {
            expect(
              dependency.contains('infrastructure'),
              isFalse,
              reason: file.path,
            );
          }
        }
      }
    },
  );
}
