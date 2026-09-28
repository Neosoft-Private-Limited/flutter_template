import 'package:core/core.dart';
import 'package:flutter/services.dart';

/// Reads the build configuration from `--dart-define` values and the native
/// flavor, then validates it. Throws a [ConfigException] when invalid.
///
/// `String.fromEnvironment` must be called with constant keys, so each key is
/// listed explicitly. Add new keys here and in `AppConfig.fromMap`.
AppConfig readAppConfig() => AppConfig.fromMap(
  const {
    ConfigKeys.environment: String.fromEnvironment(ConfigKeys.environment),
    ConfigKeys.apiBaseUrl: String.fromEnvironment(ConfigKeys.apiBaseUrl),
    ConfigKeys.logLevel: String.fromEnvironment(ConfigKeys.logLevel),
    ConfigKeys.networkLogs: String.fromEnvironment(ConfigKeys.networkLogs),
  },
  // Set by `flutter run/build --flavor <name>` on Android and iOS; null on web.
  // The analyzer sees the constant's value for the current analysis context
  // (null) and flags it as redundant; at build time it carries the flavor.
  // ignore: avoid_redundant_argument_values
  flavor: appFlavor,
);
