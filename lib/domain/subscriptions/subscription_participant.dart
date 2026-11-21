import 'package:equatable/equatable.dart';

final class SubscriptionParticipant extends Equatable {
  const SubscriptionParticipant({
    required this.personId,
    required this.shareWeight,
  });

  final String personId;
  final int shareWeight;

  @override
  List<Object?> get props => [personId, shareWeight];
}
