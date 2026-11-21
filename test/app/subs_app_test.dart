import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subs/app/app_dependencies.dart';
import 'package:subs/app/subs_app.dart';
import 'package:subs/application/ports/inbound/create_category.dart';
import 'package:subs/application/ports/inbound/create_credit_card.dart';
import 'package:subs/application/ports/inbound/create_person.dart';
import 'package:subs/application/ports/inbound/create_subscription.dart';
import 'package:subs/application/ports/inbound/delete_category.dart';
import 'package:subs/application/ports/inbound/delete_subscription.dart';
import 'package:subs/application/ports/inbound/get_subscription_details.dart';
import 'package:subs/application/ports/inbound/rename_category.dart';
import 'package:subs/application/ports/inbound/rename_person.dart';
import 'package:subs/application/ports/inbound/watch_categories.dart';
import 'package:subs/application/ports/inbound/watch_credit_cards_with_subscriptions.dart';
import 'package:subs/application/ports/inbound/watch_current_subscriptions.dart';
import 'package:subs/application/ports/inbound/watch_people.dart';
import 'package:subs/application/ports/inbound/update_subscription_weights.dart';
import 'package:subs/application/ports/inbound/update_subscription_info.dart';
import 'package:subs/domain/categories/category.dart';
import 'package:subs/domain/people/person.dart';
import 'package:subs/domain/shared/money.dart';
import 'package:subs/domain/subscriptions/payment_method.dart';
import 'package:subs/domain/subscriptions/subscription_details.dart';
import 'package:subs/domain/subscriptions/subscription_summary.dart';

class _CreatePersonMock extends Mock implements CreatePerson {}

class _CreateCategoryMock extends Mock implements CreateCategory {}

class _RenameCategoryMock extends Mock implements RenameCategory {}

class _DeleteCategoryMock extends Mock implements DeleteCategory {}

class _WatchCategoriesMock extends Mock implements WatchCategories {}

class _CreateCreditCardMock extends Mock implements CreateCreditCard {}

class _CreateSubscriptionMock extends Mock implements CreateSubscription {}

class _DeleteSubscriptionMock extends Mock implements DeleteSubscription {}

class _GetSubscriptionDetailsMock extends Mock
    implements GetSubscriptionDetails {}

class _UpdateSubscriptionWeightsMock extends Mock
    implements UpdateSubscriptionWeights {}

class _UpdateSubscriptionInfoMock extends Mock
    implements UpdateSubscriptionInfo {}

class _RenamePersonMock extends Mock implements RenamePerson {}

class _WatchPeopleMock extends Mock implements WatchPeople {}

class _WatchSubscriptionsMock extends Mock
    implements WatchCurrentSubscriptions {}

class _WatchCardsMock extends Mock
    implements WatchCreditCardsWithSubscriptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(const CreatePersonCommand(name: 'Fallback'));
    registerFallbackValue(
      const CreateCategoryCommand(name: 'Fallback', iconKey: 'category'),
    );
    registerFallbackValue(
      UpdateSubscriptionInfoCommand(
        subscriptionId: 'fallback',
        standardAmountCents: 100,
        paymentMethod: PaymentMethod.boleto,
        payerPersonId: 'fallback',
        billingDay: 1,
        startDate: DateTime(2026),
      ),
    );
    registerFallbackValue(
      const RenameCategoryCommand(
        categoryId: 'fallback',
        name: 'Fallback',
        iconKey: 'category',
      ),
    );
    registerFallbackValue(
      const UpdateSubscriptionWeightsCommand(
        subscriptionId: 'fallback',
        weights: [
          SubscriptionWeightInput(personId: 'fallback', shareWeight: 1),
        ],
      ),
    );
    registerFallbackValue(
      const RenamePersonCommand(personId: 'fallback', name: 'Fallback'),
    );
  });

  testWidgets('uses Material 3 and navigates between shell branches', (
    tester,
  ) async {
    final watchPeople = _WatchPeopleMock();
    final createCategory = _CreateCategoryMock();
    final renameCategory = _RenameCategoryMock();
    final watchCategories = _WatchCategoriesMock();
    final watchSubscriptions = _WatchSubscriptionsMock();
    final watchCards = _WatchCardsMock();
    when(watchPeople.call).thenAnswer(
      (_) => Stream.value(const [
        Person(id: 'current-user', name: 'Me', isCurrentUser: true),
        Person(id: 'alex', name: 'Alex'),
        Person(id: 'aaron', name: 'Aaron'),
      ]),
    );
    when(() => createCategory(any())).thenAnswer(
      (_) async => const Category(id: 'home', name: 'Home', iconKey: 'home'),
    );
    when(() => renameCategory(any())).thenAnswer(
      (_) async => const Category(id: 'other', name: 'Other', iconKey: 'home'),
    );
    when(watchCategories.call).thenAnswer(
      (_) => Stream.value(const [
        Category(id: 'other', name: 'Other', iconKey: 'category'),
      ]),
    );
    when(() => watchSubscriptions(any()))
        .thenAnswer((_) => Stream.value(const []));
    when(() => watchCards(includeInactive: any(named: 'includeInactive')))
        .thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(
      SubsApp(
        dependencies: AppDependencies(
          createPerson: _CreatePersonMock(),
          createCategory: createCategory,
          renameCategory: renameCategory,
          deleteCategory: _DeleteCategoryMock(),
          watchCategories: watchCategories,
          createCreditCard: _CreateCreditCardMock(),
          createSubscription: _CreateSubscriptionMock(),
          deleteSubscription: _DeleteSubscriptionMock(),
          getSubscriptionDetails: _GetSubscriptionDetailsMock(),
          updateSubscriptionWeights: _UpdateSubscriptionWeightsMock(),
          updateSubscriptionInfo: _UpdateSubscriptionInfoMock(),
          renamePerson: _RenamePersonMock(),
          watchPeople: watchPeople,
          watchCurrentSubscriptions: watchSubscriptions,
          watchCreditCardsWithSubscriptions: watchCards,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).useMaterial3, isTrue);
    expect(find.text('Subscriptions'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();

    expect(find.text('Credit cards'), findsOneWidget);
    expect(find.text('No credit cards yet'), findsOneWidget);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Add category'), findsOneWidget);

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Home');
    await tester.tap(find.byTooltip('Home'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    final createCommand =
        verify(() => createCategory(captureAny())).captured.single
            as CreateCategoryCommand;
    expect(createCommand.iconKey, 'home');

    await tester.tap(find.byTooltip('Edit category'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Home'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final renameCommand =
        verify(() => renameCategory(captureAny())).captured.single
            as RenameCategoryCommand;
    expect(renameCommand.iconKey, 'home');
  });

  testWidgets('can dismiss person dialog after submitting without crashing', (
    tester,
  ) async {
    final createPerson = _CreatePersonMock();
    final renamePerson = _RenamePersonMock();
    final watchPeople = _WatchPeopleMock();
    final watchCategories = _WatchCategoriesMock();
    final watchSubscriptions = _WatchSubscriptionsMock();
    final watchCards = _WatchCardsMock();
    when(() => createPerson(any()))
        .thenAnswer((_) async => const Person(id: 'alex', name: 'Alex'));
    when(() => renamePerson(any())).thenAnswer(
      (_) async =>
          const Person(id: 'current-user', name: 'Breno', isCurrentUser: true),
    );
    when(watchPeople.call).thenAnswer(
      (_) => Stream.value(const [
        Person(id: 'current-user', name: 'Me', isCurrentUser: true),
      ]),
    );
    when(watchCategories.call).thenAnswer(
      (_) => Stream.value(const [
        Category(id: 'other', name: 'Other', iconKey: 'category'),
      ]),
    );
    when(() => watchSubscriptions(any()))
        .thenAnswer((_) => Stream.value(const []));
    when(() => watchCards(includeInactive: any(named: 'includeInactive')))
        .thenAnswer((_) => Stream.value(const []));

    await tester.pumpWidget(
      SubsApp(
        dependencies: AppDependencies(
          createPerson: createPerson,
          createCategory: _CreateCategoryMock(),
          renameCategory: _RenameCategoryMock(),
          deleteCategory: _DeleteCategoryMock(),
          watchCategories: watchCategories,
          createCreditCard: _CreateCreditCardMock(),
          createSubscription: _CreateSubscriptionMock(),
          deleteSubscription: _DeleteSubscriptionMock(),
          getSubscriptionDetails: _GetSubscriptionDetailsMock(),
          updateSubscriptionWeights: _UpdateSubscriptionWeightsMock(),
          updateSubscriptionInfo: _UpdateSubscriptionInfoMock(),
          renamePerson: renamePerson,
          watchPeople: watchPeople,
          watchCurrentSubscriptions: watchSubscriptions,
          watchCreditCardsWithSubscriptions: watchCards,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add person'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Alex');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    verify(() => createPerson(any())).called(1);

    await tester.tap(find.byTooltip('Edit name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Breno');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    verify(() => renamePerson(any())).called(1);
  });

  testWidgets('opens subscription details and deletes from there', (
    tester,
  ) async {
    final watchPeople = _WatchPeopleMock();
    final watchCategories = _WatchCategoriesMock();
    final watchSubscriptions = _WatchSubscriptionsMock();
    final watchCards = _WatchCardsMock();
    final getDetails = _GetSubscriptionDetailsMock();
    final deleteSubscription = _DeleteSubscriptionMock();
    final updateWeights = _UpdateSubscriptionWeightsMock();
    final updateInfo = _UpdateSubscriptionInfoMock();
    final summary = SubscriptionSummary(
      id: 'electricity',
      title: 'Electricity',
      categoryName: 'Utilities',
      iconKey: 'utilities',
      standardAmount: Money(15000),
      currentUserShare: Money(7500),
      paymentMethod: PaymentMethod.boleto,
      payerName: 'Me',
      participantCount: 2,
    );
    final details = SubscriptionDetails(
      id: 'electricity',
      title: 'Electricity',
      categoryName: 'Utilities',
      iconKey: 'utilities',
      standardAmount: Money(15000),
      currentUserShare: Money(7500),
      paymentMethod: PaymentMethod.boleto,
      payerPersonId: 'current-user',
      payerName: 'Me',
      billingDay: 10,
      startDate: DateTime(2026),
      participants: [
        SubscriptionParticipantDetails(
          personId: 'current-user',
          name: 'Me',
          isCurrentUser: true,
          shareWeight: 1,
          shareAmount: Money(7500),
        ),
        SubscriptionParticipantDetails(
          personId: 'alex',
          name: 'Alex',
          isCurrentUser: false,
          shareWeight: 1,
          shareAmount: Money(7500),
        ),
      ],
    );
    when(watchPeople.call).thenAnswer(
      (_) => Stream.value(const [
        Person(id: 'current-user', name: 'Me', isCurrentUser: true),
        Person(id: 'alex', name: 'Alex'),
        Person(id: 'aaron', name: 'Aaron'),
      ]),
    );
    when(watchCategories.call).thenAnswer(
      (_) => Stream.value(const [
        Category(id: 'utilities', name: 'Utilities', iconKey: 'bolt'),
      ]),
    );
    when(() => watchSubscriptions(any()))
        .thenAnswer((_) => Stream.value([summary]));
    when(() => watchCards(includeInactive: any(named: 'includeInactive')))
        .thenAnswer((_) => Stream.value(const []));
    when(() => getDetails('electricity')).thenAnswer((_) async => details);
    when(() => deleteSubscription('electricity')).thenAnswer((_) async {});
    when(() => updateWeights(any())).thenAnswer((_) async {});
    when(() => updateInfo(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      SubsApp(
        dependencies: AppDependencies(
          createPerson: _CreatePersonMock(),
          createCategory: _CreateCategoryMock(),
          renameCategory: _RenameCategoryMock(),
          deleteCategory: _DeleteCategoryMock(),
          watchCategories: watchCategories,
          createCreditCard: _CreateCreditCardMock(),
          createSubscription: _CreateSubscriptionMock(),
          deleteSubscription: deleteSubscription,
          getSubscriptionDetails: getDetails,
          updateSubscriptionWeights: updateWeights,
          updateSubscriptionInfo: updateInfo,
          renamePerson: _RenamePersonMock(),
          watchPeople: watchPeople,
          watchCurrentSubscriptions: watchSubscriptions,
          watchCreditCardsWithSubscriptions: watchCards,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscriptions').last);
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('My total part'), findsOneWidget);
    expect(find.text('R\$ 150,00'), findsWidgets);
    expect(find.text('R\$ 75,00'), findsWidgets);

    await tester.tap(find.byTooltip('Grid view'));
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byTooltip('List view'), findsOneWidget);
    expect(find.text('My part: R\$ 75,00'), findsNothing);
    expect(find.text('R\$ 75,00'), findsWidgets);
    expect(find.textContaining('Utilities • Boleto'), findsNothing);

    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Electricity'));
    await tester.pumpAndSettle();

    expect(find.text('Subscription details'), findsOneWidget);
    expect(find.text('Your part'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Edit details'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Edit details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit details'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Standard value'),
      '180.00',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final infoCommand =
        verify(() => updateInfo(captureAny())).captured.single
            as UpdateSubscriptionInfoCommand;
    expect(infoCommand.standardAmountCents, 18000);
    await tester.scrollUntilVisible(
      find.textContaining('Alex'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Alex'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Change weights'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Change weights'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Decrease Me weight'));
    await tester.tap(find.byTooltip('Decrease Alex weight'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add person'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aaron'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final command =
        verify(() => updateWeights(captureAny())).captured.single
            as UpdateSubscriptionWeightsCommand;
    expect(
      command.weights
          .firstWhere((input) => input.personId == 'current-user')
          .shareWeight,
      0,
    );
    expect(command.weights.any((input) => input.personId == 'alex'), isFalse);
    expect(
      command.weights
          .firstWhere((input) => input.personId == 'aaron')
          .shareWeight,
      1,
    );

    await tester.scrollUntilVisible(
      find.text('Delete subscription'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Delete subscription'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => deleteSubscription('electricity')).called(1);
    expect(tester.takeException(), isNull);
  });
}
