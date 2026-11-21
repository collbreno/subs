import 'package:equatable/equatable.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';

final class SubscriptionSummary extends Equatable {
  const SubscriptionSummary({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.iconKey,
    required this.standardAmount,
    required this.currentUserShare,
    required this.paymentMethod,
    required this.payerName,
    required this.participantCount,
    this.creditCardName,
  });

  final String id;
  final String title;
  final String categoryName;
  final String iconKey;
  final Money standardAmount;
  final Money currentUserShare;
  final PaymentMethod paymentMethod;
  final String payerName;
  final int participantCount;
  final String? creditCardName;

  @override
  List<Object?> get props => [
    id,
    title,
    categoryName,
    iconKey,
    standardAmount,
    currentUserShare,
    paymentMethod,
    payerName,
    participantCount,
    creditCardName,
  ];
}
