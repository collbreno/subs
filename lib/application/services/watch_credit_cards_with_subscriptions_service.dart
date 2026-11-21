import 'package:subs/application/ports/inbound/watch_credit_cards_with_subscriptions.dart';
import 'package:subs/application/ports/outbound/credit_card_repository.dart';
import 'package:subs/domain/credit_cards/credit_card_with_subscriptions.dart';

final class WatchCreditCardsWithSubscriptionsService
    implements WatchCreditCardsWithSubscriptions {
  const WatchCreditCardsWithSubscriptionsService(this._cards);

  final CreditCardRepository _cards;

  @override
  Stream<List<CreditCardWithSubscriptions>> call({
    bool includeInactive = false,
  }) => _cards.watchWithSubscriptions(includeInactive: includeInactive);
}
