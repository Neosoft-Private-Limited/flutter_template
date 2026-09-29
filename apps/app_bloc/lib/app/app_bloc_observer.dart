import 'package:app_foundation/app_foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

/// Logs state changes (at FINE level, so only with `LOG_LEVEL=debug`) and
/// reports unexpected errors thrown inside blocs.
class AppBlocObserver extends BlocObserver {
  new(this._reporter);

  final ErrorReporter _reporter;
  static final Logger _log = Logger('Bloc');

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _log.fine(
      () =>
          '${bloc.runtimeType}: ${change.currentState.runtimeType} -> '
          '${change.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _reporter.recordError(error, stackTrace, reason: '${bloc.runtimeType}');
    super.onError(bloc, error, stackTrace);
  }
}
