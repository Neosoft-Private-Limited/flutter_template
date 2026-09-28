/// The deployment environment the app was built for.
///
/// The names match the Android product flavors, the iOS schemes and the files
/// in `config/` (`dev.json`, `staging.json`, `prod.json`).
enum AppEnvironment {
  dev,
  staging,
  prod;

  bool get isProduction => this == AppEnvironment.prod;

  /// Parses a flavor or `APP_ENV` value. Returns `null` for unknown values.
  static AppEnvironment? tryParse(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final environment in values) {
      if (environment.name == normalized) return environment;
    }
    return null;
  }
}
