import 'package:subs/domain/credit_cards/credit_card.dart';

final class CreateCreditCardCommand {
  const CreateCreditCardCommand({
    required this.name,
    required this.ownerPersonId,
    required this.closingDay,
    required this.dueDay,
  });

  final String name;
  final String ownerPersonId;
  final int closingDay;
  final int dueDay;
}

abstract interface class CreateCreditCard {
  Future<CreditCard> call(CreateCreditCardCommand command);
}
