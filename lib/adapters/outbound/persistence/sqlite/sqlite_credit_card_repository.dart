import 'package:subs/adapters/outbound/persistence/sqlite/database_changes.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/local_database.dart';
import 'package:subs/application/ports/outbound/credit_card_repository.dart';
import 'package:subs/domain/credit_cards/credit_card.dart';
import 'package:subs/domain/credit_cards/credit_card_with_subscriptions.dart';
import 'package:subs/domain/people/person.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';
import 'package:subs/domain/subscriptions/subscription_summary.dart';

final class SqliteCreditCardRepository implements CreditCardRepository {
  const SqliteCreditCardRepository(this._database, this._changes);

  final LocalDatabase _database;
  final DatabaseChanges _changes;

  @override
  Future<CreditCard> create(CreditCard card) async {
    _database.raw.execute(
      '''
      INSERT INTO credit_cards
        (id, name, owner_person_id, closing_day, due_day, is_active)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        card.id,
        card.name,
        card.ownerPersonId,
        card.closingDay,
        card.dueDay,
        card.isActive ? 1 : 0,
      ],
    );
    _changes.notify();
    return card;
  }

  @override
  Future<CreditCard?> findById(String cardId) async {
    final rows = _database.raw.select(
      '''
      SELECT id, name, owner_person_id, closing_day, due_day, is_active
      FROM credit_cards WHERE id = ?
      ''',
      [cardId],
    );
    return rows.isEmpty ? null : _mapCard(rows.first);
  }

  @override
  Stream<List<CreditCardWithSubscriptions>> watchWithSubscriptions({
    bool includeInactive = false,
  }) => _changes.watch(() => _loadWithSubscriptions(includeInactive));

  List<CreditCardWithSubscriptions> _loadWithSubscriptions(
    bool includeInactive,
  ) {
    final rows = _database.raw.select(
      '''
      SELECT
        card.id,
        card.name,
        card.owner_person_id,
        card.closing_day,
        card.due_day,
        card.is_active,
        owner.name AS owner_name,
        owner.is_current_user AS owner_is_current_user
      FROM credit_cards card
      JOIN people owner ON owner.id = card.owner_person_id
      WHERE (? = 1 OR card.is_active = 1)
      ORDER BY owner.name, card.name
    ''',
      [includeInactive ? 1 : 0],
    );

    return rows
        .map((row) {
          final card = _mapCard(row);
          return CreditCardWithSubscriptions(
            card: card,
            owner: Person(
              id: card.ownerPersonId,
              name: row['owner_name'] as String,
              isCurrentUser: row['owner_is_current_user'] == 1,
            ),
            subscriptions: _loadSubscriptions(card.id),
          );
        })
        .toList(growable: false);
  }

  List<SubscriptionSummary> _loadSubscriptions(String cardId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = _database.raw.select(
      '''
      SELECT
        subscription.id,
        subscription.title,
        category.icon_key,
        subscription.standard_amount_cents,
        category.name AS category_name,
        payer.name AS payer_name,
        card.name AS card_name,
        (SELECT COUNT(*) FROM subscription_participants participant
         WHERE participant.subscription_id = subscription.id) AS participant_count,
        (SELECT share_weight FROM subscription_participants participant
         JOIN people person ON person.id = participant.person_id
         WHERE participant.subscription_id = subscription.id
           AND person.is_current_user = 1) AS my_weight,
        (SELECT SUM(share_weight) FROM subscription_participants participant
         WHERE participant.subscription_id = subscription.id) AS total_weight
      FROM subscriptions subscription
      JOIN categories category ON category.id = subscription.category_id
      JOIN people payer ON payer.id = subscription.default_payer_person_id
      JOIN credit_cards card ON card.id = subscription.credit_card_id
      WHERE subscription.credit_card_id = ?
        AND subscription.is_active = 1
        AND date(subscription.start_date) <= date(?)
        AND (subscription.end_date IS NULL OR date(subscription.end_date) >= date(?))
      ORDER BY subscription.title
    ''',
      [cardId, today, today],
    );

    return rows.map(_mapSubscriptionSummary).toList(growable: false);
  }

  CreditCard _mapCard(dynamic row) => CreditCard(
    id: row['id'] as String,
    name: row['name'] as String,
    ownerPersonId: row['owner_person_id'] as String,
    closingDay: row['closing_day'] as int,
    dueDay: row['due_day'] as int,
    isActive: row['is_active'] == 1,
  );

  SubscriptionSummary _mapSubscriptionSummary(dynamic row) {
    final amount = row['standard_amount_cents'] as int;
    final myWeight = (row['my_weight'] as int?) ?? 0;
    final totalWeight = (row['total_weight'] as int?) ?? 0;
    return SubscriptionSummary(
      id: row['id'] as String,
      title: row['title'] as String,
      categoryName: row['category_name'] as String,
      iconKey: row['icon_key'] as String,
      standardAmount: Money(amount),
      currentUserShare: Money(
        totalWeight == 0 ? 0 : amount * myWeight ~/ totalWeight,
      ),
      paymentMethod: PaymentMethod.creditCard,
      payerName: row['payer_name'] as String,
      participantCount: row['participant_count'] as int,
      creditCardName: row['card_name'] as String,
    );
  }
}
