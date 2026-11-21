import 'package:subs/application/ports/inbound/update_subscription_info.dart';
import 'package:subs/application/ports/outbound/credit_card_repository.dart';
import 'package:subs/application/ports/outbound/subscription_repository.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';

final class UpdateSubscriptionInfoService implements UpdateSubscriptionInfo {
  const UpdateSubscriptionInfoService(this._subscriptions, this._cards);

  final SubscriptionRepository _subscriptions;
  final CreditCardRepository _cards;

  @override
  Future<void> call(UpdateSubscriptionInfoCommand command) async {
    Money(command.standardAmountCents);
    if (command.billingDay < 1 || command.billingDay > 31) {
      throw ArgumentError.value(
        command.billingDay,
        'billingDay',
        'Must be between 1 and 31',
      );
    }

    final String payerPersonId;
    String? creditCardId;
    if (command.paymentMethod == PaymentMethod.creditCard) {
      creditCardId = command.creditCardId;
      if (creditCardId == null) {
        throw ArgumentError('A credit-card subscription requires a card.');
      }
      final card = await _cards.findById(creditCardId);
      if (card == null) throw ArgumentError('The credit card does not exist.');
      payerPersonId = card.ownerPersonId;
    } else {
      payerPersonId =
          command.payerPersonId ??
          (throw ArgumentError('A boleto subscription requires a payer.'));
    }

    await _subscriptions.updateInfo(
      subscriptionId: command.subscriptionId,
      standardAmountCents: command.standardAmountCents,
      paymentMethod: command.paymentMethod,
      creditCardId: creditCardId,
      payerPersonId: payerPersonId,
      billingDay: command.billingDay,
      startDate: command.startDate,
    );
  }
}
