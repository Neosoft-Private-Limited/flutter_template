import 'dart:async';

import 'package:app/app/base/base_page.dart';
import 'package:app/app/base/view_model.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

// Test doubles ---------------------------------------------------------------

class CounterViewModel extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final counterProvider = NotifierProvider<CounterViewModel, int>(
  CounterViewModel.new,
  isAutoDispose: true,
);

final List<String> events = [];

class CounterPage extends BasePage<CounterViewModel, int> {
  const new({super.key, this.blockBack = false});

  final bool blockBack;

  @override
  NotifierProvider<CounterViewModel, int> get viewModelProvider =>
      counterProvider;

  @override
  String title(BuildContext context) => 'Counter';

  @override
  Widget? buildFloatingActionButton(
    BuildContext context,
    CounterViewModel viewModel,
  ) => FloatingActionButton(
    onPressed: viewModel.increment,
    child: const Icon(Icons.add),
  );

  @override
  bool canPop(CounterViewModel viewModel) => !blockBack;

  @override
  void onPopInvoked(
    BuildContext context,
    CounterViewModel viewModel, {
    required bool didPop,
  }) => events.add('pop didPop=$didPop');

  @override
  void onInit(CounterViewModel viewModel) => events.add('init');

  @override
  void onDispose(CounterViewModel viewModel) => events.add('dispose');

  @override
  Widget buildView(
    BuildContext context,
    int state,
    CounterViewModel viewModel,
  ) => Text('count $state');
}

/// Controls what the async view model's `load` returns.
Future<Result<String>> Function() loader = () async => const Ok('first');

class GreetingViewModel extends AsyncViewModel<String> {
  @override
  Future<Result<String>> load() => loader();
}

final greetingProvider = AsyncNotifierProvider<GreetingViewModel, String>(
  GreetingViewModel.new,
  isAutoDispose: true,
);

class GreetingPage extends BaseAsyncPage<GreetingViewModel, String> {
  const new({super.key});

  @override
  AsyncNotifierProvider<GreetingViewModel, String> get viewModelProvider =>
      greetingProvider;

  @override
  Widget buildView(
    BuildContext context,
    String data,
    GreetingViewModel viewModel,
  ) => Column(
    children: [
      Text('data $data'),
      if (viewModel.refreshError != null) const Text('refresh failed'),
      TextButton(onPressed: viewModel.refresh, child: const Text('refresh')),
    ],
  );
}

Future<void> pumpPage(WidgetTester tester, Widget page) => tester.pumpWidget(
  ProviderScope(
    retry: (_, _) => null,
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    ),
  ),
);

// Tests ----------------------------------------------------------------------

void main() {
  setUp(events.clear);

  group('BasePage', () {
    testWidgets('builds the scaffold from the hooks and the view', (
      tester,
    ) async {
      await pumpPage(tester, const CounterPage());

      expect(find.widgetWithText(AppBar, 'Counter'), findsOneWidget);
      expect(find.text('count 0'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('count 1'), findsOneWidget);
    });

    testWidgets('calls onInit once and onDispose when removed', (tester) async {
      await pumpPage(tester, const CounterPage());
      await tester.pump();
      await tester.pump();
      expect(events, ['init']);

      await tester.pumpWidget(const SizedBox());

      expect(events, ['init', 'dispose']);
    });

    testWidgets('canPop blocks back navigation and reports it', (tester) async {
      await pumpPage(tester, const CounterPage(blockBack: true));
      await tester.pump();

      final popped = await tester.binding.handlePopRoute();
      await tester.pump();

      expect(events, contains('pop didPop=false'));
      expect(popped, isTrue);
      expect(find.text('count 0'), findsOneWidget);
    });
  });

  group('BaseAsyncPage', () {
    testWidgets('shows loading, then the data', (tester) async {
      final completer = Completer<Result<String>>();
      loader = () => completer.future;

      await pumpPage(tester, const GreetingPage());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(const Ok('hello'));
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

    testWidgets('a failed refresh keeps the data and exposes the error', (
      tester,
    ) async {
      loader = () async => const Ok('first');
      await pumpPage(tester, const GreetingPage());
      await tester.pumpAndSettle();

      loader = () async => const Err(TimeoutFailure('slow'));
      await tester.tap(find.text('refresh'));
      await tester.pumpAndSettle();

      expect(find.text('data first'), findsOneWidget);
      expect(find.text('refresh failed'), findsOneWidget);
    });
  });
}
