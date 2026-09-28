// Runs the app's integration tests on a connected device, emulator or
// simulator with the dev flavor and configuration.
//
// Usage (from the repository root):
//   dart run tool/run_integration_tests.dart [--device <id>]
//   DEVICE=emulator-5554 melos run test:integration
//
// `flutter devices` lists the available device IDs. Integration tests need a
// device: they cannot run on the headless `flutter test` runner.
import 'dart:io';

Future<void> main(List<String> args) async {
  final deviceIndex = args.indexOf('--device');
  final device = deviceIndex >= 0 && deviceIndex + 1 < args.length
      ? args[deviceIndex + 1]
      : Platform.environment['DEVICE'];

  const appDir = 'apps/app';
  if (!Directory('$appDir/integration_test').existsSync()) {
    stderr.writeln('No integration tests found in $appDir/integration_test.');
    exitCode = 1;
    return;
  }

  final command = [
    'test',
    'integration_test',
    '--flavor',
    'dev',
    '--dart-define-from-file=config/dev.json',
    if (device != null && device.isNotEmpty) ...['-d', device],
  ];
  stdout.writeln('> (cd $appDir) flutter ${command.join(' ')}');

  final process = await Process.start(
    'flutter',
    command,
    workingDirectory: appDir,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln(
      'Integration tests failed (exit code $exitCode). If no device was '
      'found, start an emulator/simulator or pass --device <id>.',
    );
  }
}
