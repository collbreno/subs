import 'package:subs/domain/subscriptions/subscription_details.dart';

abstract interface class GetSubscriptionDetails {
  Future<SubscriptionDetails?> call(String subscriptionId);
}
