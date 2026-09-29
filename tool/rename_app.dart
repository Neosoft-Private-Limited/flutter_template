// Renames the example app's identifiers and display names in one step.
//
// Usage (from the repository root, with a clean git working tree):
//   dart run tool/rename_app.dart \
//     --android-id com.acme.shop \
//     --ios-id com.acme.shop \
//     --name "Acme Shop" \
//     [--app-dir apps/app] [--dry-run]
//
// Flavors get suffixes automatically: `<id>.dev`, `<id>.staging` and the
// display names "<name> Dev", "<name> Staging" and "<name>".
//
// Afterwards: update `appTitle` in packages/localization/lib/l10n/*.arb, run
// `melos run codegen`, rebuild, and review `git diff`.
import 'dart:io';

final _androidId = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');
final _iosId = RegExp(r'^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$');

void main(List<String> args) {
  final options = _parse(args);
  final androidId = options['android-id'];
  final iosId = options['ios-id'];
  final name = options['name'];
  final appDir = options['app-dir'] ?? 'apps/app';
  final dryRun = options.containsKey('dry-run');

  if (androidId == null || iosId == null || name == null) {
    _fail(
      'Usage: dart run tool/rename_app.dart --android-id <id> --ios-id <id> '
      '--name "<Display Name>" [--app-dir apps/app] [--dry-run]',
    );
  }
  if (!_androidId.hasMatch(androidId)) {
    _fail(
      'Invalid --android-id "$androidId": use reverse-DNS segments of '
      'letters, digits and underscores, e.g. com.acme.shop.',
    );
  }
  if (!_iosId.hasMatch(iosId)) {
    _fail(
      'Invalid --ios-id "$iosId": use reverse-DNS segments of letters, '
      'digits and hyphens, e.g. com.acme.shop.',
    );
  }

  final gradle = File('$appDir/android/app/build.gradle.kts');
  final prodXcconfig = File('$appDir/ios/Flutter/prod.xcconfig');
  for (final file in [gradle, prodXcconfig]) {
    if (!file.existsSync()) _fail('Not found: ${file.path}');
  }

  final oldAndroidId = _match(gradle, RegExp('applicationId = "([^"]+)"'));
  final oldIosId = _match(
    prodXcconfig,
    RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = (\S+)'),
  );
  final oldName = _match(prodXcconfig, RegExp('APP_DISPLAY_NAME = (.+)'));
  final oldNames = {
    'dev': _match(
      File('$appDir/ios/Flutter/dev.xcconfig'),
      RegExp('APP_DISPLAY_NAME = (.+)'),
    ),
    'staging': _match(
      File('$appDir/ios/Flutter/staging.xcconfig'),
      RegExp('APP_DISPLAY_NAME = (.+)'),
    ),
  };

  final edits = <String, String Function(String)>{
    gradle.path: (s) => s
        .replaceAll('"$oldAndroidId"', '"$androidId"')
        .replaceAll('"${oldNames['dev']}"', '"$name Dev"')
        .replaceAll('"${oldNames['staging']}"', '"$name Staging"')
        .replaceAll('"$oldName"', '"$name"'),
    for (final flavor in ['dev', 'staging', 'prod'])
      '$appDir/ios/Flutter/$flavor.xcconfig': (s) => s
          .replaceAll(
            RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = \S+'),
            'PRODUCT_BUNDLE_IDENTIFIER = '
            '${flavor == 'prod' ? iosId : '$iosId.$flavor'}',
          )
          .replaceAll(
            RegExp('APP_DISPLAY_NAME = .+'),
            'APP_DISPLAY_NAME = '
            '${switch (flavor) {
              'dev' => '$name Dev',
              'staging' => '$name Staging',
              _ => name,
            }}',
          ),
    '$appDir/ios/Runner.xcodeproj/project.pbxproj': (s) =>
        s.replaceAll('"$oldIosId.RunnerTests"', '"$iosId.RunnerTests"'),
    '$appDir/web/index.html': (s) => s.replaceAll(oldName, name),
    '$appDir/web/manifest.json': (s) => s.replaceAll(oldName, name),
  };

  // Kotlin package: move MainActivity to the new package directory.
  final kotlinRoot = '$appDir/android/app/src/main/kotlin';
  final oldActivity = File(
    '$kotlinRoot/${oldAndroidId.replaceAll('.', '/')}/MainActivity.kt',
  );
  final newActivity = File(
    '$kotlinRoot/${androidId.replaceAll('.', '/')}/MainActivity.kt',
  );

  stdout
    ..writeln('Android: $oldAndroidId -> $androidId')
    ..writeln('iOS:     $oldIosId -> $iosId')
    ..writeln('Name:    $oldName -> $name');

  for (final MapEntry(key: path, value: edit) in edits.entries) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final before = file.readAsStringSync();
    final after = edit(before);
    if (before == after) continue;
    stdout.writeln('${dryRun ? 'would update' : 'updated'} $path');
    if (!dryRun) file.writeAsStringSync(after);
  }

  if (oldActivity.existsSync() && oldActivity.path != newActivity.path) {
    stdout.writeln(
      '${dryRun ? 'would move' : 'moved'} ${oldActivity.path} -> '
      '${newActivity.path}',
    );
    if (!dryRun) {
      final source = oldActivity.readAsStringSync().replaceFirst(
        'package $oldAndroidId',
        'package $androidId',
      );
      newActivity
        ..createSync(recursive: true)
        ..writeAsStringSync(source);
      oldActivity.deleteSync();
      _deleteEmptyParents(oldActivity.parent, Directory(kotlinRoot));
    }
  }

  stdout.writeln(
    dryRun
        ? '\nDry run: nothing was changed.'
        : '\nDone. Update appTitle in packages/localization/lib/l10n/*.arb, '
              'run `melos run codegen`, then review `git diff`.',
  );
}

Map<String, String> _parse(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) _fail('Unexpected argument "$arg".');
    final key = arg.substring(2);
    if (key == 'dry-run') {
      options[key] = 'true';
    } else if (i + 1 < args.length) {
      options[key] = args[++i];
    } else {
      _fail('Missing value for $arg.');
    }
  }
  return options;
}

String _match(File file, RegExp pattern) {
  if (!file.existsSync()) _fail('Not found: ${file.path}');
  final match = pattern.firstMatch(file.readAsStringSync());
  if (match == null) _fail('Could not find ${pattern.pattern} in ${file.path}');
  return match.group(1)!.trim();
}

void _deleteEmptyParents(Directory dir, Directory stopAt) {
  var current = dir;
  while (current.path != stopAt.path &&
      current.existsSync() &&
      current.listSync().isEmpty) {
    current.deleteSync();
    current = current.parent;
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(64);
}
