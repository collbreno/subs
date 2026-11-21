import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subs/application/ports/inbound/create_category.dart';
import 'package:subs/application/ports/inbound/delete_category.dart';
import 'package:subs/application/ports/inbound/rename_category.dart';
import 'package:subs/application/ports/inbound/watch_categories.dart';
import 'package:subs/domain/categories/category.dart';

sealed class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

final class CategoriesStarted extends CategoriesEvent {
  const CategoriesStarted();
}

final class CategoryCreationRequested extends CategoriesEvent {
  const CategoryCreationRequested({required this.name, required this.iconKey});

  final String name;
  final String iconKey;

  @override
  List<Object?> get props => [name, iconKey];
}

final class CategoryRenameRequested extends CategoriesEvent {
  const CategoryRenameRequested({
    required this.categoryId,
    required this.name,
    required this.iconKey,
  });

  final String categoryId;
  final String name;
  final String iconKey;

  @override
  List<Object?> get props => [categoryId, name, iconKey];
}

final class CategoryDeletionRequested extends CategoriesEvent {
  const CategoryDeletionRequested(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

enum CategoriesStatus { initial, loading, success, failure }

final class CategoriesState extends Equatable {
  const CategoriesState({
    this.status = CategoriesStatus.initial,
    this.categories = const [],
    this.isSaving = false,
    this.errorMessage,
  });

  final CategoriesStatus status;
  final List<Category> categories;
  final bool isSaving;
  final String? errorMessage;

  CategoriesState copyWith({
    CategoriesStatus? status,
    List<Category>? categories,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => CategoriesState(
    status: status ?? this.status,
    categories: categories ?? this.categories,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, categories, isSaving, errorMessage];
}

final class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc(
    this._watchCategories,
    this._createCategory,
    this._renameCategory,
    this._deleteCategory,
  ) : super(const CategoriesState()) {
    on<CategoriesStarted>(_onStarted);
    on<CategoryCreationRequested>(_onCreate);
    on<CategoryRenameRequested>(_onRename);
    on<CategoryDeletionRequested>(_onDelete);
  }

  final WatchCategories _watchCategories;
  final CreateCategory _createCategory;
  final RenameCategory _renameCategory;
  final DeleteCategory _deleteCategory;

  Future<void> _onStarted(
    CategoriesStarted event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(const CategoriesState(status: CategoriesStatus.loading));
    await emit.forEach(
      _watchCategories(),
      onData: (categories) => CategoriesState(
        status: CategoriesStatus.success,
        categories: categories,
      ),
      onError: (error, stackTrace) => CategoriesState(
        status: CategoriesStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onCreate(
    CategoryCreationRequested event,
    Emitter<CategoriesState> emit,
  ) => _mutate(emit, () async {
    await _createCategory(
      CreateCategoryCommand(name: event.name, iconKey: event.iconKey),
    );
  });

  Future<void> _onRename(
    CategoryRenameRequested event,
    Emitter<CategoriesState> emit,
  ) => _mutate(emit, () async {
    await _renameCategory(
      RenameCategoryCommand(
        categoryId: event.categoryId,
        name: event.name,
        iconKey: event.iconKey,
      ),
    );
  });

  Future<void> _onDelete(
    CategoryDeletionRequested event,
    Emitter<CategoriesState> emit,
  ) => _mutate(emit, () => _deleteCategory(event.categoryId));

  Future<void> _mutate(
    Emitter<CategoriesState> emit,
    Future<void> Function() operation,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await operation();
      emit(state.copyWith(isSaving: false));
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }
}
