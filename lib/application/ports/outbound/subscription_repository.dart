import 'package:subs/domain/subscriptions/subscription.dart';
import 'package:subs/domain/subscriptions/subscription_details.dart';
import 'package:subs/domain/subscriptions/subscription_summary.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';

abstract interface class SubscriptionRepository {
  Future<Subscription> create(Subscription subscription);

  Future<void> delete(String subscriptionId);

  Future<SubscriptionDetails?> findDetailsById(String subscriptionId);

  Future<void> updateWeights({
    required String subscriptionId,
    required Map<String, int> weights,
  });

  Future<void> updateInfo({
    required String subscriptionId,
    required int standardAmountCents,
    required PaymentMethod paymentMethod,
    required String? creditCardId,
    required String payerPersonId,
    required int billingDay,
    required DateTime startDate,
  });

  Stream<List<SubscriptionSummary>> watchCurrent(DateTime referenceDate);
}
