import 'package:app_bloc/app/app.dart';
import 'package:app_bloc/app/app_bloc_observer.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Starts the Bloc app: runs the shared start-up sequence
/// (`initializeAppServices`, see app_foundation) and hands the services to
/// the widget tree.
Future<void> bootstrap({ErrorReporter? errorReporter}) async {
  final services = await initializeAppServices(errorReporter: errorReporter);
  if (services == null) return; // Invalid configuration: error screen shown.

  Bloc.observer = AppBlocObserver(services.errorReporter);
  runApp(App.fromServices(services));
}
