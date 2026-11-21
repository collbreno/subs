import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subs/adapters/inbound/flutter/shared/empty_content.dart';
import 'package:subs/adapters/inbound/flutter/shared/category_icon_catalog.dart';
import 'package:subs/adapters/inbound/flutter/subscriptions/bloc/subscriptions_bloc.dart';
import 'package:subs/application/ports/inbound/create_subscription.dart';
import 'package:subs/application/ports/inbound/watch_categories.dart';
import 'package:subs/application/ports/inbound/watch_credit_cards_with_subscriptions.dart';
import 'package:subs/application/ports/inbound/watch_people.dart';
import 'package:subs/domain/categories/category.dart';
import 'package:subs/domain/credit_cards/credit_card_with_subscriptions.dart';
import 'package:subs/domain/people/person.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  static String money(int cents) =>
      'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

enum _SubscriptionsView { list, grid }

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  _SubscriptionsView _view = _SubscriptionsView.list;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionsBloc, SubscriptionsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!))),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Subscriptions'),
          actions: [
            IconButton(
              tooltip: _view == _SubscriptionsView.list
                  ? 'Grid view'
                  : 'List view',
              onPressed: state.subscriptions.isEmpty
                  ? null
                  : () => setState(() {
                      _view = _view == _SubscriptionsView.list
                          ? _SubscriptionsView.grid
                          : _SubscriptionsView.list;
                    }),
              icon: Icon(
                _view == _SubscriptionsView.list
                    ? Icons.grid_view_outlined
                    : Icons.view_list_outlined,
              ),
            ),
          ],
        ),
        body: switch (state.status) {
          SubscriptionsStatus.initial || SubscriptionsStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          _ when state.subscriptions.isEmpty => EmptyContent(
            icon: Icons.receipt_long_outlined,
            title: 'No subscriptions yet',
            message: 'Add a subscription to start tracking recurring payments.',
            actionLabel: 'Add subscription',
            onAction: () => _addSubscription(context),
          ),
          _ =>
            _view == _SubscriptionsView.list
                ? _buildList(context, state)
                : _buildGrid(context, state),
        },
        floatingActionButton: state.subscriptions.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: state.isSaving
                    ? null
                    : () => _addSubscription(context),
                icon: const Icon(Icons.add),
                label: const Text('Add subscription'),
              ),
        bottomNavigationBar: state.subscriptions.isEmpty
            ? null
            : _SubscriptionTotalsFooter(
                totalCents: state.subscriptions.fold(
                  0,
                  (total, subscription) =>
                      total + subscription.standardAmount.cents,
                ),
                currentUserTotalCents: state.subscriptions.fold(
                  0,
                  (total, subscription) =>
                      total + subscription.currentUserShare.cents,
                ),
              ),
      ),
    );
  }

  Widget _buildList(BuildContext context, SubscriptionsState state) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: state.subscriptions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final subscription = state.subscriptions[index];
        final method = subscription.paymentMethod == PaymentMethod.boleto
            ? 'Boleto'
            : subscription.creditCardName ?? 'Credit card';
        return Card(
          child: ListTile(
            onTap: () => context.push('/subscriptions/${subscription.id}'),
            leading: CircleAvatar(
              child: Icon(categoryIconData(subscription.iconKey)),
            ),
            title: Text(subscription.title),
            subtitle: Text(
              '${subscription.categoryName} • $method\n'
              'Your part: ${SubscriptionsPage.money(subscription.currentUserShare.cents)}',
            ),
            isThreeLine: true,
            trailing: Text(
              SubscriptionsPage.money(subscription.standardAmount.cents),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, SubscriptionsState state) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.55,
      ),
      itemCount: state.subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = state.subscriptions[index];
        return Card(
          child: InkWell(
            onTap: () => context.push('/subscriptions/${subscription.id}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          child: Icon(
                            categoryIconData(subscription.iconKey),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subscription.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          SubscriptionsPage.money(
                            subscription.standardAmount.cents,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          SubscriptionsPage.money(
                            subscription.currentUserShare.cents,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addSubscription(BuildContext context) async {
    final watchPeople = context.read<WatchPeople>();
    final watchCards = context.read<WatchCreditCardsWithSubscriptions>();
    final watchCategories = context.read<WatchCategories>();
    final people = await watchPeople().first;
    final cards = await watchCards().first;
    final categories = await watchCategories().first;
    if (!context.mounted) return;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Create a category first.')));
      return;
    }
    final command = await showDialog<CreateSubscriptionCommand>(
      context: context,
      builder: (_) => _CreateSubscriptionDialog(
        people: people,
        cards: cards,
        categories: categories,
      ),
    );
    if (command != null && context.mounted) {
      context.read<SubscriptionsBloc>().add(
        SubscriptionCreationRequested(command),
      );
    }
  }
}

class _SubscriptionTotalsFooter extends StatelessWidget {
  const _SubscriptionTotalsFooter({
    required this.totalCents,
    required this.currentUserTotalCents,
  });

  final int totalCents;
  final int currentUserTotalCents;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainer,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _TotalValue(label: 'Total', cents: totalCents),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: _TotalValue(
              label: 'My total part',
              cents: currentUserTotalCents,
              alignEnd: true,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TotalValue extends StatelessWidget {
  const _TotalValue({
    required this.label,
    required this.cents,
    this.alignEnd = false,
  });

  final String label;
  final int cents;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 2),
      Text(
        SubscriptionsPage.money(cents),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _CreateSubscriptionDialog extends StatefulWidget {
  const _CreateSubscriptionDialog({
    required this.people,
    required this.cards,
    required this.categories,
  });

  final List<Person> people;
  final List<CreditCardWithSubscriptions> cards;
  final List<Category> categories;

  @override
  State<_CreateSubscriptionDialog> createState() =>
      _CreateSubscriptionDialogState();
}

class _CreateSubscriptionDialogState extends State<_CreateSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _billingDayController = TextEditingController(
    text: DateTime.now().day.toString(),
  );
  PaymentMethod _paymentMethod = PaymentMethod.boleto;
  late String _categoryId = widget.categories.first.id;
  late String _payerId = widget.people.first.id;
  String? _cardId;
  late final Set<String> _participantIds = {
    widget.people.firstWhere((person) => person.isCurrentUser).id,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _billingDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add subscription'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _categoryId = value!),
                ),
                const SizedBox(height: 16),
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
                    items: _personItems(),
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
                            child: Text(
                              '${item.card.name} • ${item.owner.name}',
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setState(() => _cardId = value),
                    validator: (value) =>
                        value == null ? 'Select a card' : null,
                  ),
                const SizedBox(height: 20),
                Text(
                  'Shared with',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: widget.people
                      .map((person) {
                        final selected = _participantIds.contains(person.id);
                        return FilterChip(
                          selected: selected,
                          label: Text(
                            person.isCurrentUser
                                ? '${person.name} (you)'
                                : person.name,
                          ),
                          onSelected: person.isCurrentUser
                              ? null
                              : (value) => setState(() {
                                  if (value) {
                                    _participantIds.add(person.id);
                                  } else {
                                    _participantIds.remove(person.id);
                                  }
                                }),
                        );
                      })
                      .toList(growable: false),
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

  List<DropdownMenuItem<String>> _personItems() => widget.people
      .map(
        (person) =>
            DropdownMenuItem(value: person.id, child: Text(person.name)),
      )
      .toList(growable: false);

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _amount(String? value) {
    final amount = double.tryParse((value ?? '').replaceAll(',', '.'));
    return amount == null || amount < 0 ? 'Enter a valid value' : null;
  }

  String? _day(String? value) {
    final day = int.tryParse(value ?? '');
    return day == null || day < 1 || day > 31 ? 'Use 1–31' : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentMethod == PaymentMethod.creditCard && _cardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create or select a credit card first.')),
      );
      return;
    }
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    Navigator.pop(
      context,
      CreateSubscriptionCommand(
        title: _titleController.text.trim(),
        categoryId: _categoryId,
        iconKey: widget.categories
            .firstWhere((category) => category.id == _categoryId)
            .iconKey,
        standardAmountCents: (amount * 100).round(),
        paymentMethod: _paymentMethod,
        creditCardId: _paymentMethod == PaymentMethod.creditCard
            ? _cardId
            : null,
        payerPersonId: _paymentMethod == PaymentMethod.boleto ? _payerId : null,
        billingDay: int.parse(_billingDayController.text),
        startDate: DateTime.now(),
        participants: _participantIds
            .map((id) => ParticipantInput(personId: id, shareWeight: 1))
            .toList(growable: false),
      ),
    );
  }
}
