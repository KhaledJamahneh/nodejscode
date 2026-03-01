import 'package:flutter/material.dart';
import 'package:einhod_water/core/theme/app_theme.dart';
import 'package:einhod_water/core/widgets/widgets.dart';
import '../../models/models.dart';

class StationDashboardScreen extends StatefulWidget {
  final WorkerModel worker;
  const StationDashboardScreen({super.key, required this.worker});

  @override
  State<StationDashboardScreen> createState() => _StationDashboardScreenState();
}

class _StationDashboardScreenState extends State<StationDashboardScreen> {
  int _selectedTab = 0;
  StationStatus _stationStatus = StationStatus.open;
  List<FillingSession> _sessions = List.from(MockData.fillingSessions);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _StationTab(
        status: _stationStatus,
        sessions: _sessions,
        onStatusChange: _confirmStatusChange,
        onNewSession: _showNewSessionSheet,
      ),
      _FillLogTab(sessions: _sessions),
      const _StationExpensesTab(),
      _StationProfileTab(worker: widget.worker),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: EinhodAppBar(
        title: 'Station Dashboard',
        notificationCount: 1,
      ),
      body: IndexedStack(index: _selectedTab, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: AppColors.white, boxShadow: AppShadows.elevated),
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.water_drop_outlined),
                activeIcon: Icon(Icons.water_drop),
                label: 'Station'),
            BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: 'Fill Log'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_outlined),
                activeIcon: Icon(Icons.receipt),
                label: 'Expenses'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _confirmStatusChange(StationStatus newStatus) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title:
            Text(l10n.changeStationStatus, style: AppTypography.headlineMedium),
        content: Text(
          'Are you sure you want to set the station to "${_statusLabel(newStatus)}"? This will be visible to all delivery workers and admins.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              setState(() => _stationStatus = newStatus);
              Navigator.pop(context);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  String _statusLabel(StationStatus s) {
    switch (s) {
      case StationStatus.open:
        return 'Open';
      case StationStatus.temporarilyClosed:
        return 'Temporarily Closed';
      case StationStatus.closedUntilTomorrow:
        return 'Closed Until Tomorrow';
    }
  }

  void _showNewSessionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewSessionSheet(
        nextNumber: _sessions.length + 1,
        onSubmit: (session) => setState(() => _sessions.insert(0, session)),
      ),
    );
  }
}

// ─── Station Tab ──────────────────────────────────────────────────────────────
class _StationTab extends StatelessWidget {
  final StationStatus status;
  final List<FillingSession> sessions;
  final ValueChanged<StationStatus> onStatusChange;
  final VoidCallback onNewSession;

  const _StationTab({
    required this.status,
    required this.sessions,
    required this.onStatusChange,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalToday = sessions.fold<int>(0, (sum, s) => sum + s.gallonsFilled);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              _StationStatusCard(
                  status: status, onStatusChange: onStatusChange),
              const SizedBox(height: AppSpacing.base),

              // Daily total
              EinhodCard(
                child: Row(
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.todaysTotal,
                            style: AppTypography.bodyMedium),
                        Text('$totalToday ${l10n.gallons}',
                            style: AppTypography.displayMedium
                                .copyWith(color: AppColors.oceanBlue)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              SectionHeader(title: 'Today\'s Sessions'),
              const SizedBox(height: AppSpacing.md),

              if (sessions.isEmpty)
                const EmptyState(
                    emoji: '🫙',
                    title: 'No filling sessions today',
                    subtitle: 'Tap + to start a new session')
              else
                ...sessions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _SessionCard(session: s),
                    )),

              const SizedBox(height: 100), // space for FAB
            ],
          ),
        ),

        // FAB
        Positioned(
          right: AppSpacing.base,
          bottom: AppSpacing.xl,
          child: GestureDetector(
            onTap: onNewSession,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: AppShadows.button),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.newFillingSession,
                      style: AppTypography.labelLarge
                          .copyWith(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Station Status Card ──────────────────────────────────────────────────────
class _StationStatusCard extends StatelessWidget {
  final StationStatus status;
  final ValueChanged<StationStatus> onStatusChange;

  const _StationStatusCard(
      {required this.status, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final statusConfig = {
      StationStatus.open: (
        'Open / مفتوح',
        AppColors.success,
        AppColors.openGreen,
        Icons.check_circle
      ),
      StationStatus.temporarilyClosed: (
        'Temporarily Closed / مغلق مؤقتاً',
        AppColors.warning,
        AppColors.closedOrange,
        Icons.pause_circle
      ),
      StationStatus.closedUntilTomorrow: (
        'Closed Until Tomorrow / مغلق حتى الغد',
        AppColors.danger,
        AppColors.closedRed,
        Icons.cancel
      ),
    };

    final config = statusConfig[status]!;

    return Container(
      decoration: BoxDecoration(
        color: config.$3,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: config.$2.withOpacity(0.3), width: 2),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.$4, color: config.$2, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(config.$1,
                  style:
                      AppTypography.headlineMedium.copyWith(color: config.$2)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Change Status:', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: StationStatus.values.map((s) {
              final isActive = s == status;
              final sc = statusConfig[s]!;
              return GestureDetector(
                onTap: isActive ? null : () => onStatusChange(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isActive ? sc.$2 : AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: sc.$2, width: 1.5),
                  ),
                  child: Text(
                    s == StationStatus.open
                        ? 'Open'
                        : s == StationStatus.temporarilyClosed
                            ? 'Temp. Closed'
                            : 'Closed',
                    style: AppTypography.bodySmall.copyWith(
                      color: isActive ? Colors.white : sc.$2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Session Card ─────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final FillingSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return EinhodCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Center(
                child: Text('#${session.sessionNumber}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session #${session.sessionNumber}',
                    style: AppTypography.titleMedium),
                Text(
                    '${session.time.hour.toString().padLeft(2, '0')}:${session.time.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${session.gallonsFilled}',
                  style: AppTypography.headlineMedium
                      .copyWith(color: AppColors.oceanBlue)),
              Text('gallons', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── New Session Sheet ────────────────────────────────────────────────────────
class _NewSessionSheet extends StatefulWidget {
  final int nextNumber;
  final ValueChanged<FillingSession> onSubmit;

  const _NewSessionSheet({required this.nextNumber, required this.onSubmit});

  @override
  State<_NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends State<_NewSessionSheet> {
  late int _sessionNumber;
  int _gallons = 100;

  @override
  void initState() {
    super.initState();
    _sessionNumber = widget.nextNumber;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.full))),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.newFillingSessionTitle,
              style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.sessionNumberLabel, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      initialValue: '$_sessionNumber',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() =>
                          _sessionNumber = int.tryParse(v) ?? _sessionNumber),
                      decoration: const InputDecoration(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.gallonsFilled, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _gallons > 0
                              ? setState(() => _gallons -= 10)
                              : null,
                          child: Container(
                              width: 40,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border:
                                      Border.all(color: AppColors.inputBorder)),
                              child: const Icon(Icons.remove, size: 18)),
                        ),
                        Expanded(
                            child: Center(
                                child: Text('$_gallons',
                                    style: AppTypography.headlineLarge.copyWith(
                                        color: AppColors.oceanBlue)))),
                        GestureDetector(
                          onTap: () => setState(() => _gallons += 10),
                          child: Container(
                              width: 40,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: AppColors.oceanBlue,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm)),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 18)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Mark Complete / إنهاء',
            onTap: () {
              widget.onSubmit(FillingSession(
                  sessionNumber: _sessionNumber,
                  gallonsFilled: _gallons,
                  time: DateTime.now()));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Fill Log Tab ─────────────────────────────────────────────────────────────
class _FillLogTab extends StatelessWidget {
  final List<FillingSession> sessions;

  const _FillLogTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const EmptyState(emoji: '🫙', title: 'No filling sessions today');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
    );
  }
}

// ─── Station Expenses Tab ─────────────────────────────────────────────────────
class _StationExpensesTab extends StatelessWidget {
  const _StationExpensesTab();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      emoji: '🧾',
      title: 'No expenses submitted yet',
    );
  }
}

// ─── Station Profile Tab ──────────────────────────────────────────────────────
class _StationProfileTab extends StatelessWidget {
  final WorkerModel worker;
  const _StationProfileTab({required this.worker});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: EinhodCard(
        child: Column(
          children: [
            CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.oceanBlue,
                child: Text(
                    worker.name.split(' ').map((n) => n[0]).take(2).join(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700))),
            const SizedBox(height: AppSpacing.md),
            Text(worker.name, style: AppTypography.headlineMedium),
            Text(worker.jobTitle, style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
