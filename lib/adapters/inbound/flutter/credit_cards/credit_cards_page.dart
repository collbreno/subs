import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subs/adapters/inbound/flutter/credit_cards/bloc/credit_cards_bloc.dart';
import 'package:subs/adapters/inbound/flutter/shared/empty_content.dart';
import 'package:subs/adapters/inbound/flutter/shared/category_icon_catalog.dart';
import 'package:subs/application/ports/inbound/create_credit_card.dart';
import 'package:subs/application/ports/inbound/watch_people.dart';
import 'package:subs/domain/people/person.dart';

class CreditCardsPage extends StatelessWidget {
  const CreditCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreditCardsBloc, CreditCardsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!))),
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Credit cards')),
        body: switch (state.status) {
          CreditCardsStatus.initial || CreditCardsStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          _ when state.cards.isEmpty => EmptyContent(
            icon: Icons.credit_card_outlined,
            title: 'No credit cards yet',
            message:
                'Add a card to group subscriptions by their real due date.',
            actionLabel: 'Add credit card',
            onAction: () => _addCard(context),
          ),
          _ => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: state.cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = state.cards[index];
              return Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.credit_card),
                  title: Text(item.card.name),
                  subtitle: Text(
                    '${item.owner.name} • closes ${item.card.closingDay} • due ${item.card.dueDay}',
                  ),
                  children: item.subscriptions.isEmpty
                      ? const [
                          ListTile(
                            title: Text('No subscriptions on this card'),
                          ),
                        ]
                      : item.subscriptions
                            .map(
                              (subscription) => ListTile(
                                leading: Icon(
                                  categoryIconData(subscription.iconKey),
                                ),
                                title: Text(subscription.title),
                                subtitle: Text(subscription.categoryName),
                                trailing: Text(
                                  _money(subscription.standardAmount.cents),
                                ),
                              ),
                            )
                            .toList(growable: false),
                ),
              );
            },
          ),
        },
        floatingActionButton: state.cards.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: state.isSaving ? null : () => _addCard(context),
                icon: const Icon(Icons.add_card),
                label: const Text('Add card'),
              ),
      ),
    );
  }

  Future<void> _addCard(BuildContext context) async {
    final people = await context.read<WatchPeople>()().first;
    if (!context.mounted) return;
    final command = await showDialog<CreateCreditCardCommand>(
      context: context,
      builder: (_) => _CreateCreditCardDialog(people: people),
    );
    if (command != null && context.mounted) {
      context.read<CreditCardsBloc>().add(CreditCardCreationRequested(command));
    }
  }

  static String _money(int cents) =>
      'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
}

class _CreateCreditCardDialog extends StatefulWidget {
  const _CreateCreditCardDialog({required this.people});

  final List<Person> people;

  @override
  State<_CreateCreditCardDialog> createState() =>
      _CreateCreditCardDialogState();
}

class _CreateCreditCardDialogState extends State<_CreateCreditCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _closingDayController = TextEditingController(text: '20');
  final _dueDayController = TextEditingController(text: '28');
  late String _ownerId = widget.people.first.id;

  @override
  void dispose() {
    _nameController.dispose();
    _closingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add credit card'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Card name'),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _ownerId,
                  decoration: const InputDecoration(labelText: 'Card owner'),
                  items: widget.people
                      .map(
                        (person) => DropdownMenuItem(
                          value: person.id,
                          child: Text(person.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _ownerId = value!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _closingDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Closing day',
                        ),
                        validator: _day,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dueDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Due day'),
                        validator: _day,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _day(String? value) {
    final day = int.tryParse(value ?? '');
    return day == null || day < 1 || day > 31 ? 'Use 1–31' : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CreateCreditCardCommand(
        name: _nameController.text.trim(),
        ownerPersonId: _ownerId,
        closingDay: int.parse(_closingDayController.text),
        dueDay: int.parse(_dueDayController.text),
      ),
    );
  }
}
