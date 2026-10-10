/// Maps [items] through [action] with at most [concurrency] futures in flight.
///
/// Output order matches input order. An error thrown by [action] propagates
/// once the in-flight work has settled; callers wanting per-item fallback
/// should catch inside [action].
Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items,
  int concurrency,
  Future<R> Function(T item) action,
) async {
  if (concurrency < 1) {
    throw ArgumentError.value(concurrency, 'concurrency', 'must be >= 1');
  }
  final results = List<R?>.filled(items.length, null);
  var next = 0;

  Future<void> worker() async {
    while (next < items.length) {
      final index = next++;
      results[index] = await action(items[index]);
    }
  }

  final workers = concurrency < items.length ? concurrency : items.length;
  await Future.wait(List.generate(workers, (_) => worker()));
  return results.cast<R>();
}
