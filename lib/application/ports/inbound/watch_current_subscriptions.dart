import 'package:subs/domain/subscriptions/subscription_summary.dart';

abstract interface class WatchCurrentSubscriptions {
  Stream<List<SubscriptionSummary>> call(DateTime referenceDate);
}
