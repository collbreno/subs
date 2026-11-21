import 'package:subs/application/ports/inbound/get_subscription_details.dart';
import 'package:subs/application/ports/outbound/subscription_repository.dart';
import 'package:subs/domain/subscriptions/subscription_details.dart';

final class GetSubscriptionDetailsService implements GetSubscriptionDetails {
  const GetSubscriptionDetailsService(this._subscriptions);

  final SubscriptionRepository _subscriptions;

  @override
  Future<SubscriptionDetails?> call(String subscriptionId) =>
      _subscriptions.findDetailsById(subscriptionId);
}
