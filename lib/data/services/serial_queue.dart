/// İşleri sırayla çalıştırır: bir iş bitmeden sonraki başlamaz (iç içe çağrı kilitlenir).
/// Boşta zincir tutulmaz; sıradaki ilk iş hemen başlar.
class SerialQueue {
  Future<void>? _tail;
  int _pending = 0;

  Future<T> run<T>(Future<T> Function() action) {
    final previous = _tail;
    _pending++;
    final result = previous == null
        ? Future<T>.sync(action)
        : previous.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (_) {}).whenComplete(() {
      _pending--;
      if (_pending == 0) _tail = null;
    });
    return result;
  }
}
