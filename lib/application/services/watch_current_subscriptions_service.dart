import 'package:subs/application/ports/inbound/watch_current_subscriptions.dart';
import 'package:subs/application/ports/outbound/subscription_repository.dart';
import 'package:subs/domain/subscriptions/subscription_summary.dart';

final class WatchCurrentSubscriptionsService
    implements WatchCurrentSubscriptions {
  const WatchCurrentSubscriptionsService(this._subscriptions);

  final SubscriptionRepository _subscriptions;

  @override
  Stream<List<SubscriptionSummary>> call(DateTime referenceDate) =>
      _subscriptions.watchCurrent(referenceDate);
}
