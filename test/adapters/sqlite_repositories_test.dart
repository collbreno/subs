import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/database_changes.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/local_database.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/sqlite_category_repository.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/sqlite_credit_card_repository.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/sqlite_people_repository.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/sqlite_subscription_repository.dart';
import 'package:subs/domain/credit_cards/credit_card.dart';
import 'package:subs/domain/categories/category.dart';
import 'package:subs/domain/people/person.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';
import 'package:subs/domain/subscriptions/subscription.dart';
import 'package:subs/domain/subscriptions/subscription_participant.dart';

void main() {
  test('first-run repositories persist and project the core flow', () async {
    final raw = sqlite3.openInMemory();
    raw.execute(
      File('database/migrations/001_initial_schema.sql').readAsStringSync(),
    );
    raw.execute(
      File('database/migrations/002_allow_current_user_zero_weight.sql')
          .readAsStringSync(),
    );
    raw.execute(
      File('database/migrations/003_add_category_icons.sql').readAsStringSync(),
    );
    raw.execute('''
      INSERT INTO people (id, name, is_current_user)
      VALUES ('current-user', 'Me', 1);
      INSERT INTO categories (id, name, icon_key)
      VALUES ('utilities', 'Utilities', 'bolt');
    ''');

    final database = LocalDatabase.testing(raw);
    final changes = DatabaseChanges();
    final people = SqlitePeopleRepository(database, changes);
    final categories = SqliteCategoryRepository(database, changes);
    final cards = SqliteCreditCardRepository(database, changes);
    final subscriptions = SqliteSubscriptionRepository(database, changes);

    await people.create(const Person(id: 'alex', name: 'Alex'));
    await people.create(const Person(id: 'aaron', name: 'Aaron'));
    await people.updateName(personId: 'current-user', name: 'Breno');
    await categories.create(
      const Category(id: 'health', name: 'Health', iconKey: 'health'),
    );
    await categories.update(
      categoryId: 'health',
      name: 'Wellness',
      iconKey: 'fitness',
    );
    await cards.create(
      const CreditCard(
        id: 'card',
        name: 'Main card',
        ownerPersonId: 'current-user',
        closingDay: 20,
        dueDay: 28,
      ),
    );
    await subscriptions.create(
      Subscription(
        id: 'electricity',
        title: 'Electricity',
        categoryId: 'utilities',
        iconKey: 'utilities',
        standardAmount: Money(15000),
        paymentMethod: PaymentMethod.creditCard,
        creditCardId: 'card',
        payerPersonId: 'current-user',
        billingDay: 10,
        startDate: DateTime(2026),
        participants: const [
          SubscriptionParticipant(personId: 'current-user', shareWeight: 1),
          SubscriptionParticipant(personId: 'alex', shareWeight: 1),
        ],
      ),
    );
    await subscriptions.updateWeights(
      subscriptionId: 'electricity',
      weights: const {'current-user': 0, 'alex': 1},
    );
    await subscriptions.updateInfo(
      subscriptionId: 'electricity',
      standardAmountCents: 18000,
      paymentMethod: PaymentMethod.creditCard,
      creditCardId: 'card',
      payerPersonId: 'current-user',
      billingDay: 15,
      startDate: DateTime(2026, 2),
    );

    final current = await subscriptions.watchCurrent(DateTime(2026, 11)).first;
    final details = await subscriptions.findDetailsById('electricity');
    final grouped = await cards.watchWithSubscriptions().first;
    final allPeople = await people.watchAll().first;
    final allCategories = await categories.watchAll().first;

    expect(current, hasLength(1));
    expect(current.single.currentUserShare.cents, 0);
    expect(details?.title, 'Electricity');
    expect(details?.billingDay, 15);
    expect(details?.standardAmount.cents, 18000);
    expect(details?.startDate, DateTime(2026, 2));
    expect(details?.participants, hasLength(2));
    expect(details?.currentUserShare.cents, 0);
    expect(details?.participants.first.shareWeight, 0);
    expect(grouped, hasLength(1));
    expect(grouped.single.subscriptions.single.title, 'Electricity');
    expect(allPeople.first.name, 'Breno');
    expect(allPeople.first.isCurrentUser, isTrue);
    expect(
      allCategories,
      contains(
        const Category(id: 'health', name: 'Wellness', iconKey: 'fitness'),
      ),
    );
    await subscriptions.updateWeights(
      subscriptionId: 'electricity',
      weights: const {'current-user': 0, 'aaron': 2},
    );
    final changedDivision = await subscriptions.findDetailsById('electricity');
    expect(
      changedDivision?.participants.map((participant) => participant.personId),
      containsAll(<String>['current-user', 'aaron']),
    );
    expect(
      changedDivision?.participants.map((participant) => participant.personId),
      isNot(contains('alex')),
    );
    await expectLater(
      categories.delete('utilities'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      subscriptions.updateWeights(
        subscriptionId: 'electricity',
        weights: const {'current-user': 1, 'alex': 0},
      ),
      throwsA(isA<SqliteException>()),
    );
    await subscriptions.delete('electricity');
    expect(await subscriptions.watchCurrent(DateTime(2026, 11)).first, isEmpty);
    expect(await subscriptions.findDetailsById('electricity'), isNull);
    expect(
      raw
          .select(
            "SELECT COUNT(*) AS count FROM subscription_participants WHERE subscription_id = 'electricity'",
          )
          .first['count'],
      0,
    );
    await categories.delete('health');
    expect(await categories.watchAll().first, hasLength(1));

    await changes.close();
    database.close();
  });
}
