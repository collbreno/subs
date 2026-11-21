import 'package:flutter/widgets.dart';
import 'package:subs/adapters/outbound/identity/uuid_id_generator.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/database_changes.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/local_database.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/sqlite_credit_card_repository.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/sqlite_category_repository.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/sqlite_people_repository.dart';
import 'package:subs/adapters/outbound/persistence/sqlite/sqlite_subscription_repository.dart';
import 'package:subs/app/app_dependencies.dart';
import 'package:subs/app/subs_app.dart';
import 'package:subs/application/services/create_credit_card_service.dart';
import 'package:subs/application/services/create_category_service.dart';
import 'package:subs/application/services/create_person_service.dart';
import 'package:subs/application/services/create_subscription_service.dart';
import 'package:subs/application/services/delete_subscription_service.dart';
import 'package:subs/application/services/get_subscription_details_service.dart';
import 'package:subs/application/services/rename_person_service.dart';
import 'package:subs/application/services/delete_category_service.dart';
import 'package:subs/application/services/rename_category_service.dart';
import 'package:subs/application/services/watch_categories_service.dart';
import 'package:subs/application/services/watch_credit_cards_with_subscriptions_service.dart';
import 'package:subs/application/services/watch_current_subscriptions_service.dart';
import 'package:subs/application/services/watch_people_service.dart';
import 'package:subs/application/services/update_subscription_weights_service.dart';
import 'package:subs/application/services/update_subscription_info_service.dart';

Future<void> bootstrap() async {
  final database = await LocalDatabase.open();
  final changes = DatabaseChanges();
  final people = SqlitePeopleRepository(database, changes);
  final categories = SqliteCategoryRepository(database, changes);
  final cards = SqliteCreditCardRepository(database, changes);
  final subscriptions = SqliteSubscriptionRepository(database, changes);
  const ids = UuidIdGenerator();

  final dependencies = AppDependencies(
    createPerson: CreatePersonService(people, ids),
    createCategory: CreateCategoryService(categories, ids),
    renameCategory: RenameCategoryService(categories),
    deleteCategory: DeleteCategoryService(categories),
    watchCategories: WatchCategoriesService(categories),
    createCreditCard: CreateCreditCardService(cards, people, ids),
    createSubscription: CreateSubscriptionService(subscriptions, cards, ids),
    deleteSubscription: DeleteSubscriptionService(subscriptions),
    getSubscriptionDetails: GetSubscriptionDetailsService(subscriptions),
    updateSubscriptionWeights: UpdateSubscriptionWeightsService(subscriptions),
    updateSubscriptionInfo: UpdateSubscriptionInfoService(subscriptions, cards),
    renamePerson: RenamePersonService(people),
    watchPeople: WatchPeopleService(people),
    watchCurrentSubscriptions: WatchCurrentSubscriptionsService(subscriptions),
    watchCreditCardsWithSubscriptions: WatchCreditCardsWithSubscriptionsService(
      cards,
    ),
  );

  runApp(SubsApp(dependencies: dependencies));
}
