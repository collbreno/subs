import 'package:subs/domain/subscriptions/payment_method.dart';
import 'package:subs/domain/subscriptions/subscription.dart';

final class ParticipantInput {
  const ParticipantInput({required this.personId, required this.shareWeight});

  final String personId;
  final int shareWeight;
}

final class CreateSubscriptionCommand {
  const CreateSubscriptionCommand({
    required this.title,
    required this.categoryId,
    required this.iconKey,
    required this.standardAmountCents,
    required this.paymentMethod,
    required this.billingDay,
    required this.startDate,
    required this.participants,
    this.creditCardId,
    this.payerPersonId,
    this.endDate,
  });

  final String title;
  final String categoryId;
  final String iconKey;
  final int standardAmountCents;
  final PaymentMethod paymentMethod;
  final String? creditCardId;
  final String? payerPersonId;
  final int billingDay;
  final DateTime startDate;
  final DateTime? endDate;
  final List<ParticipantInput> participants;
}

abstract interface class CreateSubscription {
  Future<Subscription> call(CreateSubscriptionCommand command);
}
