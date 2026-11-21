import 'package:subs/application/ports/inbound/create_credit_card.dart';
import 'package:subs/application/ports/outbound/credit_card_repository.dart';
import 'package:subs/application/ports/outbound/id_generator.dart';
import 'package:subs/application/ports/outbound/people_repository.dart';
import 'package:subs/domain/credit_cards/credit_card.dart';

final class CreateCreditCardService implements CreateCreditCard {
  const CreateCreditCardService(this._cards, this._people, this._ids);

  final CreditCardRepository _cards;
  final PeopleRepository _people;
  final IdGenerator _ids;

  @override
  Future<CreditCard> call(CreateCreditCardCommand command) async {
    final name = command.name.trim();
    if (name.isEmpty) throw ArgumentError('Name must not be blank');
    _validateDay(command.closingDay, 'closingDay');
    _validateDay(command.dueDay, 'dueDay');
    if (!await _people.exists(command.ownerPersonId)) {
      throw ArgumentError('The card owner does not exist');
    }

    return _cards.create(
      CreditCard(
        id: _ids.next(),
        name: name,
        ownerPersonId: command.ownerPersonId,
        closingDay: command.closingDay,
        dueDay: command.dueDay,
      ),
    );
  }

  void _validateDay(int day, String field) {
    if (day < 1 || day > 31) {
      throw ArgumentError.value(day, field, 'Must be between 1 and 31');
    }
  }
}
