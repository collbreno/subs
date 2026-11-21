import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subs/application/ports/inbound/create_person.dart';
import 'package:subs/application/ports/inbound/rename_person.dart';
import 'package:subs/application/ports/inbound/watch_people.dart';
import 'package:subs/domain/people/person.dart';

sealed class PeopleEvent extends Equatable {
  const PeopleEvent();

  @override
  List<Object?> get props => [];
}

final class PeopleStarted extends PeopleEvent {
  const PeopleStarted();
}

final class PersonCreationRequested extends PeopleEvent {
  const PersonCreationRequested(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class PersonRenameRequested extends PeopleEvent {
  const PersonRenameRequested({required this.personId, required this.name});

  final String personId;
  final String name;

  @override
  List<Object?> get props => [personId, name];
}

enum PeopleStatus { initial, loading, success, failure }

final class PeopleState extends Equatable {
  const PeopleState({
    this.status = PeopleStatus.initial,
    this.people = const [],
    this.isSaving = false,
    this.errorMessage,
  });

  final PeopleStatus status;
  final List<Person> people;
  final bool isSaving;
  final String? errorMessage;

  PeopleState copyWith({
    PeopleStatus? status,
    List<Person>? people,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => PeopleState(
    status: status ?? this.status,
    people: people ?? this.people,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, people, isSaving, errorMessage];
}

final class PeopleBloc extends Bloc<PeopleEvent, PeopleState> {
  PeopleBloc(this._watchPeople, this._createPerson, this._renamePerson)
    : super(const PeopleState()) {
    on<PeopleStarted>(_onStarted);
    on<PersonCreationRequested>(_onCreationRequested);
    on<PersonRenameRequested>(_onRenameRequested);
  }

  final WatchPeople _watchPeople;
  final CreatePerson _createPerson;
  final RenamePerson _renamePerson;

  Future<void> _onStarted(
    PeopleStarted event,
    Emitter<PeopleState> emit,
  ) async {
    emit(const PeopleState(status: PeopleStatus.loading));
    await emit.forEach(
      _watchPeople(),
      onData: (people) =>
          PeopleState(status: PeopleStatus.success, people: people),
      onError: (error, stackTrace) => PeopleState(
        status: PeopleStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onCreationRequested(
    PersonCreationRequested event,
    Emitter<PeopleState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await _createPerson(CreatePersonCommand(name: event.name));
      emit(state.copyWith(isSaving: false));
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onRenameRequested(
    PersonRenameRequested event,
    Emitter<PeopleState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await _renamePerson(
        RenamePersonCommand(personId: event.personId, name: event.name),
      );
      emit(state.copyWith(isSaving: false));
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }
}
