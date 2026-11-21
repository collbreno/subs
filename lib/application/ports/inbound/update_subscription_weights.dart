final class SubscriptionWeightInput {
  const SubscriptionWeightInput({
    required this.personId,
    required this.shareWeight,
  });

  final String personId;
  final int shareWeight;
}

final class UpdateSubscriptionWeightsCommand {
  const UpdateSubscriptionWeightsCommand({
    required this.subscriptionId,
    required this.weights,
  });

  final String subscriptionId;
  final List<SubscriptionWeightInput> weights;
}

abstract interface class UpdateSubscriptionWeights {
  Future<void> call(UpdateSubscriptionWeightsCommand command);
}
