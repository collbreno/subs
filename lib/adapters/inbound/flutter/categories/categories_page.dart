import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subs/adapters/inbound/flutter/categories/bloc/categories_bloc.dart';
import 'package:subs/adapters/inbound/flutter/shared/category_icon_catalog.dart';
import 'package:subs/domain/categories/category.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoriesBloc, CategoriesState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!))),
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        body: switch (state.status) {
          CategoriesStatus.initial || CategoriesStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          _ => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: state.categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(categoryIconData(category.iconKey)),
                  ),
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit category',
                        onPressed: state.isSaving
                            ? null
                            : () => _edit(context, category),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete category',
                        onPressed: state.isSaving
                            ? null
                            : () => _delete(context, category),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        },
        floatingActionButton: FloatingActionButton.extended(
          onPressed: state.isSaving ? null : () => _create(context),
          icon: const Icon(Icons.add),
          label: const Text('Add category'),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (_) => const _CategoryDialog(),
    );
    if (result != null && context.mounted) {
      context.read<CategoriesBloc>().add(
        CategoryCreationRequested(name: result.name, iconKey: result.iconKey),
      );
    }
  }

  Future<void> _edit(BuildContext context, Category category) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (_) => _CategoryDialog(
        initialName: category.name,
        initialIconKey: category.iconKey,
      ),
    );
    if (result != null &&
        (result.name != category.name || result.iconKey != category.iconKey) &&
        context.mounted) {
      context.read<CategoriesBloc>().add(
        CategoryRenameRequested(
          categoryId: category.id,
          name: result.name,
          iconKey: result.iconKey,
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete “${category.name}”? Categories used by subscriptions cannot be deleted.',
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
      context.read<CategoriesBloc>().add(
        CategoryDeletionRequested(category.id),
      );
    }
  }
}

typedef _CategoryFormResult = ({String name, String iconKey});

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.initialName, this.initialIconKey = 'category'});

  final String? initialName;
  final String initialIconKey;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late String _iconKey = widget.initialIconKey;

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
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_isEditing ? 'Edit category' : 'Add category'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 20),
              Text('Icon', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 72,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: categoryIconOptions.length,
                itemBuilder: (context, index) {
                  final option = categoryIconOptions[index];
                  final selected = option.key == _iconKey;
                  return Tooltip(
                    message: option.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _iconKey = option.key),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Icon(option.icon),
                      ),
                    ),
                  );
                },
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
      FilledButton(
        onPressed: _submit,
        child: Text(_isEditing ? 'Save' : 'Add'),
      ),
    ],
  );

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, (
        name: _controller.text.trim(),
        iconKey: _iconKey,
      ));
    }
  }
}
