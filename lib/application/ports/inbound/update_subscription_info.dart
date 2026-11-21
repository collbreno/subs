import 'package:subs/domain/subscriptions/payment_method.dart';

final class UpdateSubscriptionInfoCommand {
  const UpdateSubscriptionInfoCommand({
    required this.subscriptionId,
    required this.standardAmountCents,
    required this.paymentMethod,
    required this.billingDay,
    required this.startDate,
    this.creditCardId,
    this.payerPersonId,
  });

  final String subscriptionId;
  final int standardAmountCents;
  final PaymentMethod paymentMethod;
  final String? creditCardId;
  final String? payerPersonId;
  final int billingDay;
  final DateTime startDate;
}

abstract interface class UpdateSubscriptionInfo {
  Future<void> call(UpdateSubscriptionInfoCommand command);
}
