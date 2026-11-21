import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:subs/adapters/inbound/flutter/categories/bloc/categories_bloc.dart';
import 'package:subs/adapters/inbound/flutter/categories/categories_page.dart';
import 'package:subs/adapters/inbound/flutter/credit_cards/bloc/credit_cards_bloc.dart';
import 'package:subs/adapters/inbound/flutter/credit_cards/credit_cards_page.dart';
import 'package:subs/adapters/inbound/flutter/navigation/app_shell.dart';
import 'package:subs/adapters/inbound/flutter/people/bloc/people_bloc.dart';
import 'package:subs/adapters/inbound/flutter/people/people_page.dart';
import 'package:subs/adapters/inbound/flutter/subscriptions/bloc/subscriptions_bloc.dart';
import 'package:subs/adapters/inbound/flutter/subscriptions/bloc/subscription_details_bloc.dart';
import 'package:subs/adapters/inbound/flutter/subscriptions/subscription_details_page.dart';
import 'package:subs/adapters/inbound/flutter/subscriptions/subscriptions_page.dart';
import 'package:subs/application/ports/inbound/create_credit_card.dart';
import 'package:subs/application/ports/inbound/create_category.dart';
import 'package:subs/application/ports/inbound/create_person.dart';
import 'package:subs/application/ports/inbound/create_subscription.dart';
import 'package:subs/application/ports/inbound/delete_subscription.dart';
import 'package:subs/application/ports/inbound/get_subscription_details.dart';
import 'package:subs/application/ports/inbound/rename_person.dart';
import 'package:subs/application/ports/inbound/delete_category.dart';
import 'package:subs/application/ports/inbound/rename_category.dart';
import 'package:subs/application/ports/inbound/watch_categories.dart';
import 'package:subs/application/ports/inbound/watch_credit_cards_with_subscriptions.dart';
import 'package:subs/application/ports/inbound/watch_current_subscriptions.dart';
import 'package:subs/application/ports/inbound/watch_people.dart';
import 'package:subs/application/ports/inbound/update_subscription_weights.dart';
import 'package:subs/application/ports/inbound/update_subscription_info.dart';

abstract final class AppRoute {
  static const subscriptions = '/subscriptions';
  static const creditCards = '/credit-cards';
  static const people = '/people';
  static const categories = '/categories';

  static String subscriptionDetails(String subscriptionId) =>
      '$subscriptions/$subscriptionId';
}

final appRouter = GoRouter(
  initialLocation: AppRoute.subscriptions,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.subscriptions,
              builder: (context, state) => BlocProvider(
                create: (context) => SubscriptionsBloc(
                  context.read<WatchCurrentSubscriptions>(),
                  context.read<CreateSubscription>(),
                  context.read<DeleteSubscription>(),
                )..add(SubscriptionsStarted(referenceDate: DateTime.now())),
                child: const SubscriptionsPage(),
              ),
              routes: [
                GoRoute(
                  path: ':subscriptionId',
                  builder: (context, state) {
                    final subscriptionId =
                        state.pathParameters['subscriptionId']!;
                    return BlocProvider(
                      create: (context) => SubscriptionDetailsBloc(
                        context.read<GetSubscriptionDetails>(),
                        context.read<DeleteSubscription>(),
                        context.read<UpdateSubscriptionWeights>(),
                        context.read<UpdateSubscriptionInfo>(),
                      )..add(SubscriptionDetailsStarted(subscriptionId)),
                      child: const SubscriptionDetailsPage(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.creditCards,
              builder: (context, state) => BlocProvider(
                create: (context) => CreditCardsBloc(
                  context.read<WatchCreditCardsWithSubscriptions>(),
                  context.read<CreateCreditCard>(),
                )..add(const CreditCardsStarted()),
                child: const CreditCardsPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.people,
              builder: (context, state) => BlocProvider(
                create: (context) => PeopleBloc(
                  context.read<WatchPeople>(),
                  context.read<CreatePerson>(),
                  context.read<RenamePerson>(),
                )..add(const PeopleStarted()),
                child: const PeoplePage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.categories,
              builder: (context, state) => BlocProvider(
                create: (context) => CategoriesBloc(
                  context.read<WatchCategories>(),
                  context.read<CreateCategory>(),
                  context.read<RenameCategory>(),
                  context.read<DeleteCategory>(),
                )..add(const CategoriesStarted()),
                child: const CategoriesPage(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: Center(child: Text(state.error?.toString() ?? 'Unknown route')),
  ),
);
