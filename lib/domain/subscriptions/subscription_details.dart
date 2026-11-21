import 'package:equatable/equatable.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';

final class SubscriptionParticipantDetails extends Equatable {
  const SubscriptionParticipantDetails({
    required this.personId,
    required this.name,
    required this.isCurrentUser,
    required this.shareWeight,
    required this.shareAmount,
  });

  final String personId;
  final String name;
  final bool isCurrentUser;
  final int shareWeight;
  final Money shareAmount;

  @override
  List<Object?> get props => [
    personId,
    name,
    isCurrentUser,
    shareWeight,
    shareAmount,
  ];
}

final class SubscriptionDetails extends Equatable {
  const SubscriptionDetails({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.iconKey,
    required this.standardAmount,
    required this.currentUserShare,
    required this.paymentMethod,
    required this.payerPersonId,
    required this.payerName,
    required this.billingDay,
    required this.startDate,
    required this.participants,
    this.creditCardName,
    this.creditCardId,
  });

  final String id;
  final String title;
  final String categoryName;
  final String iconKey;
  final Money standardAmount;
  final Money currentUserShare;
  final PaymentMethod paymentMethod;
  final String payerPersonId;
  final String payerName;
  final int billingDay;
  final DateTime startDate;
  final List<SubscriptionParticipantDetails> participants;
  final String? creditCardName;
  final String? creditCardId;

  @override
  List<Object?> get props => [
    id,
    title,
    categoryName,
    iconKey,
    standardAmount,
    currentUserShare,
    paymentMethod,
    payerPersonId,
    payerName,
    billingDay,
    startDate,
    participants,
    creditCardName,
    creditCardId,
  ];
}
