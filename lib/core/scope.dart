import 'package:flutter/widgets.dart';
import '../data/fan_store.dart';

class FanScope extends InheritedNotifier<FanStore> {
  const FanScope({super.key, required FanStore store, required super.child})
    : super(notifier: store);

  static FanStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FanScope>();
    assert(scope != null, 'FanScope ausente');
    return scope!.notifier!;
  }
}
