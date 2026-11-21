import 'package:subs/application/ports/outbound/id_generator.dart';
import 'package:uuid/uuid.dart';

final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  static const _uuid = Uuid();

  @override
  String next() => _uuid.v7();
}
