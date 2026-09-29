import 'package:app/app/app.dart';
import 'package:app/app/di/providers.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Starts the Riverpod app: runs the shared start-up sequence
/// (`initializeAppServices`, see app_foundation) and exposes the resulting
/// services to Riverpod through overrides.
Future<void> bootstrap({ErrorReporter? errorReporter}) async {
  final services = await initializeAppServices(errorReporter: errorReporter);
  if (services == null) return; // Invalid configuration: error screen shown.

  runApp(
    ProviderScope(
      // Retries are explicit (network retry interceptor, user-triggered
      // retry buttons); disable Riverpod's automatic provider retry.
      retry: (_, _) => null,
      overrides: overridesFor(services),
      child: const App(),
    ),
  );
}
