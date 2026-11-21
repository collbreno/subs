import 'package:subs/application/ports/inbound/update_subscription_weights.dart';
import 'package:subs/application/ports/outbound/subscription_repository.dart';

final class UpdateSubscriptionWeightsService
    implements UpdateSubscriptionWeights {
  const UpdateSubscriptionWeightsService(this._subscriptions);

  final SubscriptionRepository _subscriptions;

  @override
  Future<void> call(UpdateSubscriptionWeightsCommand command) {
    if (command.weights.isEmpty) {
      throw ArgumentError('At least one participant is required.');
    }
    if (command.weights.any((input) => input.shareWeight < 0)) {
      throw ArgumentError('Weights must not be negative.');
    }
    if (command.weights.every((input) => input.shareWeight == 0)) {
      throw ArgumentError('At least one weight must be positive.');
    }
    return _subscriptions.updateWeights(
      subscriptionId: command.subscriptionId,
      weights: {
        for (final input in command.weights) input.personId: input.shareWeight,
      },
    );
  }
}
