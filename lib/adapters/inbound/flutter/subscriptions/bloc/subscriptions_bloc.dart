import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subs/application/ports/inbound/create_subscription.dart';
import 'package:subs/application/ports/inbound/delete_subscription.dart';
import 'package:subs/application/ports/inbound/watch_current_subscriptions.dart';
import 'package:subs/domain/subscriptions/subscription_summary.dart';

sealed class SubscriptionsEvent extends Equatable {
  const SubscriptionsEvent();

  @override
  List<Object?> get props => [];
}

final class SubscriptionsStarted extends SubscriptionsEvent {
  const SubscriptionsStarted({required this.referenceDate});

  final DateTime referenceDate;

  @override
  List<Object?> get props => [referenceDate];
}

final class SubscriptionCreationRequested extends SubscriptionsEvent {
  const SubscriptionCreationRequested(this.command);

  final CreateSubscriptionCommand command;

  @override
  List<Object?> get props => [command];
}

final class SubscriptionDeletionRequested extends SubscriptionsEvent {
  const SubscriptionDeletionRequested(this.subscriptionId);

  final String subscriptionId;

  @override
  List<Object?> get props => [subscriptionId];
}

enum SubscriptionsStatus { initial, loading, success, failure }

final class SubscriptionsState extends Equatable {
  const SubscriptionsState({
    this.status = SubscriptionsStatus.initial,
    this.subscriptions = const [],
    this.isSaving = false,
    this.errorMessage,
  });

  final SubscriptionsStatus status;
  final List<SubscriptionSummary> subscriptions;
  final bool isSaving;
  final String? errorMessage;

  SubscriptionsState copyWith({
    SubscriptionsStatus? status,
    List<SubscriptionSummary>? subscriptions,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => SubscriptionsState(
    status: status ?? this.status,
    subscriptions: subscriptions ?? this.subscriptions,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, subscriptions, isSaving, errorMessage];
}

final class SubscriptionsBloc
    extends Bloc<SubscriptionsEvent, SubscriptionsState> {
  SubscriptionsBloc(
    this._watchCurrent,
    this._createSubscription,
    this._deleteSubscription,
  ) : super(const SubscriptionsState()) {
    on<SubscriptionsStarted>(_onStarted);
    on<SubscriptionCreationRequested>(_onCreationRequested);
    on<SubscriptionDeletionRequested>(_onDeletionRequested);
  }

  final WatchCurrentSubscriptions _watchCurrent;
  final CreateSubscription _createSubscription;
  final DeleteSubscription _deleteSubscription;

  Future<void> _onStarted(
    SubscriptionsStarted event,
    Emitter<SubscriptionsState> emit,
  ) async {
    emit(const SubscriptionsState(status: SubscriptionsStatus.loading));
    await emit.forEach(
      _watchCurrent(event.referenceDate),
      onData: (subscriptions) => SubscriptionsState(
        status: SubscriptionsStatus.success,
        subscriptions: subscriptions,
      ),
      onError: (error, stackTrace) => SubscriptionsState(
        status: SubscriptionsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onCreationRequested(
    SubscriptionCreationRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await _createSubscription(event.command);
      emit(state.copyWith(isSaving: false));
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onDeletionRequested(
    SubscriptionDeletionRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      await _deleteSubscription(event.subscriptionId);
      emit(state.copyWith(isSaving: false));
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }
}
