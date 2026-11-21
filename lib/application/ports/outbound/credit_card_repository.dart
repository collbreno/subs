import 'package:subs/domain/credit_cards/credit_card.dart';
import 'package:subs/domain/credit_cards/credit_card_with_subscriptions.dart';

abstract interface class CreditCardRepository {
  Future<CreditCard> create(CreditCard card);

  Future<CreditCard?> findById(String cardId);

  Stream<List<CreditCardWithSubscriptions>> watchWithSubscriptions({
    bool includeInactive = false,
  });
}
