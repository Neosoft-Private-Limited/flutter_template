// Runs the apps' integration tests on a connected device, emulator or
// simulator with the dev flavor and configuration.
//
// Usage (from the repository root):
//   dart run tool/run_integration_tests.dart [--device <id>] [--app <dir>]
//   DEVICE=emulator-5554 melos run test:integration
//
// Without --app, every app under apps/ that has an integration_test/ folder
// runs in turn. `flutter devices` lists the available device IDs.
// Integration tests need a device: they cannot run on the headless
// `flutter test` runner.
import 'dart:io';

String? _option(List<String> args, String name, String envName) {
  final index = args.indexOf(name);
  if (index >= 0 && index + 1 < args.length) return args[index + 1];
  final fromEnv = Platform.environment[envName];
  return fromEnv == null || fromEnv.isEmpty ? null : fromEnv;
}

Future<void> main(List<String> args) async {
  final device = _option(args, '--device', 'DEVICE');
  final onlyApp = _option(args, '--app', 'APP');

  final apps = onlyApp != null
      ? [onlyApp]
      : (Directory('apps')
            .listSync()
            .whereType<Directory>()
            .map((d) => d.path)
            .where((p) => Directory('$p/integration_test').existsSync())
            .toList()
          ..sort());

  if (apps.isEmpty ||
      apps.any((app) => !Directory('$app/integration_test').existsSync())) {
    stderr.writeln('No integration tests found in ${apps.join(', ')}.');
    exitCode = 1;
    return;
  }

  for (final app in apps) {
    final command = [
      'test',
      'integration_test',
      '--flavor',
      'dev',
      '--dart-define-from-file=config/dev.json',
      if (device != null) ...['-d', device],
    ];
    stdout.writeln('> (cd $app) flutter ${command.join(' ')}');
    final process = await Process.start(
      'flutter',
      command,
      workingDirectory: app,
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final code = await process.exitCode;
    if (code != 0) {
      stderr.writeln(
        'Integration tests failed in $app (exit code $code). If no device '
        'was found, start an emulator/simulator or pass --device <id>.',
      );
      exitCode = code;
      return;
    }
  }
}
