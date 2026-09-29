import 'package:app_bloc/app/base/async_cubit.dart';
import 'package:app_bloc/app/base/base_page.dart';
import 'package:app_bloc/features/settings/cubit/settings_cubit.dart';
import 'package:app_bloc/features/settings/cubit/settings_cubits.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:storage/storage.dart';

import '../helpers/test_app.dart';

// Test doubles ---------------------------------------------------------------

final List<String> events = [];

class CounterCubit extends Cubit<int> {
  new() : super(0);

  void increment() => emit(state + 1);

  @override
  Future<void> close() {
    events.add('closed');
    return super.close();
  }
}

class CounterPage extends BasePage<CounterCubit, int> {
  const new({super.key});

  @override
  CounterCubit createViewModel(BuildContext context) => CounterCubit();

  @override
  String title(BuildContext context) => 'Counter';

  @override
  void onInit(CounterCubit viewModel) => events.add('init ${viewModel.state}');

  @override
  void onStateChanged(
    BuildContext context,
    int state,
    CounterCubit viewModel,
  ) => events.add('changed $state');

  @override
  Widget? buildFloatingActionButton(
    BuildContext context,
    CounterCubit viewModel,
  ) => FloatingActionButton(
    onPressed: viewModel.increment,
    child: const Icon(Icons.add),
  );

  @override
  Widget buildView(BuildContext context, int state, CounterCubit viewModel) =>
      Text('count $state');
}

Future<Result<String>> Function() loader = () async => const Ok('first');

class GreetingCubit extends AsyncCubit<String> {
  @override
  Future<Result<String>> load() => loader();
}

class GreetingPage extends BaseAsyncPage<GreetingCubit, String> {
  const new({super.key});

  @override
  GreetingCubit createViewModel(BuildContext context) => GreetingCubit();

  @override
  Widget buildData(
    BuildContext context,
    String data,
    GreetingCubit viewModel, {
    AppFailure? refreshError,
  }) => Text('data $data');
}

Future<void> pumpPage(WidgetTester tester, Widget page) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: page,
  ),
);

// Tests ----------------------------------------------------------------------

void main() {
  setUp(events.clear);

  group('BasePage', () {
    testWidgets('builds the scaffold, rebuilds on state changes', (
      tester,
    ) async {
      await pumpPage(tester, const CounterPage());

      expect(find.widgetWithText(AppBar, 'Counter'), findsOneWidget);
      expect(find.text('count 0'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('count 1'), findsOneWidget);
      expect(events, contains('changed 1'));
    });

    testWidgets('runs onInit once and closes the view model on removal', (
      tester,
    ) async {
      await pumpPage(tester, const CounterPage());
      await tester.pump();
      await tester.pump();
      expect(events, ['init 0']);

      await tester.pumpWidget(const SizedBox());

      expect(events, ['init 0', 'closed']);
    });
  });

  group('BaseAsyncPage', () {
    testWidgets('fetches on init and shows the data', (tester) async {
      loader = () async => const Ok('hello');

      await pumpPage(tester, const GreetingPage());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('data hello'), findsOneWidget);
    });

    testWidgets('shows a localized error with a working retry', (tester) async {
      loader = () async => const Err(NetworkFailure('offline'));
      await pumpPage(tester, const GreetingPage());
      await tester.pumpAndSettle();
      expect(find.textContaining('offline'), findsOneWidget);

      loader = () async => const Ok('back');
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('data back'), findsOneWidget);
    });
  });

  group('SettingsCubit', () {
    test('mirrors the app-wide cubits and forwards intents', () async {
      final settings = SettingsRepository(InMemoryKeyValueStore());
      final themeCubit = ThemeCubit(settings);
      final localeCubit = LocaleCubit(settings);
      final cubit = SettingsCubit(
        config: testConfig,
        themeCubit: themeCubit,
        localeCubit: localeCubit,
        localDataCleaner: LocalDataCleaner(
          keyValueStore: InMemoryKeyValueStore(),
          secureStore: InMemorySecureStore(),
        ),
      );
      addTearDown(() async {
        await cubit.close();
        await themeCubit.close();
        await localeCubit.close();
      });

      await cubit.selectThemeMode(ThemeMode.dark);
      await cubit.selectLocale(const Locale('es'));
      await Future<void>.delayed(Duration.zero);

      expect(themeCubit.state, ThemeMode.dark);
      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.locale, const Locale('es'));

      await cubit.selectLocale(null);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.locale, isNull);
    });
  });
}
