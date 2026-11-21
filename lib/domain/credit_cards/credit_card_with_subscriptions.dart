import 'package:equatable/equatable.dart';
import 'package:subs/domain/credit_cards/credit_card.dart';
import 'package:subs/domain/people/person.dart';
import 'package:subs/domain/subscriptions/subscription_summary.dart';

final class CreditCardWithSubscriptions extends Equatable {
  const CreditCardWithSubscriptions({
    required this.card,
    required this.owner,
    required this.subscriptions,
  });

  final CreditCard card;
  final Person owner;
  final List<SubscriptionSummary> subscriptions;

  @override
  List<Object?> get props => [card, owner, subscriptions];
}
