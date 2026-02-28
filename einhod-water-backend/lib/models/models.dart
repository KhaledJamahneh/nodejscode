enum UserRole { client, deliveryWorker, stationWorker, admin, owner }

enum DeliveryPriority { urgent, midUrgent, normal }

enum DeliveryStatus { pending, inProgress, completed, skipped }

enum NotificationLevel { important, midImportance, normal }

enum PaymentMethod { cash, card }

enum ExpensePaymentMethod { myPocket, company, unpaid }

class UserModel {
  final String id;
  final String username;
  final String name;
  final String phone;
  final UserRole role;
  final String? address;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.phone,
    required this.role,
    this.address,
  });
}

class ClientModel extends UserModel {
  final String subscriptionType;
  final int couponsRemaining;
  final int totalCoupons;
  final DateTime subscriptionExpiry;
  final double outstandingDebt;

  ClientModel({
    required super.id,
    required super.username,
    required super.name,
    required super.phone,
    required super.address,
    required this.subscriptionType,
    required this.couponsRemaining,
    required this.totalCoupons,
    required this.subscriptionExpiry,
    required this.outstandingDebt,
  }) : super(role: UserRole.client);

  int get daysUntilExpiry =>
      subscriptionExpiry.difference(DateTime.now()).inDays;
  bool get isExpiringSoon => daysUntilExpiry <= 7;
  bool get isExpired => subscriptionExpiry.isBefore(DateTime.now());
  bool get hasDebt => outstandingDebt > 0;
}

class DeliveryModel {
  final String id;
  final String clientId;
  final String clientName;
  final String address;
  final int gallons;
  final DeliveryPriority priority;
  final DeliveryStatus status;
  final DateTime date;
  final String? workerId;
  final String? notes;

  DeliveryModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.address,
    required this.gallons,
    required this.priority,
    required this.status,
    required this.date,
    this.workerId,
    this.notes,
  });
}

class WorkerModel extends UserModel {
  final String jobTitle;
  final bool isOnShift;
  final bool gpsActive;
  final int gallonsRemaining;
  final int todayCompletedDeliveries;
  final int totalDeliveriesToday;
  final int pendingExpenses;
  final double salary;

  WorkerModel({
    required super.id,
    required super.username,
    required super.name,
    required super.phone,
    required super.role,
    required this.jobTitle,
    required this.isOnShift,
    required this.gpsActive,
    required this.gallonsRemaining,
    required this.todayCompletedDeliveries,
    required this.totalDeliveriesToday,
    required this.pendingExpenses,
    required this.salary,
  });
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationLevel level;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.level,
    required this.timestamp,
    required this.isRead,
    this.actionLabel,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class FillingSession {
  final int sessionNumber;
  final int gallonsFilled;
  final DateTime time;

  FillingSession({
    required this.sessionNumber,
    required this.gallonsFilled,
    required this.time,
  });
}

class ExpenseModel {
  final String id;
  final String workerId;
  final double amount;
  final String merchantName;
  final String description;
  final DateTime date;
  final ExpensePaymentMethod paymentMethod;
  final bool hasReceipt;
  final bool? approved;

  ExpenseModel({
    required this.id,
    required this.workerId,
    required this.amount,
    required this.merchantName,
    required this.description,
    required this.date,
    required this.paymentMethod,
    required this.hasReceipt,
    this.approved,
  });
}

// Mock data helpers
class MockData {
  static ClientModel get sampleClient => ClientModel(
        id: 'c1',
        username: 'ahmed.khalil',
        name: 'Ahmed Khalil',
        phone: '+962791234567',
        address: '42 Al-Madina St, Amman',
        subscriptionType: 'Coupon Book',
        couponsRemaining: 47,
        totalCoupons: 60,
        subscriptionExpiry: DateTime.now().add(const Duration(days: 7)),
        outstandingDebt: 15.5,
      );

  static List<DeliveryModel> get recentDeliveries => [
        DeliveryModel(
          id: 'd1',
          clientId: 'c1',
          clientName: 'Ahmed Khalil',
          address: '42 Al-Madina St',
          gallons: 3,
          priority: DeliveryPriority.normal,
          status: DeliveryStatus.completed,
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DeliveryModel(
          id: 'd2',
          clientId: 'c1',
          clientName: 'Ahmed Khalil',
          address: '42 Al-Madina St',
          gallons: 2,
          priority: DeliveryPriority.midUrgent,
          status: DeliveryStatus.completed,
          date: DateTime.now().subtract(const Duration(days: 3)),
        ),
        DeliveryModel(
          id: 'd3',
          clientId: 'c1',
          clientName: 'Ahmed Khalil',
          address: '42 Al-Madina St',
          gallons: 5,
          priority: DeliveryPriority.urgent,
          status: DeliveryStatus.completed,
          date: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];

  static List<DeliveryModel> get workerDeliveries => [
        DeliveryModel(
          id: 'wd1',
          clientId: 'c2',
          clientName: 'Sara Hassan',
          address: '17 Zahran St, Amman',
          gallons: 3,
          priority: DeliveryPriority.urgent,
          status: DeliveryStatus.pending,
          date: DateTime.now(),
        ),
        DeliveryModel(
          id: 'wd2',
          clientId: 'c3',
          clientName: 'Omar Nasser',
          address: '8 Mecca St, Amman',
          gallons: 2,
          priority: DeliveryPriority.midUrgent,
          status: DeliveryStatus.inProgress,
          date: DateTime.now(),
        ),
        DeliveryModel(
          id: 'wd3',
          clientId: 'c4',
          clientName: 'Layla Ali',
          address: '55 Hussein St, Amman',
          gallons: 4,
          priority: DeliveryPriority.normal,
          status: DeliveryStatus.completed,
          date: DateTime.now(),
        ),
        DeliveryModel(
          id: 'wd4',
          clientId: 'c5',
          clientName: 'Tariq Mahmoud',
          address: '22 Rainbow St, Amman',
          gallons: 1,
          priority: DeliveryPriority.normal,
          status: DeliveryStatus.pending,
          date: DateTime.now(),
        ),
      ];

  static List<NotificationModel> get notifications => [
        NotificationModel(
          id: 'n1',
          title: 'Subscription Expiring Soon',
          body:
              'Your coupon book expires in 7 days. Renew now to avoid interruption.',
          level: NotificationLevel.important,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
          actionLabel: 'Renew',
        ),
        NotificationModel(
          id: 'n2',
          title: 'Delivery Confirmed',
          body: '3 gallons delivered to your address successfully.',
          level: NotificationLevel.normal,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
        ),
        NotificationModel(
          id: 'n3',
          title: 'Outstanding Balance',
          body:
              'You have an outstanding balance of ₪15.50. Please settle at your earliest convenience.',
          level: NotificationLevel.midImportance,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
          actionLabel: 'Pay Now',
        ),
      ];

  static List<WorkerModel> get workers => [
        WorkerModel(
          id: 'w1',
          username: 'khaled.driver',
          name: 'Khaled Mansour',
          phone: '+962781234567',
          role: UserRole.deliveryWorker,
          jobTitle: 'Delivery Profile',
          isOnShift: true,
          gpsActive: true,
          gallonsRemaining: 47,
          todayCompletedDeliveries: 8,
          totalDeliveriesToday: 14,
          pendingExpenses: 2,
          salary: 450,
        ),
        WorkerModel(
          id: 'w2',
          username: 'yasser.driver',
          name: 'Yasser Qasim',
          phone: '+962771234567',
          role: UserRole.deliveryWorker,
          jobTitle: 'Delivery Profile',
          isOnShift: true,
          gpsActive: false,
          gallonsRemaining: 12,
          todayCompletedDeliveries: 5,
          totalDeliveriesToday: 10,
          pendingExpenses: 0,
          salary: 420,
        ),
        WorkerModel(
          id: 'w3',
          username: 'fadi.station',
          name: 'Fadi Karim',
          phone: '+962761234567',
          role: UserRole.stationWorker,
          jobTitle: 'Onsite Worker Profile',
          isOnShift: false,
          gpsActive: false,
          gallonsRemaining: 0,
          todayCompletedDeliveries: 0,
          totalDeliveriesToday: 0,
          pendingExpenses: 1,
          salary: 380,
        ),
        // Additional workers from data process
        WorkerModel(
          id: 'w4',
          username: 'name.delivery',
          name: '[Name]',
          phone: '+962790000000',
          role: UserRole.deliveryWorker,
          jobTitle: 'Delivery Profile',
          isOnShift: true,
          gpsActive: true,
          gallonsRemaining: 50,
          todayCompletedDeliveries: 0,
          totalDeliveriesToday: 0,
          pendingExpenses: 0,
          salary: 400,
        ),
        WorkerModel(
          id: 'w5',
          username: 'name.onsite',
          name: '[Name]',
          phone: '+962790000001',
          role: UserRole.stationWorker,
          jobTitle: 'Onsite Worker Profile',
          isOnShift: true,
          gpsActive: false,
          gallonsRemaining: 0,
          todayCompletedDeliveries: 0,
          totalDeliveriesToday: 0,
          pendingExpenses: 0,
          salary: 350,
        ),
      ];

  static List<FillingSession> get fillingSessions => [
        FillingSession(
            sessionNumber: 1,
            gallonsFilled: 120,
            time: DateTime.now().subtract(const Duration(hours: 5))),
        FillingSession(
            sessionNumber: 2,
            gallonsFilled: 110,
            time: DateTime.now().subtract(const Duration(hours: 3))),
        FillingSession(
            sessionNumber: 3,
            gallonsFilled: 110,
            time: DateTime.now().subtract(const Duration(hours: 1))),
      ];
}
