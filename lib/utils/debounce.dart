import 'dart:async';

class DebounceUtils {
  final Duration delay;
  Timer? _timer;

  DebounceUtils({this.delay = const Duration(milliseconds: 500)});

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
