import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subs/adapters/inbound/flutter/people/bloc/people_bloc.dart';
import 'package:subs/domain/people/person.dart';

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PeopleBloc, PeopleState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!))),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('People')),
          body: switch (state.status) {
            PeopleStatus.initial || PeopleStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            PeopleStatus.failure when state.people.isEmpty => _ErrorContent(
              message: state.errorMessage ?? 'Could not load people.',
            ),
            _ => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: state.people.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final person = state.people[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(person.name.characters.first.toUpperCase()),
                    ),
                    title: Text(person.name),
                    subtitle: person.isCurrentUser ? const Text('You') : null,
                    trailing: IconButton(
                      tooltip: 'Edit name',
                      onPressed: state.isSaving
                          ? null
                          : () => _editPerson(context, person),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                );
              },
            ),
          },
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isSaving ? null : () => _addPerson(context),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add person'),
          ),
        );
      },
    );
  }

  Future<void> _addPerson(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _PersonNameDialog(),
    );
    if (name != null && context.mounted) {
      context.read<PeopleBloc>().add(PersonCreationRequested(name));
    }
  }

  Future<void> _editPerson(BuildContext context, Person person) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _PersonNameDialog(initialName: person.name),
    );
    if (name != null && name != person.name && context.mounted) {
      context.read<PeopleBloc>().add(
        PersonRenameRequested(personId: person.id, name: name),
      );
    }
  }
}

class _PersonNameDialog extends StatefulWidget {
  const _PersonNameDialog({this.initialName});

  final String? initialName;

  @override
  State<_PersonNameDialog> createState() => _PersonNameDialogState();
}

class _PersonNameDialogState extends State<_PersonNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit name' : 'Add person'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter a name' : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
