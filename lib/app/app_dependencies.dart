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

final class AppDependencies {
  const AppDependencies({
    required this.createPerson,
    required this.createCategory,
    required this.renameCategory,
    required this.deleteCategory,
    required this.watchCategories,
    required this.createCreditCard,
    required this.createSubscription,
    required this.deleteSubscription,
    required this.getSubscriptionDetails,
    required this.updateSubscriptionWeights,
    required this.updateSubscriptionInfo,
    required this.renamePerson,
    required this.watchPeople,
    required this.watchCurrentSubscriptions,
    required this.watchCreditCardsWithSubscriptions,
  });

  final CreatePerson createPerson;
  final CreateCategory createCategory;
  final RenameCategory renameCategory;
  final DeleteCategory deleteCategory;
  final WatchCategories watchCategories;
  final CreateCreditCard createCreditCard;
  final CreateSubscription createSubscription;
  final DeleteSubscription deleteSubscription;
  final GetSubscriptionDetails getSubscriptionDetails;
  final UpdateSubscriptionWeights updateSubscriptionWeights;
  final UpdateSubscriptionInfo updateSubscriptionInfo;
  final RenamePerson renamePerson;
  final WatchPeople watchPeople;
  final WatchCurrentSubscriptions watchCurrentSubscriptions;
  final WatchCreditCardsWithSubscriptions watchCreditCardsWithSubscriptions;
}
