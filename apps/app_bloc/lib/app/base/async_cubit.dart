import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

/// State of a screen that loads data: loading, loaded or failed.
@immutable
sealed class ViewState<T> {
  const new();
}

final class ViewLoading<T> extends ViewState<T> {
  const new();

  @override
  bool operator ==(Object other) => other is ViewLoading<T>;

  @override
  int get hashCode => (ViewLoading<T>).hashCode;
}

final class ViewData<T> extends ViewState<T> {
  const new(this.data, {this.isRefreshing = false, this.refreshError});

  final T data;
  final bool isRefreshing;

  /// Set when a refresh failed while [data] is still shown.
  final AppFailure? refreshError;

  @override
  bool operator ==(Object other) =>
      other is ViewData<T> &&
      other.data == data &&
      other.isRefreshing == isRefreshing &&
      other.refreshError == refreshError;

  @override
  int get hashCode => Object.hash(data, isRefreshing, refreshError);
}

final class ViewFailure<T> extends ViewState<T> {
  const new(this.error);

  final AppFailure error;

  @override
  bool operator ==(Object other) =>
      other is ViewFailure<T> && identical(other.error, error);

  @override
  int get hashCode => error.hashCode;
}

/// Base class for view models of screens that load data (the Bloc
/// counterpart of the Riverpod app's `AsyncViewModel`).
///
/// Implement [load]; call [fetch] to load (the page does it in `onInit`),
/// [refresh] to reload while keeping data visible. Add intent methods to the
/// subclass.
abstract class AsyncCubit<T> extends Cubit<ViewState<T>> {
  new() : super(ViewLoading<T>());

  /// Loads the screen data, usually one repository call.
  Future<Result<T>> load();

  /// Loads from scratch, showing the loading state (first load and retry).
  Future<void> fetch() async {
    emit(ViewLoading<T>());
    final result = await load();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => ViewData(value),
      Err(:final failure) => ViewFailure(failure),
    });
  }

  /// Reloads while keeping the current data visible. Without data it behaves
  /// like [fetch]; while a refresh is running it does nothing.
  Future<void> refresh() async {
    final current = state;
    if (current is! ViewData<T>) {
      await fetch();
      return;
    }
    if (current.isRefreshing) return;
    emit(ViewData(current.data, isRefreshing: true));
    final result = await load();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => ViewData(value),
      Err(:final failure) => ViewData(current.data, refreshError: failure),
    });
  }
}
