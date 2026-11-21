import 'package:subs/adapters/outbound/persistence/sqlite/database_changes.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/local_database.dart';
import 'package:subs/application/ports/outbound/subscription_repository.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';
import 'package:subs/domain/subscriptions/subscription.dart';
import 'package:subs/domain/subscriptions/subscription_details.dart';
import 'package:subs/domain/subscriptions/subscription_summary.dart';

final class SqliteSubscriptionRepository implements SubscriptionRepository {
  const SqliteSubscriptionRepository(this._database, this._changes);

  final LocalDatabase _database;
  final DatabaseChanges _changes;

  @override
  Future<Subscription> create(Subscription subscription) async {
    final database = _database.raw;
    database.execute('BEGIN IMMEDIATE');
    try {
      database.execute(
        '''
        INSERT INTO subscriptions (
          id, title, category_id, icon_key, standard_amount_cents,
          payment_method, credit_card_id, default_payer_person_id,
          billing_day, start_date, end_date, is_active
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          subscription.id,
          subscription.title,
          subscription.categoryId,
          subscription.iconKey,
          subscription.standardAmount.cents,
          subscription.paymentMethod == PaymentMethod.boleto
              ? 'boleto'
              : 'credit_card',
          subscription.creditCardId,
          subscription.payerPersonId,
          subscription.billingDay,
          _date(subscription.startDate),
          subscription.endDate == null ? null : _date(subscription.endDate!),
          subscription.isActive ? 1 : 0,
        ],
      );
      for (final participant in subscription.participants) {
        database.execute(
          '''
          INSERT INTO subscription_participants
            (subscription_id, person_id, share_weight)
          VALUES (?, ?, ?)
          ''',
          [subscription.id, participant.personId, participant.shareWeight],
        );
      }
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
    _changes.notify();
    return subscription;
  }

  @override
  Future<void> delete(String subscriptionId) async {
    final database = _database.raw;
    final exists = database.select('SELECT 1 FROM subscriptions WHERE id = ?', [
      subscriptionId,
    ]);
    if (exists.isEmpty) throw StateError('Subscription not found.');

    database.execute('BEGIN IMMEDIATE');
    try {
      database.execute(
        'DELETE FROM subscription_participants WHERE subscription_id = ?',
        [subscriptionId],
      );
      database.execute('DELETE FROM subscriptions WHERE id = ?', [
        subscriptionId,
      ]);
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
    _changes.notify();
  }

  @override
  Future<SubscriptionDetails?> findDetailsById(String subscriptionId) async {
    final rows = _database.raw.select(
      '''
      SELECT
        subscription.id,
        subscription.title,
        category.icon_key,
        subscription.standard_amount_cents,
        subscription.payment_method,
        subscription.credit_card_id,
        subscription.default_payer_person_id,
        subscription.billing_day,
        subscription.start_date,
        category.name AS category_name,
        payer.name AS payer_name,
        card.name AS card_name
      FROM subscriptions subscription
      JOIN categories category ON category.id = subscription.category_id
      JOIN people payer ON payer.id = subscription.default_payer_person_id
      LEFT JOIN credit_cards card ON card.id = subscription.credit_card_id
      WHERE subscription.id = ?
      ''',
      [subscriptionId],
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final amount = row['standard_amount_cents'] as int;
    final participantRows = _database.raw.select(
      '''
      SELECT
        person.id,
        person.name,
        person.is_current_user,
        participant.share_weight
      FROM subscription_participants participant
      JOIN people person ON person.id = participant.person_id
      WHERE participant.subscription_id = ?
      ORDER BY person.is_current_user DESC, person.name COLLATE NOCASE
      ''',
      [subscriptionId],
    );
    final totalWeight = participantRows.fold<int>(
      0,
      (total, participant) => total + participant['share_weight'] as int,
    );
    final participants = participantRows
        .map((participant) {
          final weight = participant['share_weight'] as int;
          return SubscriptionParticipantDetails(
            personId: participant['id'] as String,
            name: participant['name'] as String,
            isCurrentUser: participant['is_current_user'] == 1,
            shareWeight: weight,
            shareAmount: Money(
              totalWeight == 0 ? 0 : amount * weight ~/ totalWeight,
            ),
          );
        })
        .toList(growable: false);
    final currentUserShare = participants
        .where((participant) => participant.isCurrentUser)
        .map((participant) => participant.shareAmount)
        .firstOrNull;

    return SubscriptionDetails(
      id: row['id'] as String,
      title: row['title'] as String,
      categoryName: row['category_name'] as String,
      iconKey: row['icon_key'] as String,
      standardAmount: Money(amount),
      currentUserShare: currentUserShare ?? Money(0),
      paymentMethod: row['payment_method'] == 'boleto'
          ? PaymentMethod.boleto
          : PaymentMethod.creditCard,
      payerPersonId: row['default_payer_person_id'] as String,
      payerName: row['payer_name'] as String,
      billingDay: row['billing_day'] as int,
      startDate: DateTime.parse(row['start_date'] as String),
      participants: participants,
      creditCardName: row['card_name'] as String?,
      creditCardId: row['credit_card_id'] as String?,
    );
  }

  @override
  Future<void> updateInfo({
    required String subscriptionId,
    required int standardAmountCents,
    required PaymentMethod paymentMethod,
    required String? creditCardId,
    required String payerPersonId,
    required int billingDay,
    required DateTime startDate,
  }) async {
    _database.raw.execute(
      '''
      UPDATE subscriptions
      SET standard_amount_cents = ?,
          payment_method = ?,
          credit_card_id = ?,
          default_payer_person_id = ?,
          billing_day = ?,
          start_date = ?,
          updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
      WHERE id = ?
      ''',
      [
        standardAmountCents,
        paymentMethod == PaymentMethod.boleto ? 'boleto' : 'credit_card',
        creditCardId,
        payerPersonId,
        billingDay,
        _date(startDate),
        subscriptionId,
      ],
    );
    if (_database.raw.updatedRows == 0) {
      throw StateError('Subscription not found.');
    }
    _changes.notify();
  }

  @override
  Future<void> updateWeights({
    required String subscriptionId,
    required Map<String, int> weights,
  }) async {
    final database = _database.raw;
    final exists = database.select('SELECT 1 FROM subscriptions WHERE id = ?', [
      subscriptionId,
    ]);
    if (exists.isEmpty) throw StateError('Subscription not found.');

    database.execute('BEGIN IMMEDIATE');
    try {
      database.execute(
        'DELETE FROM subscription_participants WHERE subscription_id = ?',
        [subscriptionId],
      );
      for (final entry in weights.entries) {
        database.execute(
          '''
          INSERT INTO subscription_participants
            (subscription_id, person_id, share_weight)
          VALUES (?, ?, ?)
          ''',
          [subscriptionId, entry.key, entry.value],
        );
      }
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
    _changes.notify();
  }

  @override
  Stream<List<SubscriptionSummary>> watchCurrent(DateTime referenceDate) =>
      _changes.watch(() => _loadCurrent(referenceDate));

  List<SubscriptionSummary> _loadCurrent(DateTime referenceDate) {
    final date = _date(referenceDate);
    final rows = _database.raw.select(
      '''
      SELECT
        subscription.id,
        subscription.title,
        category.icon_key,
        subscription.standard_amount_cents,
        subscription.payment_method,
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
      LEFT JOIN credit_cards card ON card.id = subscription.credit_card_id
      WHERE subscription.is_active = 1
        AND date(subscription.start_date) <= date(?)
        AND (subscription.end_date IS NULL OR date(subscription.end_date) >= date(?))
      ORDER BY subscription.title
    ''',
      [date, date],
    );

    return rows
        .map((row) {
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
            paymentMethod: row['payment_method'] == 'boleto'
                ? PaymentMethod.boleto
                : PaymentMethod.creditCard,
            payerName: row['payer_name'] as String,
            participantCount: row['participant_count'] as int,
            creditCardName: row['card_name'] as String?,
          );
        })
        .toList(growable: false);
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
