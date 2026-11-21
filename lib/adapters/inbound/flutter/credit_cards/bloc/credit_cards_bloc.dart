import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subs/application/ports/inbound/create_credit_card.dart';
import 'package:subs/application/ports/inbound/watch_credit_cards_with_subscriptions.dart';
import 'package:subs/domain/credit_cards/credit_card_with_subscriptions.dart';

sealed class CreditCardsEvent extends Equatable {
  const CreditCardsEvent();

  @override
  List<Object?> get props => [];
}

final class CreditCardsStarted extends CreditCardsEvent {
  const CreditCardsStarted({this.includeInactive = false});

  final bool includeInactive;

  @override
  List<Object?> get props => [includeInactive];
}

final class CreditCardCreationRequested extends CreditCardsEvent {
  const CreditCardCreationRequested(this.command);

  final CreateCreditCardCommand command;

  @override
  List<Object?> get props => [command];
}

enum CreditCardsStatus { initial, loading, success, failure }

final class CreditCardsState extends Equatable {
  const CreditCardsState({
    this.status = CreditCardsStatus.initial,
    this.cards = const [],
    this.isSaving = false,
    this.errorMessage,
  });

  final CreditCardsStatus status;
  final List<CreditCardWithSubscriptions> cards;
  final bool isSaving;
  final String? errorMessage;

  CreditCardsState copyWith({
    CreditCardsStatus? status,
    List<CreditCardWithSubscriptions>? cards,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => CreditCardsState(
    status: status ?? this.status,
    cards: cards ?? this.cards,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, cards, isSaving, errorMessage];
}

final class CreditCardsBloc extends Bloc<CreditCardsEvent, CreditCardsState> {
  CreditCardsBloc(this._watchCards, this._createCreditCard)
    : super(const CreditCardsState()) {
    on<CreditCardsStarted>(_onStarted);
    on<CreditCardCreationRequested>(_onCreationRequested);
  }

  final WatchCreditCardsWithSubscriptions _watchCards;
  final CreateCreditCard _createCreditCard;

  Future<void> _onStarted(
    CreditCardsStarted event,
    Emitter<CreditCardsState> emit,
  ) async {
    emit(const CreditCardsState(status: CreditCardsStatus.loading));
    await emit.forEach(
      _watchCards(includeInactive: event.includeInactive),
      onData: (cards) =>
          CreditCardsState(status: CreditCardsStatus.success, cards: cards),
      onError: (error, stackTrace) => CreditCardsState(
        status: CreditCardsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onCreationRequested(
    CreditCardCreationRequested event,
    Emitter<CreditCardsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await _createCreditCard(event.command);
      emit(state.copyWith(isSaving: false));
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }
}
