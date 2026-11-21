import 'package:subs/domain/credit_cards/credit_card_with_subscriptions.dart';

abstract interface class WatchCreditCardsWithSubscriptions {
  Stream<List<CreditCardWithSubscriptions>> call({
    bool includeInactive = false,
  });
}
