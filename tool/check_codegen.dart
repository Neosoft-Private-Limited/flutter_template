// Regenerates code and fails if the output differs from the files on disk,
// i.e. someone edited a source (ARB file) without regenerating.
//
// Works with or without git and leaves the regenerated files in place, so the
// fix is simply to commit them.
//
// Usage: dart run tool/check_codegen.dart   (or: melos run codegen:check)
import 'dart:io';

/// Packages that use `flutter gen-l10n` (identified by an l10n.yaml file).
Iterable<Directory> _l10nPackages() =>
    Directory('packages')
        .listSync()
        .whereType<Directory>()
        .where((d) => File('${d.path}/l10n.yaml').existsSync());

Map<String, String> _snapshot(Directory dir) => {
  if (dir.existsSync())
    for (final file in dir.listSync(recursive: true).whereType<File>())
      file.path: file.readAsStringSync(),
};

void main() {
  final stale = <String>[];
  final packages = _l10nPackages().toList();
  if (packages.isEmpty) {
    stderr.writeln('No packages with l10n.yaml found; nothing to check.');
    exitCode = 1;
    return;
  }

  for (final package in packages) {
    final generated = Directory('${package.path}/lib/src/generated');
    final before = _snapshot(generated);

    final result = Process.runSync(
      'flutter',
      ['gen-l10n'],
      workingDirectory: package.path,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      stderr
        ..writeln('flutter gen-l10n failed in ${package.path}:')
        ..writeln(result.stdout)
        ..writeln(result.stderr);
      exitCode = result.exitCode;
      return;
    }

    final after = _snapshot(generated);
    for (final path in {...before.keys, ...after.keys}) {
      if (before[path] != after[path]) stale.add(path);
    }
    stdout.writeln('Checked ${package.path} (${after.length} generated files)');
  }

  if (stale.isEmpty) {
    stdout.writeln('Generated files are up to date.');
    return;
  }
  stderr
    ..writeln('Generated files were out of date and have been regenerated:')
    ..writeAll(stale.map((p) => '  $p\n'))
    ..writeln('Commit the regenerated files.');
  exitCode = 1;
}
