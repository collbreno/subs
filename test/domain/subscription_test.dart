import 'package:flutter_test/flutter_test.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';
import 'package:subs/domain/subscriptions/subscription.dart';
import 'package:subs/domain/subscriptions/subscription_participant.dart';

void main() {
  test('credit-card subscription requires a card', () {
    expect(
      () => Subscription(
        id: 'subscription-id',
        title: 'Music',
        categoryId: 'category-id',
        iconKey: 'music',
        standardAmount: Money(1990),
        paymentMethod: PaymentMethod.creditCard,
        payerPersonId: 'person-id',
        billingDay: 10,
        startDate: DateTime(2026),
        participants: const [
          SubscriptionParticipant(personId: 'person-id', shareWeight: 1),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('participant cannot be added twice', () {
    expect(
      () => Subscription(
        id: 'subscription-id',
        title: 'Music',
        categoryId: 'category-id',
        iconKey: 'music',
        standardAmount: Money(1990),
        paymentMethod: PaymentMethod.boleto,
        payerPersonId: 'person-id',
        billingDay: 10,
        startDate: DateTime(2026),
        participants: const [
          SubscriptionParticipant(personId: 'person-id', shareWeight: 1),
          SubscriptionParticipant(personId: 'person-id', shareWeight: 1),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('a zero weight is valid when another participant is positive', () {
    final subscription = Subscription(
      id: 'subscription-id',
      title: 'Music',
      categoryId: 'category-id',
      iconKey: 'music',
      standardAmount: Money(1990),
      paymentMethod: PaymentMethod.boleto,
      payerPersonId: 'person-id',
      billingDay: 10,
      startDate: DateTime(2026),
      participants: const [
        SubscriptionParticipant(personId: 'person-id', shareWeight: 0),
        SubscriptionParticipant(personId: 'other-id', shareWeight: 1),
      ],
    );

    expect(subscription.participants.first.shareWeight, 0);
  });

  test('all participant weights cannot be zero', () {
    expect(
      () => Subscription(
        id: 'subscription-id',
        title: 'Music',
        categoryId: 'category-id',
        iconKey: 'music',
        standardAmount: Money(1990),
        paymentMethod: PaymentMethod.boleto,
        payerPersonId: 'person-id',
        billingDay: 10,
        startDate: DateTime(2026),
        participants: const [
          SubscriptionParticipant(personId: 'person-id', shareWeight: 0),
        ],
      ),
      throwsArgumentError,
    );
  });
}
