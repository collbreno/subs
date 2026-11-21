import 'package:equatable/equatable.dart';

final class CreditCard extends Equatable {
  const CreditCard({
    required this.id,
    required this.name,
    required this.ownerPersonId,
    required this.closingDay,
    required this.dueDay,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String ownerPersonId;
  final int closingDay;
  final int dueDay;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    name,
    ownerPersonId,
    closingDay,
    dueDay,
    isActive,
  ];
}
