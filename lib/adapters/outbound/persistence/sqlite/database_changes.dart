import 'dart:async';

final class DatabaseChanges {
  final _controller = StreamController<void>.broadcast();

  void notify() => _controller.add(null);

  Stream<T> watch<T>(T Function() load) async* {
    yield load();
    await for (final _ in _controller.stream) {
      yield load();
    }
  }

  Future<void> close() => _controller.close();
}
