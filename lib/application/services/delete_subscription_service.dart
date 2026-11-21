import 'package:subs/application/ports/inbound/delete_subscription.dart';
import 'package:subs/application/ports/outbound/subscription_repository.dart';

final class DeleteSubscriptionService implements DeleteSubscription {
  const DeleteSubscriptionService(this._subscriptions);

  final SubscriptionRepository _subscriptions;

  @override
  Future<void> call(String subscriptionId) =>
      _subscriptions.delete(subscriptionId);
}
