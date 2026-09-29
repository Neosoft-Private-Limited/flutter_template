import 'package:app_bloc/app/router/app_router.dart';
import 'package:app_bloc/features/settings/cubit/settings_cubits.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Root widget. Dependencies are provided explicitly with
/// `RepositoryProvider`s (read with `context.read<T>()`); app-wide state
/// (theme, locale) lives in cubits above the router.
class App extends StatefulWidget {
  const new({
    required this.config,
    required this.postsRepository,
    required this.settingsRepository,
    required this.localDataCleaner,
    super.key,
    this.initialLocation = AppRoutes.home,
  });

  /// Wires the app from the shared start-up services.
  factory fromServices(AppServices services, {Key? key}) => App(
    key: key,
    config: services.config,
    postsRepository: createPostsRepository(
      apiClient: services.apiClient,
      graphQLClient: services.graphQLClient,
      database: services.database,
    ),
    settingsRepository: services.settingsRepository,
    localDataCleaner: services.localDataCleaner,
  );

  final AppConfig config;
  final PostsRepository postsRepository;
  final SettingsRepository settingsRepository;
  final LocalDataCleaner localDataCleaner;
  final String initialLocation;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: widget.config),
      RepositoryProvider.value(value: widget.postsRepository),
      RepositoryProvider.value(value: widget.settingsRepository),
      RepositoryProvider.value(value: widget.localDataCleaner),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(widget.settingsRepository)),
        BlocProvider(create: (_) => LocaleCubit(widget.settingsRepository)),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          routerConfig: _router,
          onGenerateTitle: (context) => context.l10n.appTitle,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: context.watch<ThemeCubit>().state,
          locale: context.watch<LocaleCubit>().state,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
        ),
      ),
    ),
  );
}
