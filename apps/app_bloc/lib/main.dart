import 'package:app_bloc/bootstrap.dart';

/// Single entry point for every environment. The environment comes from
/// `--flavor` and `--dart-define-from-file=config/<env>.json`.
Future<void> main() => bootstrap();
