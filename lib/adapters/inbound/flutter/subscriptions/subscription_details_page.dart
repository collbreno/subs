import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subs/adapters/inbound/flutter/subscriptions/bloc/subscription_details_bloc.dart';
import 'package:subs/application/ports/inbound/watch_people.dart';
import 'package:subs/application/ports/inbound/watch_credit_cards_with_subscriptions.dart';
import 'package:subs/application/ports/inbound/update_subscription_info.dart';
import 'package:subs/domain/credit_cards/credit_card_with_subscriptions.dart';
import 'package:subs/domain/people/person.dart';
import 'package:subs/adapters/inbound/flutter/shared/category_icon_catalog.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';
import 'package:subs/domain/subscriptions/subscription_details.dart';

class SubscriptionDetailsPage extends StatelessWidget {
  const SubscriptionDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionDetailsBloc, SubscriptionDetailsState>(
      listenWhen: (previous, current) =>
          (!previous.isDeleted && current.isDeleted) ||
          (previous.errorMessage != current.errorMessage &&
              current.errorMessage != null),
      listener: (context, state) {
        if (state.isDeleted) {
          context.pop();
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Subscription details')),
        body: switch (state.status) {
          SubscriptionDetailsStatus.initial ||
          SubscriptionDetailsStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          SubscriptionDetailsStatus.notFound => const _Message(
            icon: Icons.search_off_outlined,
            text: 'Subscription not found.',
          ),
          SubscriptionDetailsStatus.failure => const _Message(
            icon: Icons.error_outline,
            text: 'Could not load this subscription.',
          ),
          SubscriptionDetailsStatus.success => _DetailsBody(
            details: state.details!,
            isDeleting: state.isDeleting,
            isUpdatingWeights: state.isUpdatingWeights,
            isUpdatingInfo: state.isUpdatingInfo,
            onEditInfo: () => _editInfo(context, state.details!),
            onChangeWeights: () => _changeWeights(context, state.details!),
            onDelete: () => _confirmDelete(context, state.details!),
          ),
        },
      ),
    );
  }

  Future<void> _editInfo(
    BuildContext context,
    SubscriptionDetails details,
  ) async {
    final watchPeople = context.read<WatchPeople>();
    final watchCards = context.read<WatchCreditCardsWithSubscriptions>();
    final people = await watchPeople().first;
    final cards = await watchCards(includeInactive: true).first;
    if (!context.mounted) return;
    final command = await showDialog<UpdateSubscriptionInfoCommand>(
      context: context,
      builder: (_) =>
          _EditInfoDialog(details: details, people: people, cards: cards),
    );
    if (command != null && context.mounted) {
      context.read<SubscriptionDetailsBloc>().add(
        SubscriptionInfoUpdateRequested(command),
      );
    }
  }

  Future<void> _changeWeights(
    BuildContext context,
    SubscriptionDetails details,
  ) async {
    final watchPeople = context.read<WatchPeople>();
    final people = await watchPeople().first;
    if (!context.mounted) return;
    final weights = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) =>
          _WeightsDialog(participants: details.participants, people: people),
    );
    if (weights != null && context.mounted) {
      context.read<SubscriptionDetailsBloc>().add(
        SubscriptionWeightsUpdateRequested(weights),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SubscriptionDetails details,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete subscription?'),
        content: Text(
          'Delete “${details.title}”? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<SubscriptionDetailsBloc>().add(
        const SubscriptionDetailsDeletionRequested(),
      );
    }
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.details,
    required this.isDeleting,
    required this.isUpdatingWeights,
    required this.isUpdatingInfo,
    required this.onEditInfo,
    required this.onChangeWeights,
    required this.onDelete,
  });

  final SubscriptionDetails details;
  final bool isDeleting;
  final bool isUpdatingWeights;
  final bool isUpdatingInfo;
  final VoidCallback onEditInfo;
  final VoidCallback onChangeWeights;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final paymentMethod = details.paymentMethod == PaymentMethod.boleto
        ? 'Boleto'
        : details.creditCardName ?? 'Credit card';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Icon(categoryIconData(details.iconKey), size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  details.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  details.categoryName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'Standard value',
                value: _money(details.standardAmount.cents),
              ),
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Your part',
                value: _money(details.currentUserShare.cents),
              ),
              _DetailRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Payment method',
                value: paymentMethod,
              ),
              _DetailRow(
                icon: Icons.person_pin_outlined,
                label: 'Paid by',
                value: details.payerName,
              ),
              _DetailRow(
                icon: Icons.event_outlined,
                label: 'Billing day',
                value: details.billingDay.toString(),
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Starts on',
                value: _date(details.startDate),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isUpdatingInfo ? null : onEditInfo,
                    icon: isUpdatingInfo
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_outlined),
                    label: Text(
                      isUpdatingInfo ? 'Saving details…' : 'Edit details',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Shared with', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: details.participants.indexed
                .map((entry) {
                  final (index, participant) = entry;
                  return _DetailRow(
                    icon: participant.isCurrentUser
                        ? Icons.person
                        : Icons.person_outline,
                    label:
                        '${participant.isCurrentUser ? '${participant.name} (you)' : participant.name}'
                        ' • ${participant.shareWeight} ${participant.shareWeight == 1 ? 'share' : 'shares'}',
                    value: _money(participant.shareAmount.cents),
                    showDivider: index != details.participants.length - 1,
                  );
                })
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: isUpdatingWeights ? null : onChangeWeights,
          icon: isUpdatingWeights
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.balance_outlined),
          label: Text(isUpdatingWeights ? 'Saving weights…' : 'Change weights'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: isDeleting ? null : onDelete,
          icon: isDeleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: Text(isDeleting ? 'Deleting…' : 'Delete subscription'),
        ),
      ],
    );
  }

  static String _money(int cents) =>
      'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _EditInfoDialog extends StatefulWidget {
  const _EditInfoDialog({
    required this.details,
    required this.people,
    required this.cards,
  });

  final SubscriptionDetails details;
  final List<Person> people;
  final List<CreditCardWithSubscriptions> cards;

  @override
  State<_EditInfoDialog> createState() => _EditInfoDialogState();
}

class _EditInfoDialogState extends State<_EditInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController = TextEditingController(
    text: (widget.details.standardAmount.cents / 100).toStringAsFixed(2),
  );
  late final TextEditingController _billingDayController =
      TextEditingController(text: widget.details.billingDay.toString());
  late PaymentMethod _paymentMethod = widget.details.paymentMethod;
  late String _payerId = widget.details.payerPersonId;
  late String? _cardId = widget.details.creditCardId;
  late DateTime _startDate = widget.details.startDate;

  @override
  void dispose() {
    _amountController.dispose();
    _billingDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit details'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Standard value',
                        prefixText: 'R\$ ',
                      ),
                      validator: _amount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _billingDayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Billing day',
                      ),
                      validator: _day,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Payment method',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(
                    value: PaymentMethod.boleto,
                    icon: Icon(Icons.barcode_reader),
                    label: Text('Boleto'),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.creditCard,
                    icon: Icon(Icons.credit_card),
                    label: Text('Card'),
                  ),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (selection) => setState(() {
                  _paymentMethod = selection.first;
                  _cardId ??= widget.cards.firstOrNull?.card.id;
                }),
              ),
              const SizedBox(height: 16),
              if (_paymentMethod == PaymentMethod.boleto)
                DropdownButtonFormField<String>(
                  initialValue: _payerId,
                  decoration: const InputDecoration(labelText: 'Paid by'),
                  items: widget.people
                      .map(
                        (person) => DropdownMenuItem(
                          value: person.id,
                          child: Text(person.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _payerId = value!),
                )
              else if (widget.cards.isEmpty)
                const Text('Create a credit card before using this method.')
              else
                DropdownButtonFormField<String>(
                  initialValue: _cardId,
                  decoration: const InputDecoration(labelText: 'Credit card'),
                  items: widget.cards
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.card.id,
                          child: Text('${item.card.name} • ${item.owner.name}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _cardId = value),
                  validator: (value) => value == null ? 'Select a card' : null,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Starts on ${_date(_startDate)}'),
                ),
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
      FilledButton(onPressed: _submit, child: const Text('Save')),
    ],
  );

  String? _amount(String? value) {
    final amount = double.tryParse((value ?? '').replaceAll(',', '.'));
    return amount == null || amount < 0 ? 'Enter a valid value' : null;
  }

  String? _day(String? value) {
    final day = int.tryParse(value ?? '');
    return day == null || day < 1 || day > 31 ? 'Use 1–31' : null;
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _startDate = date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentMethod == PaymentMethod.creditCard && _cardId == null) return;
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    Navigator.pop(
      context,
      UpdateSubscriptionInfoCommand(
        subscriptionId: widget.details.id,
        standardAmountCents: (amount * 100).round(),
        paymentMethod: _paymentMethod,
        creditCardId: _paymentMethod == PaymentMethod.creditCard
            ? _cardId
            : null,
        payerPersonId: _paymentMethod == PaymentMethod.boleto ? _payerId : null,
        billingDay: int.parse(_billingDayController.text),
        startDate: _startDate,
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _WeightsDialog extends StatefulWidget {
  const _WeightsDialog({required this.participants, required this.people});

  final List<SubscriptionParticipantDetails> participants;
  final List<Person> people;

  @override
  State<_WeightsDialog> createState() => _WeightsDialogState();
}

class _WeightsDialogState extends State<_WeightsDialog> {
  late final Map<String, int> _weights = {
    for (final participant in widget.participants)
      participant.personId: participant.shareWeight,
  };
  String? _errorMessage;

  Map<String, Person> get _peopleById => {
    for (final person in widget.people) person.id: person,
  };

  List<Person> get _selectedPeople {
    final peopleById = _peopleById;
    return _weights.keys
        .map(
          (id) =>
              peopleById[id] ??
              Person(
                id: id,
                name: widget.participants
                    .firstWhere((participant) => participant.personId == id)
                    .name,
                isCurrentUser: widget.participants
                    .firstWhere((participant) => participant.personId == id)
                    .isCurrentUser,
              ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Change weights'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weights divide the value proportionally. Your weight may be zero.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ..._selectedPeople.map(_participantRow),
            OutlinedButton.icon(
              onPressed: _availablePeople.isEmpty ? null : _addPerson,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add person'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );

  List<Person> get _availablePeople => widget.people
      .where((person) => !_weights.containsKey(person.id))
      .toList(growable: false);

  Widget _participantRow(Person person) {
    final weight = _weights[person.id]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                person.isCurrentUser ? '${person.name} (you)' : person.name,
              ),
            ),
            IconButton(
              tooltip: 'Decrease ${person.name} weight',
              onPressed: person.isCurrentUser && weight == 0
                  ? null
                  : () => setState(() {
                      if (!person.isCurrentUser && weight == 1) {
                        _weights.remove(person.id);
                      } else {
                        _weights[person.id] = weight - 1;
                      }
                      _errorMessage = null;
                    }),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Semantics(
              label: '${person.name} weight',
              value: weight.toString(),
              child: SizedBox(
                width: 28,
                child: Text(
                  weight.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Increase ${person.name} weight',
              onPressed: () => setState(() {
                _weights[person.id] = weight + 1;
                _errorMessage = null;
              }),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPerson() async {
    final person = await showDialog<Person>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Add person'),
        children: _availablePeople
            .map(
              (person) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, person),
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(person.name),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (person != null && mounted) {
      setState(() {
        _weights[person.id] = 1;
        _errorMessage = null;
      });
    }
  }

  void _save() {
    if (_weights.values.every((weight) => weight == 0)) {
      setState(() => _errorMessage = 'At least one weight must be positive.');
      return;
    }
    Navigator.pop(context, Map<String, int>.unmodifiable(_weights));
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ),
      if (showDivider) const Divider(height: 1, indent: 56),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 48), const SizedBox(height: 12), Text(text)],
    ),
  );
}
