import 'package:subs/application/ports/inbound/create_subscription.dart';
import 'package:subs/application/ports/outbound/credit_card_repository.dart';
import 'package:subs/application/ports/outbound/id_generator.dart';
import 'package:subs/application/ports/outbound/subscription_repository.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';
import 'package:subs/domain/subscriptions/subscription.dart';
import 'package:subs/domain/subscriptions/subscription_participant.dart';

final class CreateSubscriptionService implements CreateSubscription {
  const CreateSubscriptionService(this._subscriptions, this._cards, this._ids);

  final SubscriptionRepository _subscriptions;
  final CreditCardRepository _cards;
  final IdGenerator _ids;

  @override
  Future<Subscription> call(CreateSubscriptionCommand command) async {
    final String payerPersonId;
    if (command.paymentMethod == PaymentMethod.creditCard) {
      final cardId = command.creditCardId;
      if (cardId == null) {
        throw ArgumentError('A credit-card subscription requires a card');
      }
      final card = await _cards.findById(cardId);
      if (card == null) throw ArgumentError('The credit card does not exist');
      payerPersonId = card.ownerPersonId;
    } else {
      payerPersonId =
          command.payerPersonId ??
          (throw ArgumentError('A boleto subscription requires a payer'));
    }

    final subscription = Subscription(
      id: _ids.next(),
      title: command.title,
      categoryId: command.categoryId,
      iconKey: command.iconKey,
      standardAmount: Money(command.standardAmountCents),
      paymentMethod: command.paymentMethod,
      creditCardId: command.creditCardId,
      payerPersonId: payerPersonId,
      billingDay: command.billingDay,
      startDate: command.startDate,
      endDate: command.endDate,
      participants: command.participants
          .map(
            (input) => SubscriptionParticipant(
              personId: input.personId,
              shareWeight: input.shareWeight,
            ),
          )
          .toList(growable: false),
    );

    return _subscriptions.create(subscription);
  }
}
