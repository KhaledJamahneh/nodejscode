import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Einhod Water'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Purity in Every Drop'**
  String get appTagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @companyUsername.
  ///
  /// In en, this message translates to:
  /// **'Company Username'**
  String get companyUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue managing deliveries'**
  String get signInSubtitle;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @useDemoAccount.
  ///
  /// In en, this message translates to:
  /// **'Use Demo Account'**
  String get useDemoAccount;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @dashboardDesc.
  ///
  /// In en, this message translates to:
  /// **'View and manage your business overview'**
  String get dashboardDesc;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @production.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get production;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @overviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Financial and operational analytics'**
  String get overviewDesc;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @clientView.
  ///
  /// In en, this message translates to:
  /// **'Client View'**
  String get clientView;

  /// No description provided for @workerView.
  ///
  /// In en, this message translates to:
  /// **'Worker View'**
  String get workerView;

  /// No description provided for @adminView.
  ///
  /// In en, this message translates to:
  /// **'Admin View'**
  String get adminView;

  /// No description provided for @switchView.
  ///
  /// In en, this message translates to:
  /// **'Switch View'**
  String get switchView;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @gallons.
  ///
  /// In en, this message translates to:
  /// **'Gallons'**
  String get gallons;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @purchaseComplete.
  ///
  /// In en, this message translates to:
  /// **'Purchase complete! Balance updated'**
  String get purchaseComplete;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noActivity;

  /// No description provided for @notificationDeliveryAssigned.
  ///
  /// In en, this message translates to:
  /// **'New Task Assigned'**
  String get notificationDeliveryAssigned;

  /// No description provided for @notificationDeliveryAssignedMsg.
  ///
  /// In en, this message translates to:
  /// **'Admin assigned you a new delivery request'**
  String get notificationDeliveryAssignedMsg;

  /// No description provided for @notificationRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request Accepted'**
  String get notificationRequestAccepted;

  /// No description provided for @notificationRequestAcceptedMsg.
  ///
  /// In en, this message translates to:
  /// **'{workerName} has been assigned to your delivery request'**
  String notificationRequestAcceptedMsg(Object workerName);

  /// No description provided for @notificationDeliveryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Delivery Completed'**
  String get notificationDeliveryCompleted;

  /// No description provided for @notificationDeliveryCompletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your delivery has been completed'**
  String get notificationDeliveryCompletedMsg;

  /// No description provided for @notificationPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get notificationPaymentReceived;

  /// No description provided for @notificationPaymentReceivedMsg.
  ///
  /// In en, this message translates to:
  /// **'Payment of ₪{amount} received'**
  String notificationPaymentReceivedMsg(Object amount);

  /// No description provided for @notificationWorkerNearby.
  ///
  /// In en, this message translates to:
  /// **'Worker Nearby'**
  String get notificationWorkerNearby;

  /// No description provided for @notificationWorkerNearbyMsg.
  ///
  /// In en, this message translates to:
  /// **'{workerName} is nearby your location'**
  String notificationWorkerNearbyMsg(Object workerName);

  /// No description provided for @notificationGeneric.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationGeneric;

  /// No description provided for @notificationGenericMsg.
  ///
  /// In en, this message translates to:
  /// **'You have a new notification'**
  String get notificationGenericMsg;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @singleDate.
  ///
  /// In en, this message translates to:
  /// **'Single Date'**
  String get singleDate;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @workShifts.
  ///
  /// In en, this message translates to:
  /// **'Work Shifts'**
  String get workShifts;

  /// No description provided for @createShift.
  ///
  /// In en, this message translates to:
  /// **'Create Shift'**
  String get createShift;

  /// No description provided for @editShift.
  ///
  /// In en, this message translates to:
  /// **'Edit Shift'**
  String get editShift;

  /// No description provided for @deleteShift.
  ///
  /// In en, this message translates to:
  /// **'Delete Shift'**
  String get deleteShift;

  /// No description provided for @shiftName.
  ///
  /// In en, this message translates to:
  /// **'Shift Name'**
  String get shiftName;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @daysOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Days of Week'**
  String get daysOfWeek;

  /// No description provided for @noShifts.
  ///
  /// In en, this message translates to:
  /// **'No shifts'**
  String get noShifts;

  /// No description provided for @shiftCreated.
  ///
  /// In en, this message translates to:
  /// **'Shift created'**
  String get shiftCreated;

  /// No description provided for @shiftUpdated.
  ///
  /// In en, this message translates to:
  /// **'Shift updated'**
  String get shiftUpdated;

  /// No description provided for @shiftDeleted.
  ///
  /// In en, this message translates to:
  /// **'Shift deleted'**
  String get shiftDeleted;

  /// No description provided for @deleteShiftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this shift?'**
  String get deleteShiftConfirm;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @activeWorkers.
  ///
  /// In en, this message translates to:
  /// **'Active Workers'**
  String get activeWorkers;

  /// No description provided for @onShiftWorkers.
  ///
  /// In en, this message translates to:
  /// **'On-Shift Workers'**
  String get onShiftWorkers;

  /// No description provided for @currentlyWorking.
  ///
  /// In en, this message translates to:
  /// **'Currently Working'**
  String get currentlyWorking;

  /// No description provided for @allWorkers.
  ///
  /// In en, this message translates to:
  /// **'All Workers'**
  String get allWorkers;

  /// No description provided for @onShiftOnly.
  ///
  /// In en, this message translates to:
  /// **'On-Shift Only'**
  String get onShiftOnly;

  /// No description provided for @pendingDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Pending Deliveries'**
  String get pendingDeliveries;

  /// No description provided for @completedToday.
  ///
  /// In en, this message translates to:
  /// **'Completed Today'**
  String get completedToday;

  /// No description provided for @lowInventory.
  ///
  /// In en, this message translates to:
  /// **'Low Inventory'**
  String get lowInventory;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @salaryAdvance.
  ///
  /// In en, this message translates to:
  /// **'Salary Advance'**
  String get salaryAdvance;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @workers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workers;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @couponSettings.
  ///
  /// In en, this message translates to:
  /// **'Coupon Settings'**
  String get couponSettings;

  /// No description provided for @pricePerPage.
  ///
  /// In en, this message translates to:
  /// **'Price per page'**
  String get pricePerPage;

  /// No description provided for @bonusGallons.
  ///
  /// In en, this message translates to:
  /// **'Bonus gallons'**
  String get bonusGallons;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get totalPrice;

  /// No description provided for @editPackage.
  ///
  /// In en, this message translates to:
  /// **'Edit Package'**
  String get editPackage;

  /// No description provided for @employmentInfo.
  ///
  /// In en, this message translates to:
  /// **'Employment Info'**
  String get employmentInfo;

  /// No description provided for @financials.
  ///
  /// In en, this message translates to:
  /// **'Financials'**
  String get financials;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @advances.
  ///
  /// In en, this message translates to:
  /// **'Advances'**
  String get advances;

  /// No description provided for @recentDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Recent Deliveries'**
  String get recentDeliveries;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get accountInfo;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @coupons.
  ///
  /// In en, this message translates to:
  /// **'coupons'**
  String get coupons;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @payAsYouGo.
  ///
  /// In en, this message translates to:
  /// **'Pay as you go'**
  String get payAsYouGo;

  /// No description provided for @gallonsOnHand.
  ///
  /// In en, this message translates to:
  /// **'Gallons On Hand'**
  String get gallonsOnHand;

  /// No description provided for @expiryDays.
  ///
  /// In en, this message translates to:
  /// **'Expiry Days'**
  String get expiryDays;

  /// No description provided for @daysUntilExpiry.
  ///
  /// In en, this message translates to:
  /// **'Days until coupon book expires'**
  String get daysUntilExpiry;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived;

  /// No description provided for @addToDebt.
  ///
  /// In en, this message translates to:
  /// **'Add to debt'**
  String get addToDebt;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @allPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'All Payment Methods'**
  String get allPaymentMethods;

  /// No description provided for @allSizes.
  ///
  /// In en, this message translates to:
  /// **'All Sizes'**
  String get allSizes;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @sizes.
  ///
  /// In en, this message translates to:
  /// **'Sizes'**
  String get sizes;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get left;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @couponBookSize.
  ///
  /// In en, this message translates to:
  /// **'Coupon Book Size'**
  String get couponBookSize;

  /// No description provided for @morningShift.
  ///
  /// In en, this message translates to:
  /// **'Morning Shift'**
  String get morningShift;

  /// No description provided for @eveningShift.
  ///
  /// In en, this message translates to:
  /// **'Evening Shift'**
  String get eveningShift;

  /// No description provided for @fullDay.
  ///
  /// In en, this message translates to:
  /// **'Full Day'**
  String get fullDay;

  /// No description provided for @smallCoupon.
  ///
  /// In en, this message translates to:
  /// **'Small (100 Coupons)'**
  String get smallCoupon;

  /// No description provided for @mediumCoupon.
  ///
  /// In en, this message translates to:
  /// **'Medium (200 Coupons)'**
  String get mediumCoupon;

  /// No description provided for @largeCoupon.
  ///
  /// In en, this message translates to:
  /// **'Large (300 Coupons)'**
  String get largeCoupon;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @deliveryWorker.
  ///
  /// In en, this message translates to:
  /// **'Delivery Profile'**
  String get deliveryWorker;

  /// No description provided for @onsiteWorker.
  ///
  /// In en, this message translates to:
  /// **'Onsite Worker Profile'**
  String get onsiteWorker;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @midUrgent.
  ///
  /// In en, this message translates to:
  /// **'Mid-Urgent'**
  String get midUrgent;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @allPriorities.
  ///
  /// In en, this message translates to:
  /// **'All Priorities'**
  String get allPriorities;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

  /// No description provided for @assignWorker.
  ///
  /// In en, this message translates to:
  /// **'Assign Worker'**
  String get assignWorker;

  /// No description provided for @normalPriority.
  ///
  /// In en, this message translates to:
  /// **'Normal Priority'**
  String get normalPriority;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriority;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @scheduledTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Time'**
  String get scheduledTime;

  /// No description provided for @completedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed At'**
  String get completedAt;

  /// No description provided for @quickDelivery.
  ///
  /// In en, this message translates to:
  /// **'Quick Delivery'**
  String get quickDelivery;

  /// No description provided for @gallonsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Gallons Delivered'**
  String get gallonsDelivered;

  /// No description provided for @emptyGallonsReturned.
  ///
  /// In en, this message translates to:
  /// **'Empty Gallons Returned'**
  String get emptyGallonsReturned;

  /// No description provided for @specialPrice.
  ///
  /// In en, this message translates to:
  /// **'Special Price'**
  String get specialPrice;

  /// No description provided for @customAmount.
  ///
  /// In en, this message translates to:
  /// **'Custom Amount'**
  String get customAmount;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @deliveryCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Delivery created successfully'**
  String get deliveryCreatedSuccessfully;

  /// No description provided for @pleaseSelectClientAndWorker.
  ///
  /// In en, this message translates to:
  /// **'Please select client and worker'**
  String get pleaseSelectClientAndWorker;

  /// No description provided for @emptyGallonsCollected.
  ///
  /// In en, this message translates to:
  /// **'Empty Gallons Collected'**
  String get emptyGallonsCollected;

  /// No description provided for @analysisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Analysis Period'**
  String get analysisPeriod;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @deliveryPerformance.
  ///
  /// In en, this message translates to:
  /// **'Delivery Performance'**
  String get deliveryPerformance;

  /// No description provided for @financialOverview.
  ///
  /// In en, this message translates to:
  /// **'Financial Overview'**
  String get financialOverview;

  /// No description provided for @clientBaseDebt.
  ///
  /// In en, this message translates to:
  /// **'Client Base & Debt'**
  String get clientBaseDebt;

  /// No description provided for @topDeliveryWorkers.
  ///
  /// In en, this message translates to:
  /// **'Top Delivery Workers'**
  String get topDeliveryWorkers;

  /// No description provided for @onsitePerformance.
  ///
  /// In en, this message translates to:
  /// **'On-Site Performance'**
  String get onsitePerformance;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @avgTransaction.
  ///
  /// In en, this message translates to:
  /// **'Avg. Transaction'**
  String get avgTransaction;

  /// No description provided for @cashRevenue.
  ///
  /// In en, this message translates to:
  /// **'Cash Revenue'**
  String get cashRevenue;

  /// No description provided for @cardRevenue.
  ///
  /// In en, this message translates to:
  /// **'Card Revenue'**
  String get cardRevenue;

  /// No description provided for @totalClients.
  ///
  /// In en, this message translates to:
  /// **'Total Clients'**
  String get totalClients;

  /// No description provided for @activeSubs.
  ///
  /// In en, this message translates to:
  /// **'Active Subs.'**
  String get activeSubs;

  /// No description provided for @expiredSubs.
  ///
  /// In en, this message translates to:
  /// **'Expired Subs.'**
  String get expiredSubs;

  /// No description provided for @totalDebt.
  ///
  /// In en, this message translates to:
  /// **'Total Debt'**
  String get totalDebt;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @avg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avg;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUser;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRoles;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by username, email, or phone'**
  String get searchPlaceholder;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @workerType.
  ///
  /// In en, this message translates to:
  /// **'Worker Type'**
  String get workerType;

  /// No description provided for @assignedStation.
  ///
  /// In en, this message translates to:
  /// **'Assigned Station'**
  String get assignedStation;

  /// No description provided for @vehicleCapacity.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Capacity'**
  String get vehicleCapacity;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @assignRoles.
  ///
  /// In en, this message translates to:
  /// **'Assign Roles'**
  String get assignRoles;

  /// No description provided for @workerSettings.
  ///
  /// In en, this message translates to:
  /// **'Worker Settings'**
  String get workerSettings;

  /// No description provided for @confirmDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user?'**
  String get confirmDeleteUser;

  /// No description provided for @userDeactivated.
  ///
  /// In en, this message translates to:
  /// **'User deactivated'**
  String get userDeactivated;

  /// No description provided for @userActivated.
  ///
  /// In en, this message translates to:
  /// **'User activated'**
  String get userActivated;

  /// No description provided for @deactivateUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'{user} will not be able to login after deactivation.'**
  String deactivateUserConfirm(String user);

  /// No description provided for @activateUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'{user} will be able to login after activation.'**
  String activateUserConfirm(String user);

  /// No description provided for @deleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {user}?'**
  String deleteUserConfirm(String user);

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @keepCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'leave blank to keep current'**
  String get keepCurrentPassword;

  /// No description provided for @min8Chars.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get min8Chars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid format (e.g., +123456789)'**
  String get invalidPhone;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @operationsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Here\'s the latest update on your operations.'**
  String get operationsUpdate;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @actualGallons.
  ///
  /// In en, this message translates to:
  /// **'Actual Gallons'**
  String get actualGallons;

  /// No description provided for @emptyGallons.
  ///
  /// In en, this message translates to:
  /// **'Empty Gallons'**
  String get emptyGallons;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All Dates'**
  String get allDates;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @yourRequestsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your requests will appear here'**
  String get yourRequestsAppearHere;

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String expiresIn(int days);

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @requestWaterDelivery.
  ///
  /// In en, this message translates to:
  /// **'Request Water Delivery'**
  String get requestWaterDelivery;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @viewAllHistory.
  ///
  /// In en, this message translates to:
  /// **'View All History'**
  String get viewAllHistory;

  /// No description provided for @urgentDesc.
  ///
  /// In en, this message translates to:
  /// **'I need water today, as soon as possible'**
  String get urgentDesc;

  /// No description provided for @midUrgentDesc.
  ///
  /// In en, this message translates to:
  /// **'I need water today'**
  String get midUrgentDesc;

  /// No description provided for @nonUrgentDesc.
  ///
  /// In en, this message translates to:
  /// **'Whenever available'**
  String get nonUrgentDesc;

  /// No description provided for @requestReceived.
  ///
  /// In en, this message translates to:
  /// **'Request Received!'**
  String get requestReceived;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @proximityAlert.
  ///
  /// In en, this message translates to:
  /// **'Your delivery is {dist}m away — ETA {eta} min'**
  String proximityAlert(int dist, int eta);

  /// No description provided for @illBeReady.
  ///
  /// In en, this message translates to:
  /// **'I\'ll be ready'**
  String get illBeReady;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @noAssets.
  ///
  /// In en, this message translates to:
  /// **'No assets assigned'**
  String get noAssets;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @locationSharing.
  ///
  /// In en, this message translates to:
  /// **'Location Sharing'**
  String get locationSharing;

  /// No description provided for @activeAdminSeeYou.
  ///
  /// In en, this message translates to:
  /// **'Active — Admin can see your location'**
  String get activeAdminSeeYou;

  /// No description provided for @enableGpsPermission.
  ///
  /// In en, this message translates to:
  /// **'Please enable GPS and grant location permission'**
  String get enableGpsPermission;

  /// No description provided for @locationSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'When enabled, clients will receive a notification when you\'re within 500 meters of their address. Your exact location is not shared with clients.'**
  String get locationSharingDescription;

  /// No description provided for @gallonsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Gallons Remaining'**
  String get gallonsRemaining;

  /// No description provided for @mainList.
  ///
  /// In en, this message translates to:
  /// **'Main List'**
  String get mainList;

  /// No description provided for @secondaryList.
  ///
  /// In en, this message translates to:
  /// **'Secondary List'**
  String get secondaryList;

  /// No description provided for @recordDelivery.
  ///
  /// In en, this message translates to:
  /// **'Record Delivery'**
  String get recordDelivery;

  /// No description provided for @sendApology.
  ///
  /// In en, this message translates to:
  /// **'Send Apology'**
  String get sendApology;

  /// No description provided for @locationCaptured.
  ///
  /// In en, this message translates to:
  /// **'Location captured'**
  String get locationCaptured;

  /// No description provided for @confirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get confirmDelivery;

  /// No description provided for @dispenserDelivery.
  ///
  /// In en, this message translates to:
  /// **'Dispenser Delivery'**
  String get dispenserDelivery;

  /// No description provided for @dispensers.
  ///
  /// In en, this message translates to:
  /// **'Dispensers'**
  String get dispensers;

  /// No description provided for @dispenserSettings.
  ///
  /// In en, this message translates to:
  /// **'Dispenser Settings'**
  String get dispenserSettings;

  /// No description provided for @types.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get types;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @addType.
  ///
  /// In en, this message translates to:
  /// **'Add Type'**
  String get addType;

  /// No description provided for @editType.
  ///
  /// In en, this message translates to:
  /// **'Edit Type'**
  String get editType;

  /// No description provided for @typeName.
  ///
  /// In en, this message translates to:
  /// **'Type Name'**
  String get typeName;

  /// No description provided for @addFeature.
  ///
  /// In en, this message translates to:
  /// **'Add Feature'**
  String get addFeature;

  /// No description provided for @editFeature.
  ///
  /// In en, this message translates to:
  /// **'Edit Feature'**
  String get editFeature;

  /// No description provided for @featureName.
  ///
  /// In en, this message translates to:
  /// **'Feature Name'**
  String get featureName;

  /// No description provided for @stationStatus.
  ///
  /// In en, this message translates to:
  /// **'Station Status'**
  String get stationStatus;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @tempClosed.
  ///
  /// In en, this message translates to:
  /// **'Temporarily Closed'**
  String get tempClosed;

  /// No description provided for @closedUntilTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Closed until tomorrow'**
  String get closedUntilTomorrow;

  /// No description provided for @newFillingSession.
  ///
  /// In en, this message translates to:
  /// **'New Filling Session'**
  String get newFillingSession;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @deleteRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the request from {client}? This action cannot be undone.'**
  String deleteRequestConfirm(String client);

  /// No description provided for @cancelRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this request for {gallons} gallons?'**
  String cancelRequestConfirm(int gallons);

  /// No description provided for @priorityLevel.
  ///
  /// In en, this message translates to:
  /// **'Priority Level'**
  String get priorityLevel;

  /// No description provided for @addInstructions.
  ///
  /// In en, this message translates to:
  /// **'Add instructions...'**
  String get addInstructions;

  /// No description provided for @gpsSettings.
  ///
  /// In en, this message translates to:
  /// **'GPS Settings'**
  String get gpsSettings;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTracking;

  /// No description provided for @shareLocationDuringShift.
  ///
  /// In en, this message translates to:
  /// **'Share location during shift'**
  String get shareLocationDuringShift;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @recordedGallons.
  ///
  /// In en, this message translates to:
  /// **'Recorded Gallons'**
  String get recordedGallons;

  /// No description provided for @emptyReturned.
  ///
  /// In en, this message translates to:
  /// **'Empty Returned'**
  String get emptyReturned;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @urgentWithCount.
  ///
  /// In en, this message translates to:
  /// **'Urgent ({count})'**
  String urgentWithCount(int count);

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @totalDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Total Deliveries'**
  String get totalDeliveries;

  /// No description provided for @totalDeliveriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Total number of water deliveries successfully completed during the analysis period.'**
  String get totalDeliveriesDesc;

  /// No description provided for @totalGallonsDesc.
  ///
  /// In en, this message translates to:
  /// **'Total volume of water delivered to all clients combined during this period.'**
  String get totalGallonsDesc;

  /// No description provided for @avgPerDelivery.
  ///
  /// In en, this message translates to:
  /// **'Avg. per Delivery'**
  String get avgPerDelivery;

  /// No description provided for @avgPerDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'The mathematical average volume of water delivered per individual trip.'**
  String get avgPerDeliveryDesc;

  /// No description provided for @uniqueClients.
  ///
  /// In en, this message translates to:
  /// **'Unique Clients'**
  String get uniqueClients;

  /// No description provided for @uniqueClientsDesc.
  ///
  /// In en, this message translates to:
  /// **'The total number of distinct clients who received at least one delivery during this period.'**
  String get uniqueClientsDesc;

  /// No description provided for @totalRevenueDesc.
  ///
  /// In en, this message translates to:
  /// **'Gross income generated from all completed transactions and deliveries.'**
  String get totalRevenueDesc;

  /// No description provided for @avgTransactionDesc.
  ///
  /// In en, this message translates to:
  /// **'The average monetary value of each payment received from clients.'**
  String get avgTransactionDesc;

  /// No description provided for @cashRevenueDesc.
  ///
  /// In en, this message translates to:
  /// **'Portion of total revenue collected through physical cash payments.'**
  String get cashRevenueDesc;

  /// No description provided for @cardRevenueDesc.
  ///
  /// In en, this message translates to:
  /// **'Portion of total revenue collected through credit or debit card transactions.'**
  String get cardRevenueDesc;

  /// No description provided for @totalClientsDesc.
  ///
  /// In en, this message translates to:
  /// **'The total number of registered client accounts in the entire system.'**
  String get totalClientsDesc;

  /// No description provided for @activeSubsDesc.
  ///
  /// In en, this message translates to:
  /// **'Number of clients whose coupon books or cash accounts are currently valid and not expired.'**
  String get activeSubsDesc;

  /// No description provided for @expiredSubsDesc.
  ///
  /// In en, this message translates to:
  /// **'Number of clients whose service period has ended and require renewal.'**
  String get expiredSubsDesc;

  /// No description provided for @totalDebtDesc.
  ///
  /// In en, this message translates to:
  /// **'The total outstanding unpaid balance owed to the company by all clients.'**
  String get totalDebtDesc;

  /// No description provided for @noDeliveryWorkerData.
  ///
  /// In en, this message translates to:
  /// **'No delivery profile data available'**
  String get noDeliveryWorkerData;

  /// No description provided for @noOnsiteWorkerData.
  ///
  /// In en, this message translates to:
  /// **'No onsite worker profile data available'**
  String get noOnsiteWorkerData;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @editInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Info'**
  String get editInfo;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// No description provided for @workerAssigned.
  ///
  /// In en, this message translates to:
  /// **'Worker assigned successfully'**
  String get workerAssigned;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated successfully'**
  String get statusUpdated;

  /// No description provided for @requestDeleted.
  ///
  /// In en, this message translates to:
  /// **'Request deleted successfully'**
  String get requestDeleted;

  /// No description provided for @deliveryStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Delivery status updated successfully'**
  String get deliveryStatusUpdated;

  /// No description provided for @userDeleted.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get userDeleted;

  /// No description provided for @userCreated.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get userCreated;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully'**
  String get userUpdated;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @editUserInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit User Info'**
  String get editUserInfo;

  /// No description provided for @fillingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Open valve and start filling at {station}?'**
  String fillingConfirmation(String station);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @connectionIssue.
  ///
  /// In en, this message translates to:
  /// **'Connection Issue'**
  String get connectionIssue;

  /// No description provided for @unableToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dashboard'**
  String get unableToLoadDashboard;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @awaitingAction.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Action'**
  String get awaitingAction;

  /// No description provided for @onShift.
  ///
  /// In en, this message translates to:
  /// **'On Shift'**
  String get onShift;

  /// No description provided for @couldNotLoadStationStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not load station status'**
  String get couldNotLoadStationStatus;

  /// No description provided for @noAddress.
  ///
  /// In en, this message translates to:
  /// **'No Address'**
  String get noAddress;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequired;

  /// No description provided for @enableLocationToViewMap.
  ///
  /// In en, this message translates to:
  /// **'Please enable location to view the map'**
  String get enableLocationToViewMap;

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Location Settings'**
  String get openLocationSettings;

  /// No description provided for @remainingCoupons.
  ///
  /// In en, this message translates to:
  /// **'Remaining Coupons'**
  String get remainingCoupons;

  /// No description provided for @specialOffer.
  ///
  /// In en, this message translates to:
  /// **'Special Offer'**
  String get specialOffer;

  /// No description provided for @summerOfferDesc.
  ///
  /// In en, this message translates to:
  /// **'Get 10% off on your next reorder'**
  String get summerOfferDesc;

  /// No description provided for @coordinatesCopied.
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied'**
  String get coordinatesCopied;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Manually'**
  String get enterManually;

  /// No description provided for @homeLocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Home Location Saved'**
  String get homeLocationSaved;

  /// No description provided for @enterCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter Coordinates'**
  String get enterCoordinates;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @stationInformation.
  ///
  /// In en, this message translates to:
  /// **'Station Information'**
  String get stationInformation;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noSessionsYet;

  /// No description provided for @backendNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Backend route not implemented yet'**
  String get backendNotImplemented;

  /// No description provided for @lastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months'**
  String get lastSixMonths;

  /// No description provided for @addNewClient.
  ///
  /// In en, this message translates to:
  /// **'Add New Client'**
  String get addNewClient;

  /// No description provided for @todaysTotal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Total'**
  String get todaysTotal;

  /// No description provided for @adminUser.
  ///
  /// In en, this message translates to:
  /// **'Admin User'**
  String get adminUser;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sessionNumber.
  ///
  /// In en, this message translates to:
  /// **'Session #{number}'**
  String sessionNumber(int number);

  /// No description provided for @gallonsUnit.
  ///
  /// In en, this message translates to:
  /// **'{count} Gallons'**
  String gallonsUnit(int count);

  /// No description provided for @changeStationStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Station Status'**
  String get changeStationStatus;

  /// No description provided for @newFillingSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'New Filling Session'**
  String get newFillingSessionTitle;

  /// No description provided for @sessionNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Session #'**
  String get sessionNumberLabel;

  /// No description provided for @gallonsFilled.
  ///
  /// In en, this message translates to:
  /// **'Gallons Filled'**
  String get gallonsFilled;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// No description provided for @updateViaGPS.
  ///
  /// In en, this message translates to:
  /// **'Update via GPS'**
  String get updateViaGPS;

  /// No description provided for @gpsActive.
  ///
  /// In en, this message translates to:
  /// **'GPS Active'**
  String get gpsActive;

  /// No description provided for @gpsOff.
  ///
  /// In en, this message translates to:
  /// **'GPS Off'**
  String get gpsOff;

  /// No description provided for @gpsOn.
  ///
  /// In en, this message translates to:
  /// **'GPS On'**
  String get gpsOn;

  /// No description provided for @unknownWorker.
  ///
  /// In en, this message translates to:
  /// **'Unknown Worker'**
  String get unknownWorker;

  /// No description provided for @addNotes.
  ///
  /// In en, this message translates to:
  /// **'Add notes (optional)'**
  String get addNotes;

  /// No description provided for @updateGallonsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Update Gallons Remaining'**
  String get updateGallonsRemaining;

  /// No description provided for @liveMap.
  ///
  /// In en, this message translates to:
  /// **'Live Map'**
  String get liveMap;

  /// No description provided for @nextStops.
  ///
  /// In en, this message translates to:
  /// **'Next Stops'**
  String get nextStops;

  /// No description provided for @submitExpense.
  ///
  /// In en, this message translates to:
  /// **'Submit Expense'**
  String get submitExpense;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Entitled Entity'**
  String get destination;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid (Debt)'**
  String get unpaid;

  /// No description provided for @expenseSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Expense submitted!'**
  String get expenseSubmitted;

  /// No description provided for @unableToLoadDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Unable to load deliveries'**
  String get unableToLoadDeliveries;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get serialNumber;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriod;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @noStationsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No stations configured'**
  String get noStationsConfigured;

  /// No description provided for @stationManagement.
  ///
  /// In en, this message translates to:
  /// **'Station Management'**
  String get stationManagement;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @stationStatusUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Station status updated to'**
  String get stationStatusUpdatedTo;

  /// No description provided for @addStation.
  ///
  /// In en, this message translates to:
  /// **'Add Station'**
  String get addStation;

  /// No description provided for @editStation.
  ///
  /// In en, this message translates to:
  /// **'Edit Station'**
  String get editStation;

  /// No description provided for @stationName.
  ///
  /// In en, this message translates to:
  /// **'Station Name'**
  String get stationName;

  /// No description provided for @stationAddress.
  ///
  /// In en, this message translates to:
  /// **'Station Address'**
  String get stationAddress;

  /// No description provided for @stationAdded.
  ///
  /// In en, this message translates to:
  /// **'Station added successfully'**
  String get stationAdded;

  /// No description provided for @stationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Station updated successfully'**
  String get stationUpdated;

  /// No description provided for @enterStationName.
  ///
  /// In en, this message translates to:
  /// **'Enter station name'**
  String get enterStationName;

  /// No description provided for @enterStationAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter station address (optional)'**
  String get enterStationAddress;

  /// No description provided for @stationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Station deleted successfully'**
  String get stationDeleted;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteConfirmation;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'delivery'**
  String get delivery;

  /// No description provided for @deliveryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Delivery deleted successfully'**
  String get deliveryDeleted;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newItem;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignment;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned To'**
  String get assignedTo;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @inSettings.
  ///
  /// In en, this message translates to:
  /// **'in settings'**
  String get inSettings;

  /// No description provided for @schedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedules;

  /// No description provided for @scheduledDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Deliveries'**
  String get scheduledDeliveries;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add Schedule'**
  String get addSchedule;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit Schedule'**
  String get editSchedule;

  /// No description provided for @scheduleType.
  ///
  /// In en, this message translates to:
  /// **'Schedule Type'**
  String get scheduleType;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @biweekly.
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly'**
  String get biweekly;

  /// No description provided for @selectDays.
  ///
  /// In en, this message translates to:
  /// **'Select Days'**
  String get selectDays;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @scheduleCreated.
  ///
  /// In en, this message translates to:
  /// **'Schedule created successfully'**
  String get scheduleCreated;

  /// No description provided for @scheduleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated successfully'**
  String get scheduleUpdated;

  /// No description provided for @scheduleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Schedule deleted successfully'**
  String get scheduleDeleted;

  /// No description provided for @feature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get feature;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @fillLog.
  ///
  /// In en, this message translates to:
  /// **'Fill Log'**
  String get fillLog;

  /// No description provided for @stationIs.
  ///
  /// In en, this message translates to:
  /// **'Station is'**
  String get stationIs;

  /// No description provided for @productionOverview.
  ///
  /// In en, this message translates to:
  /// **'Production Overview'**
  String get productionOverview;

  /// No description provided for @avgPerSession.
  ///
  /// In en, this message translates to:
  /// **'Avg/Session'**
  String get avgPerSession;

  /// No description provided for @nextStop.
  ///
  /// In en, this message translates to:
  /// **'Next Stop'**
  String get nextStop;

  /// No description provided for @gpsCurrentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'GPS is currently disabled'**
  String get gpsCurrentlyDisabled;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses found'**
  String get noExpenses;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @reimburse.
  ///
  /// In en, this message translates to:
  /// **'Reimburse'**
  String get reimburse;

  /// No description provided for @myPocket.
  ///
  /// In en, this message translates to:
  /// **'My Pocket'**
  String get myPocket;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @noSchedules.
  ///
  /// In en, this message translates to:
  /// **'No Schedules'**
  String get noSchedules;

  /// No description provided for @noSchedulesDesc.
  ///
  /// In en, this message translates to:
  /// **'Create recurring delivery schedules for clients'**
  String get noSchedulesDesc;

  /// No description provided for @addDeliverySchedule.
  ///
  /// In en, this message translates to:
  /// **'Add Delivery Schedule'**
  String get addDeliverySchedule;

  /// No description provided for @selectClient.
  ///
  /// In en, this message translates to:
  /// **'Select client'**
  String get selectClient;

  /// No description provided for @assignWorkerOptional.
  ///
  /// In en, this message translates to:
  /// **'Assign Worker (Optional)'**
  String get assignWorkerOptional;

  /// No description provided for @autoAssignOrSelectWorker.
  ///
  /// In en, this message translates to:
  /// **'Auto-assign or select worker'**
  String get autoAssignOrSelectWorker;

  /// No description provided for @autoAssign.
  ///
  /// In en, this message translates to:
  /// **'Auto-assign'**
  String get autoAssign;

  /// No description provided for @enterGallons.
  ///
  /// In en, this message translates to:
  /// **'Enter gallons'**
  String get enterGallons;

  /// No description provided for @deliveryDays.
  ///
  /// In en, this message translates to:
  /// **'Delivery Days'**
  String get deliveryDays;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// No description provided for @endDateOptional.
  ///
  /// In en, this message translates to:
  /// **'End Date (Optional)'**
  String get endDateOptional;

  /// No description provided for @noEndDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get noEndDate;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @addSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Add any special instructions...'**
  String get addSpecialInstructions;

  /// No description provided for @createSchedule.
  ///
  /// In en, this message translates to:
  /// **'Create Schedule'**
  String get createSchedule;

  /// No description provided for @selectAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Select at least one day'**
  String get selectAtLeastOneDay;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @searchClients.
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get searchClients;

  /// No description provided for @doneSelected.
  ///
  /// In en, this message translates to:
  /// **'Done ({count} selected)'**
  String doneSelected(int count);

  /// No description provided for @tapToSelectClients.
  ///
  /// In en, this message translates to:
  /// **'Tap to select clients'**
  String get tapToSelectClients;

  /// No description provided for @selectAtLeastOneClient.
  ///
  /// In en, this message translates to:
  /// **'Select at least one client'**
  String get selectAtLeastOneClient;

  /// No description provided for @noClientsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No clients available'**
  String get noClientsAvailable;

  /// No description provided for @deliveryEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Delivery every day'**
  String get deliveryEveryDay;

  /// No description provided for @deliveryOnSelectedDaysEachWeek.
  ///
  /// In en, this message translates to:
  /// **'Delivery on selected days each week'**
  String get deliveryOnSelectedDaysEachWeek;

  /// No description provided for @deliveryOnSelectedDaysEveryOtherWeek.
  ///
  /// In en, this message translates to:
  /// **'Delivery on selected days every other week'**
  String get deliveryOnSelectedDaysEveryOtherWeek;

  /// No description provided for @deliveryXTimesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Delivery X times per month'**
  String get deliveryXTimesPerMonth;

  /// No description provided for @customIrregularSchedule.
  ///
  /// In en, this message translates to:
  /// **'Custom/irregular schedule'**
  String get customIrregularSchedule;

  /// No description provided for @timesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Times per month'**
  String get timesPerMonth;

  /// No description provided for @everyNDays.
  ///
  /// In en, this message translates to:
  /// **'Every N days'**
  String get everyNDays;

  /// No description provided for @nTimes.
  ///
  /// In en, this message translates to:
  /// **'N times'**
  String get nTimes;

  /// No description provided for @customScheduleExample.
  ///
  /// In en, this message translates to:
  /// **'Example: Every 3 days, 2 times = 2 deliveries within 3 days'**
  String get customScheduleExample;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @avgPerClient.
  ///
  /// In en, this message translates to:
  /// **'Avg/Client'**
  String get avgPerClient;

  /// No description provided for @weeklyGallons.
  ///
  /// In en, this message translates to:
  /// **'Weekly Gallons'**
  String get weeklyGallons;

  /// No description provided for @searchSchedules.
  ///
  /// In en, this message translates to:
  /// **'Search schedules'**
  String get searchSchedules;

  /// No description provided for @everyMon.
  ///
  /// In en, this message translates to:
  /// **'Every Mon'**
  String get everyMon;

  /// No description provided for @everyTue.
  ///
  /// In en, this message translates to:
  /// **'Every Tue'**
  String get everyTue;

  /// No description provided for @everyWed.
  ///
  /// In en, this message translates to:
  /// **'Every Wed'**
  String get everyWed;

  /// No description provided for @everyThu.
  ///
  /// In en, this message translates to:
  /// **'Every Thu'**
  String get everyThu;

  /// No description provided for @everyFri.
  ///
  /// In en, this message translates to:
  /// **'Every Fri'**
  String get everyFri;

  /// No description provided for @everySat.
  ///
  /// In en, this message translates to:
  /// **'Every Sat'**
  String get everySat;

  /// No description provided for @everySun.
  ///
  /// In en, this message translates to:
  /// **'Every Sun'**
  String get everySun;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @noSchedulesFound.
  ///
  /// In en, this message translates to:
  /// **'No schedules found'**
  String get noSchedulesFound;

  /// No description provided for @deleteSchedules.
  ///
  /// In en, this message translates to:
  /// **'Delete schedules?'**
  String get deleteSchedules;

  /// No description provided for @deleteSchedulesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} schedules?'**
  String deleteSchedulesConfirm(int count);

  /// No description provided for @gal.
  ///
  /// In en, this message translates to:
  /// **'gal'**
  String get gal;

  /// No description provided for @addAsset.
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get addAsset;

  /// No description provided for @editAsset.
  ///
  /// In en, this message translates to:
  /// **'Edit Asset'**
  String get editAsset;

  /// No description provided for @assetType.
  ///
  /// In en, this message translates to:
  /// **'Asset Type (e.g., Dispenser, Bottle)'**
  String get assetType;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @deliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocation;

  /// No description provided for @setHomeLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Home Location'**
  String get setHomeLocation;

  /// No description provided for @workersWillBeNotified.
  ///
  /// In en, this message translates to:
  /// **'You will be notified when a worker is near your home'**
  String get workersWillBeNotified;

  /// No description provided for @requiredToReceiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'Required to receive proximity alerts'**
  String get requiredToReceiveAlerts;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @mustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'Must be between {min} and {max}'**
  String mustBeBetween(String min, String max);

  /// No description provided for @coordinatesTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: You can find your coordinates in Google Maps by long-pressing your home.'**
  String get coordinatesTip;

  /// No description provided for @cannotDeleteUserWithRecords.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete user with existing records. Please deactivate instead.'**
  String get cannotDeleteUserWithRecords;

  /// No description provided for @revenues.
  ///
  /// In en, this message translates to:
  /// **'Revenues'**
  String get revenues;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @outcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get outcome;

  /// No description provided for @requestCouponBook.
  ///
  /// In en, this message translates to:
  /// **'Request Coupon Book'**
  String get requestCouponBook;

  /// No description provided for @couponBookType.
  ///
  /// In en, this message translates to:
  /// **'Coupon Book Type'**
  String get couponBookType;

  /// No description provided for @physicalBook.
  ///
  /// In en, this message translates to:
  /// **'Physical Book'**
  String get physicalBook;

  /// No description provided for @requestPhysicalCouponBook.
  ///
  /// In en, this message translates to:
  /// **'Request physical coupon book'**
  String get requestPhysicalCouponBook;

  /// No description provided for @electronicBook.
  ///
  /// In en, this message translates to:
  /// **'Electronic Book'**
  String get electronicBook;

  /// No description provided for @buyDigitalCouponBook.
  ///
  /// In en, this message translates to:
  /// **'Buy digital coupon book online'**
  String get buyDigitalCouponBook;

  /// No description provided for @selectBookSize.
  ///
  /// In en, this message translates to:
  /// **'Select Book Size'**
  String get selectBookSize;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @howWillYouPay.
  ///
  /// In en, this message translates to:
  /// **'How will you pay?'**
  String get howWillYouPay;

  /// No description provided for @useCoupon.
  ///
  /// In en, this message translates to:
  /// **'Use Coupon'**
  String get useCoupon;

  /// No description provided for @deductFromMyCouponBook.
  ///
  /// In en, this message translates to:
  /// **'Deduct from my coupon book'**
  String get deductFromMyCouponBook;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @payWhenWaterArrives.
  ///
  /// In en, this message translates to:
  /// **'Pay when water arrives'**
  String get payWhenWaterArrives;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get requestSubmitted;

  /// No description provided for @stationIsOpen.
  ///
  /// In en, this message translates to:
  /// **'Station is open'**
  String get stationIsOpen;

  /// No description provided for @temporarilyClosed.
  ///
  /// In en, this message translates to:
  /// **'Temporarily closed'**
  String get temporarilyClosed;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get unknownStatus;

  /// No description provided for @couponRequests.
  ///
  /// In en, this message translates to:
  /// **'Coupon Requests'**
  String get couponRequests;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApproval;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'water'**
  String get water;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
