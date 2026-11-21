import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subs/application/ports/inbound/delete_subscription.dart';
import 'package:subs/application/ports/inbound/get_subscription_details.dart';
import 'package:subs/application/ports/inbound/update_subscription_weights.dart';
import 'package:subs/application/ports/inbound/update_subscription_info.dart';
import 'package:subs/domain/subscriptions/subscription_details.dart';

sealed class SubscriptionDetailsEvent extends Equatable {
  const SubscriptionDetailsEvent();

  @override
  List<Object?> get props => [];
}

final class SubscriptionDetailsStarted extends SubscriptionDetailsEvent {
  const SubscriptionDetailsStarted(this.subscriptionId);

  final String subscriptionId;

  @override
  List<Object?> get props => [subscriptionId];
}

final class SubscriptionDetailsDeletionRequested
    extends SubscriptionDetailsEvent {
  const SubscriptionDetailsDeletionRequested();
}

final class SubscriptionWeightsUpdateRequested
    extends SubscriptionDetailsEvent {
  const SubscriptionWeightsUpdateRequested(this.weights);

  final Map<String, int> weights;

  @override
  List<Object?> get props => [weights];
}

final class SubscriptionInfoUpdateRequested extends SubscriptionDetailsEvent {
  const SubscriptionInfoUpdateRequested(this.command);

  final UpdateSubscriptionInfoCommand command;

  @override
  List<Object?> get props => [command];
}

enum SubscriptionDetailsStatus { initial, loading, success, notFound, failure }

final class SubscriptionDetailsState extends Equatable {
  const SubscriptionDetailsState({
    this.status = SubscriptionDetailsStatus.initial,
    this.details,
    this.isDeleting = false,
    this.isUpdatingWeights = false,
    this.isUpdatingInfo = false,
    this.isDeleted = false,
    this.errorMessage,
  });

  final SubscriptionDetailsStatus status;
  final SubscriptionDetails? details;
  final bool isDeleting;
  final bool isUpdatingWeights;
  final bool isUpdatingInfo;
  final bool isDeleted;
  final String? errorMessage;

  SubscriptionDetailsState copyWith({
    SubscriptionDetailsStatus? status,
    SubscriptionDetails? details,
    bool? isDeleting,
    bool? isUpdatingWeights,
    bool? isUpdatingInfo,
    bool? isDeleted,
    String? errorMessage,
    bool clearError = false,
  }) => SubscriptionDetailsState(
    status: status ?? this.status,
    details: details ?? this.details,
    isDeleting: isDeleting ?? this.isDeleting,
    isUpdatingWeights: isUpdatingWeights ?? this.isUpdatingWeights,
    isUpdatingInfo: isUpdatingInfo ?? this.isUpdatingInfo,
    isDeleted: isDeleted ?? this.isDeleted,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    details,
    isDeleting,
    isUpdatingWeights,
    isUpdatingInfo,
    isDeleted,
    errorMessage,
  ];
}

final class SubscriptionDetailsBloc
    extends Bloc<SubscriptionDetailsEvent, SubscriptionDetailsState> {
  SubscriptionDetailsBloc(
    this._getDetails,
    this._deleteSubscription,
    this._updateWeights,
    this._updateInfo,
  ) : super(const SubscriptionDetailsState()) {
    on<SubscriptionDetailsStarted>(_onStarted);
    on<SubscriptionDetailsDeletionRequested>(_onDeletionRequested);
    on<SubscriptionWeightsUpdateRequested>(_onWeightsUpdateRequested);
    on<SubscriptionInfoUpdateRequested>(_onInfoUpdateRequested);
  }

  final GetSubscriptionDetails _getDetails;
  final DeleteSubscription _deleteSubscription;
  final UpdateSubscriptionWeights _updateWeights;
  final UpdateSubscriptionInfo _updateInfo;

  Future<void> _onStarted(
    SubscriptionDetailsStarted event,
    Emitter<SubscriptionDetailsState> emit,
  ) async {
    emit(
      const SubscriptionDetailsState(status: SubscriptionDetailsStatus.loading),
    );
    try {
      final details = await _getDetails(event.subscriptionId);
      if (details == null) {
        emit(
          const SubscriptionDetailsState(
            status: SubscriptionDetailsStatus.notFound,
          ),
        );
      } else {
        emit(
          SubscriptionDetailsState(
            status: SubscriptionDetailsStatus.success,
            details: details,
          ),
        );
      }
    } catch (error) {
      emit(
        SubscriptionDetailsState(
          status: SubscriptionDetailsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeletionRequested(
    SubscriptionDetailsDeletionRequested event,
    Emitter<SubscriptionDetailsState> emit,
  ) async {
    final details = state.details;
    if (details == null) return;
    emit(state.copyWith(isDeleting: true, clearError: true));
    try {
      await _deleteSubscription(details.id);
      emit(state.copyWith(isDeleting: false, isDeleted: true));
    } catch (error) {
      emit(state.copyWith(isDeleting: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onWeightsUpdateRequested(
    SubscriptionWeightsUpdateRequested event,
    Emitter<SubscriptionDetailsState> emit,
  ) async {
    final details = state.details;
    if (details == null) return;
    emit(state.copyWith(isUpdatingWeights: true, clearError: true));
    try {
      await _updateWeights(
        UpdateSubscriptionWeightsCommand(
          subscriptionId: details.id,
          weights: event.weights.entries
              .map(
                (entry) => SubscriptionWeightInput(
                  personId: entry.key,
                  shareWeight: entry.value,
                ),
              )
              .toList(growable: false),
        ),
      );
      final refreshed = await _getDetails(details.id);
      emit(
        SubscriptionDetailsState(
          status: refreshed == null
              ? SubscriptionDetailsStatus.notFound
              : SubscriptionDetailsStatus.success,
          details: refreshed,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isUpdatingWeights: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onInfoUpdateRequested(
    SubscriptionInfoUpdateRequested event,
    Emitter<SubscriptionDetailsState> emit,
  ) async {
    final details = state.details;
    if (details == null) return;
    emit(state.copyWith(isUpdatingInfo: true, clearError: true));
    try {
      await _updateInfo(event.command);
      final refreshed = await _getDetails(details.id);
      emit(
        SubscriptionDetailsState(
          status: refreshed == null
              ? SubscriptionDetailsStatus.notFound
              : SubscriptionDetailsStatus.success,
          details: refreshed,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(isUpdatingInfo: false, errorMessage: error.toString()),
      );
    }
  }
}
