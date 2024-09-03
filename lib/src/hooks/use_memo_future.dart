import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

T? useMemoFuture<T>(Future<T> Function() valueBuilder,
    {List<Object> keys = const []}) {
  final future = useMemoized(valueBuilder, keys);
  final snapshot = useFuture(future);
  if (snapshot.connectionState == ConnectionState.done) {
    return snapshot.data;
  }
  return null;
}
