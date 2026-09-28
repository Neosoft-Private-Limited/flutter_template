/// Keys used in `Options.extra` to tune interceptor behaviour per request.
abstract final class RequestExtras {
  /// Set to `false` to skip attaching the access token (public endpoints).
  static const authenticate = 'networking.authenticate';

  /// Set to `true` to allow retries for a non-idempotent request that the
  /// backend guarantees to be safe to repeat (for example an idempotency key).
  static const retryable = 'networking.retryable';

  /// Internal: number of retries already attempted for this request.
  static const retryAttempt = 'networking.retryAttempt';

  /// Internal: time the request was sent, used for duration logs.
  static const startedAt = 'networking.startedAt';
}
