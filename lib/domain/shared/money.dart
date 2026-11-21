import 'package:equatable/equatable.dart';

final class Money extends Equatable {
  Money(int cents) : cents = _validate(cents);

  final int cents;

  static int _validate(int cents) {
    if (cents < 0) {
      throw ArgumentError.value(cents, 'cents', 'Must not be negative');
    }
    return cents;
  }

  @override
  List<Object?> get props => [cents];
}
