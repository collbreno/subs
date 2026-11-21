import 'package:equatable/equatable.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';
import 'package:subs/domain/subscriptions/subscription_participant.dart';

final class Subscription extends Equatable {
  Subscription({
    required this.id,
    required String title,
    required this.categoryId,
    required String iconKey,
    required this.standardAmount,
    required this.paymentMethod,
    required this.payerPersonId,
    required int billingDay,
    required this.startDate,
    required List<SubscriptionParticipant> participants,
    this.creditCardId,
    this.endDate,
    this.isActive = true,
  }) : title = _requiredText(title, 'title'),
       iconKey = _requiredText(iconKey, 'iconKey'),
       billingDay = _validDay(billingDay),
       participants = List.unmodifiable(_validateParticipants(participants)) {
    if (endDate != null && endDate!.isBefore(startDate)) {
      throw ArgumentError('End date must not precede start date');
    }
    if (paymentMethod == PaymentMethod.creditCard && creditCardId == null) {
      throw ArgumentError('A credit-card subscription requires a card');
    }
    if (paymentMethod == PaymentMethod.boleto && creditCardId != null) {
      throw ArgumentError('A boleto subscription cannot have a card');
    }
  }

  final String id;
  final String title;
  final String categoryId;
  final String iconKey;
  final Money standardAmount;
  final PaymentMethod paymentMethod;
  final String? creditCardId;
  final String payerPersonId;
  final int billingDay;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<SubscriptionParticipant> participants;

  static String _requiredText(String value, String field) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) throw ArgumentError('$field must not be blank');
    return trimmed;
  }

  static int _validDay(int day) {
    if (day < 1 || day > 31) {
      throw ArgumentError.value(day, 'billingDay', 'Must be between 1 and 31');
    }
    return day;
  }

  static List<SubscriptionParticipant> _validateParticipants(
    List<SubscriptionParticipant> participants,
  ) {
    if (participants.isEmpty) {
      throw ArgumentError('At least one participant is required');
    }
    final personIds = <String>{};
    for (final participant in participants) {
      if (participant.shareWeight < 0) {
        throw ArgumentError('Participant weights must not be negative');
      }
      if (!personIds.add(participant.personId)) {
        throw ArgumentError('A participant cannot be added twice');
      }
    }
    if (participants.every((participant) => participant.shareWeight == 0)) {
      throw ArgumentError('At least one participant weight must be positive');
    }
    return participants;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    categoryId,
    iconKey,
    standardAmount,
    paymentMethod,
    creditCardId,
    payerPersonId,
    billingDay,
    startDate,
    endDate,
    isActive,
    participants,
  ];
}
