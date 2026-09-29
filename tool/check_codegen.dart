// Regenerates code and fails if the output differs from the files on disk,
// i.e. someone edited a source (ARB file, drift table) without regenerating.
//
// Generators checked:
// - `flutter gen-l10n` in every package with an l10n.yaml;
// - `dart run build_runner build` in every workspace member that has
//   build_runner as a dev dependency (drift in `packages/database`).
//
// Works with or without git and leaves the regenerated files in place, so the
// fix is simply to commit them.
//
// Usage: dart run tool/check_codegen.dart   (or: melos run codegen:check)
import 'dart:io';

Iterable<Directory> _members() => [
  for (final root in ['apps', 'packages'])
    if (Directory(root).existsSync())
      ...Directory(root)
          .listSync()
          .whereType<Directory>()
          .where((d) => File('${d.path}/pubspec.yaml').existsSync()),
];

bool _usesBuildRunner(Directory package) => RegExp(
  r'^\s+build_runner:',
  multiLine: true,
).hasMatch(File('${package.path}/pubspec.yaml').readAsStringSync());

/// Contents of the generated files a generator may touch.
Map<String, String> _snapshot(Directory package, {required bool buildRunner}) {
  bool generated(String path) => buildRunner
      ? path.endsWith('.g.dart') || path.contains('/drift_schemas/')
      : path.contains('/lib/src/generated/');
  return {
    for (final file in package.listSync(recursive: true).whereType<File>())
      if (!file.path.contains('/.dart_tool/') &&
          !file.path.contains('/build/') &&
          generated(file.path))
        file.path: file.readAsStringSync(),
  };
}

void main() {
  final stale = <String>[];
  var checked = 0;

  for (final package in _members()) {
    final jobs = <(bool, List<String>)>[
      if (File('${package.path}/l10n.yaml').existsSync())
        (false, ['flutter', 'gen-l10n']),
      if (_usesBuildRunner(package))
        (true, ['dart', 'run', 'build_runner', 'build']),
    ];
    for (final (buildRunner, command) in jobs) {
      checked++;
      final before = _snapshot(package, buildRunner: buildRunner);
      final result = Process.runSync(
        command.first,
        command.skip(1).toList(),
        workingDirectory: package.path,
        runInShell: Platform.isWindows,
      );
      if (result.exitCode != 0) {
        stderr
          ..writeln('`${command.join(' ')}` failed in ${package.path}:')
          ..writeln(result.stdout)
          ..writeln(result.stderr);
        exitCode = result.exitCode;
        return;
      }
      final after = _snapshot(package, buildRunner: buildRunner);
      for (final path in {...before.keys, ...after.keys}) {
        if (before[path] != after[path]) stale.add(path);
      }
      stdout.writeln(
        'Checked `${command.join(' ')}` in ${package.path} '
        '(${after.length} generated files)',
      );
    }
  }

  if (checked == 0) {
    stderr.writeln('No code generators found; nothing to check.');
    exitCode = 1;
    return;
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
