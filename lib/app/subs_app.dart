import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subs/app/app_dependencies.dart';
import 'package:subs/app/router/app_router.dart';
import 'package:subs/app/theme/app_theme.dart';
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

class SubsApp extends StatelessWidget {
  const SubsApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CreatePerson>.value(
          value: dependencies.createPerson,
        ),
        RepositoryProvider<CreateCategory>.value(
          value: dependencies.createCategory,
        ),
        RepositoryProvider<RenameCategory>.value(
          value: dependencies.renameCategory,
        ),
        RepositoryProvider<DeleteCategory>.value(
          value: dependencies.deleteCategory,
        ),
        RepositoryProvider<WatchCategories>.value(
          value: dependencies.watchCategories,
        ),
        RepositoryProvider<CreateCreditCard>.value(
          value: dependencies.createCreditCard,
        ),
        RepositoryProvider<CreateSubscription>.value(
          value: dependencies.createSubscription,
        ),
        RepositoryProvider<DeleteSubscription>.value(
          value: dependencies.deleteSubscription,
        ),
        RepositoryProvider<GetSubscriptionDetails>.value(
          value: dependencies.getSubscriptionDetails,
        ),
        RepositoryProvider<UpdateSubscriptionWeights>.value(
          value: dependencies.updateSubscriptionWeights,
        ),
        RepositoryProvider<UpdateSubscriptionInfo>.value(
          value: dependencies.updateSubscriptionInfo,
        ),
        RepositoryProvider<RenamePerson>.value(
          value: dependencies.renamePerson,
        ),
        RepositoryProvider<WatchPeople>.value(value: dependencies.watchPeople),
        RepositoryProvider<WatchCurrentSubscriptions>.value(
          value: dependencies.watchCurrentSubscriptions,
        ),
        RepositoryProvider<WatchCreditCardsWithSubscriptions>.value(
          value: dependencies.watchCreditCardsWithSubscriptions,
        ),
      ],
      child: MaterialApp.router(
        title: 'Subs',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
