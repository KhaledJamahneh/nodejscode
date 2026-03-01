// lib/features/admin/presentation/screens/admin_deliveries_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/deliveries_provider.dart';
import '../providers/users_provider.dart';
import '../providers/requests_provider.dart';
import '../providers/admin_provider.dart';
import '../../data/models/delivery_model.dart';

class AdminDeliveriesScreen extends ConsumerStatefulWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  ConsumerState<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends ConsumerState<AdminDeliveriesScreen> {
  final Set<int> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(deliveriesListProvider);
    final filter = ref.watch(deliveriesFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    // Listen for status updates
    ref.listen(updateDeliveryStatusProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getMessage(next.error)),
            backgroundColor: AppTheme.iosRed,
          ),
        );
      } else if (next is AsyncData && previous is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deliveryStatusUpdated)),
        );
      }
    });

    // Listen for assignment updates
    ref.listen(assignWorkerToDeliveryProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getMessage(next.error)),
            backgroundColor: AppTheme.iosRed,
          ),
        );
      } else if (next is AsyncData && previous is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workerAssigned)),
        );
      }
    });

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: _isSelecting
              ? Text('${_selectedIds.length} selected')
              : Text(l10n.overview),
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          actions: [
            if (!_isSelecting) ...[
              IconButton(
                icon: Icon(
                  ref.watch(themeProvider) == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 22,
                ),
                onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              IconButton(
                icon: Text(
                  ref.watch(localeProvider).languageCode == 'en' ? 'ع' : 'En',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
              ),
            ],
            if (_isSelecting) ...[
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSelection,
                tooltip: 'Cancel',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _showBulkDeleteDialog(context),
                tooltip: 'Delete Selected',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) => _handleBulkAction(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pending',
                    child: Text('Mark as Pending'),
                  ),
                  const PopupMenuItem(
                    value: 'in_progress',
                    child: Text('Mark as In Progress'),
                  ),
                  const PopupMenuItem(
                    value: 'completed',
                    child: Text('Mark as Completed'),
                  ),
                  const PopupMenuItem(
                    value: 'cancelled',
                    child: Text('Mark as Cancelled'),
                  ),
                ],
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.refresh(deliveriesListProvider),
              ),
            ],
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.all),
              Tab(text: l10n.pending),
              Tab(text: l10n.inProgress),
              Tab(text: l10n.cancelled),
            ],
            onTap: (index) {
              String? status;
              switch (index) {
                case 0:
                  status = null;
                  break;
                case 1:
                  status = 'pending';
                  break;
                case 2:
                  status = 'in_progress';
                  break;
                case 3:
                  status = 'cancelled';
                  break;
              }
              ref.read(deliveriesFilterProvider.notifier).state =
                  filter.copyWith(status: status, clearStatus: status == null);
            },
          ),
        ),
        body: Column(
          children: [
            // Filters
            _buildFilters(context, ref, filter),

            // Statistics Summary
            deliveriesAsync
                    .whenData((deliveries) => _buildStats(context, deliveries))
                    .value ??
                const SizedBox.shrink(),

            // Deliveries List
            Expanded(
              child: deliveriesAsync.when(
                data: (deliveries) => deliveries.isEmpty
                    ? _buildEmptyState(context)
                    : _buildDeliveriesList(context, ref, deliveries),
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppTheme.iosRed),
                    const SizedBox(height: 16),
                    Text('${l10n.error}: ${error.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(deliveriesListProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickDeliveryDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quick Delivery'),
        backgroundColor: AppTheme.primary,
      ),
      ),
    );
  }

  Widget _buildFilters(
      BuildContext context, WidgetRef ref, DeliveriesFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border:
            Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('${l10n.filters}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    )),
                const SizedBox(width: 8),

                // Status Filter
                _buildFilterChip(
                  context: context,
                  label: filter.status == null
                      ? l10n.allStatus
                      : _getStatusDisplay(context, filter.status!),
                  selected: filter.status != null,
                  color: filter.status != null
                      ? StatusColors.getColor(filter.status!)
                      : null,
                  onTap: () => _showStatusFilter(context, ref, filter),
                ),
                const SizedBox(width: 8),

                // Date Filter
                _buildFilterChip(
                  context: context,
                  label: filter.startDate == null
                      ? l10n.allDates
                      : filter.startDate == filter.endDate
                          ? _formatFilterDate(context, filter.startDate!)
                          : '${_formatFilterDate(context, filter.startDate!)} - ${_formatFilterDate(context, filter.endDate!)}',
                  selected: filter.startDate != null,
                  onTap: () => _showDatePicker(context, ref, filter),
                ),
                const SizedBox(width: 8),

                // Today Quick Filter
                TextButton.icon(
                  onPressed: () {
                    final today = DateTime.now();
                    final dateStr = DateFormat('yyyy-MM-dd').format(today);
                    ref.read(deliveriesFilterProvider.notifier).state =
                        filter.copyWith(startDate: dateStr, endDate: dateStr);
                  },
                  icon: const Icon(Icons.today_rounded, size: 16),
                  label: Text(l10n.today),
                ),

                // Clear All
                if (filter.hasFilters)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(deliveriesFilterProvider.notifier).state =
                          DeliveriesFilter();
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: Text(l10n.clear),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool selected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (color?.withOpacity(0.1) ?? AppTheme.primary.withOpacity(0.1))
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? (color ?? AppTheme.primary) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? (color ?? AppTheme.primary)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded,
                  size: 16, color: color ?? AppTheme.primary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<Delivery> deliveries) {
    final l10n = AppLocalizations.of(context)!;
    final total = deliveries.length;
    final completed = deliveries.where((d) => d.isCompleted).length;
    final inProgress = deliveries.where((d) => d.isInProgress).length;
    final pending = deliveries.where((d) => d.isPending).length;
    final totalGallons =
        deliveries.fold<int>(0, (sum, d) => sum + d.gallonsDelivered);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(l10n.total, total.toString(),
              Icons.local_shipping_rounded, AppTheme.iosBlue),
          _buildStatItem(l10n.complete, completed.toString(),
              Icons.check_circle_rounded, AppTheme.iosGreen),
          _buildStatItem(l10n.inProgress, inProgress.toString(),
              Icons.delivery_dining_rounded, AppTheme.iosOrange),
          _buildStatItem(_getStatusDisplay(context, 'pending'),
              pending.toString(), Icons.schedule_rounded, AppTheme.iosGray),
          _buildStatItem(l10n.gallons, '${totalGallons}L',
              Icons.water_drop_rounded, AppTheme.iosTeal),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 10,
              color: AppTheme.iosGray,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDeliveriesList(
      BuildContext context, WidgetRef ref, List<Delivery> deliveries) {
    // Sort by date (newest first)
    final sortedDeliveries = List<Delivery>.from(deliveries)
      ..sort((a, b) => b.deliveryDate.compareTo(a.deliveryDate));

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(deliveriesListProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: sortedDeliveries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final delivery = sortedDeliveries[index];
          return _buildDeliveryCard(context, ref, delivery);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(
      BuildContext context, WidgetRef ref, Delivery delivery) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedIds.contains(delivery.id);

    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      color: isSelected ? AppTheme.primary.withOpacity(0.1) : null,
      onTap: () => _isSelecting
          ? _toggleSelection(delivery.id)
          : _showDeliveryDetails(context, delivery),
      onLongPress: () => _toggleSelection(delivery.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Selection Checkbox
              if (_isSelecting) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(delivery.id),
                ),
                const SizedBox(width: 8),
              ],
              // Status Badge and Edit Button
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          StatusColors.getColor(delivery.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          StatusColors.getIcon(delivery.status),
                          size: 14,
                          color: StatusColors.getColor(delivery.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusDisplay(context, delivery.status).toUpperCase(),
                          style: TextStyle(
                            color: StatusColors.getColor(delivery.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    onPressed: () => _showEditDeliveryDialog(context, ref, delivery),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Spacer(),

              // Gallons
              Text(
                '${delivery.gallonsDelivered}${l10n.gallons}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),

              // Actions Menu
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 20, color: AppTheme.iosGray),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_notifications_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.changeStatus),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'assign',
                    child: Row(
                      children: [
                        const Icon(Icons.person_add_alt_1_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.assignWorker),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.iosRed, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.delete,
                            style: const TextStyle(color: AppTheme.iosRed)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'status') {
                    _showStatusDialog(context, ref, delivery);
                  } else if (value == 'assign') {
                    _showAssignWorkerDialog(context, ref, delivery);
                  } else if (value == 'delete') {
                    _confirmDeleteDelivery(context, ref, delivery);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Client
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  size: 18, color: AppTheme.iosGray),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  delivery.clientName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Address
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 18, color: AppTheme.iosGray),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  delivery.clientAddress,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondaryLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (delivery.workerName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_shipping_rounded,
                    size: 18, color: AppTheme.iosGray),
                const SizedBox(width: 8),
                Text(
                  delivery.workerName,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryLight,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Footer - Times
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Delivery Date
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppTheme.iosGray),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(delivery.deliveryDate),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.iosGray),
                  ),
                ],
              ),

              // Actual Time (if completed)
              if (delivery.actualDeliveryTime != null)
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: AppTheme.iosGreen),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(delivery.actualDeliveryTime!),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.iosGreen,
                      ),
                    ),
                  ],
                )
              else if (delivery.scheduledTime != null)
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 14, color: AppTheme.iosOrange),
                    const SizedBox(width: 6),
                    Text(
                      delivery.scheduledTime!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.iosOrange,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 80, color: AppTheme.iosGray.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text(
            l10n.noActivity,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.iosGray),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(
      BuildContext context, WidgetRef ref, Delivery delivery) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.changeStatus),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['pending', 'in_progress', 'completed', 'cancelled']
                .map((status) {
              final isSelected = delivery.status == status;
              return ListTile(
                leading: Icon(
                  StatusColors.getIcon(status),
                  color: StatusColors.getColor(status),
                ),
                title: Text(
                  _getStatusDisplay(context, status),
                  style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppTheme.iosGreen)
                    : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(context, ref, delivery.id, status);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref,
      int deliveryId, String status) async {
    await ref
        .read(updateDeliveryStatusProvider.notifier)
        .updateStatus(deliveryId, status);
  }

  void _showAssignWorkerDialog(
      BuildContext context, WidgetRef ref, Delivery delivery) {
    final workersAsync = ref.read(workersListProvider);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.assignWorker),
        content: SizedBox(
          width: double.maxFinite,
          child: workersAsync.when(
            data: (workers) => workers.isEmpty
                ? Text(l10n.noActivity)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      final isAssigned = delivery.workerName ==
                          (worker['full_name'] ?? worker['username']);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.person_rounded,
                              color: AppTheme.primary),
                        ),
                        title: Text(worker['full_name'] ?? worker['username'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(worker['phone_number'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${worker['profile']['active_tasks_count'] ?? 0} Active',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: (worker['profile']['active_tasks_count'] ?? 0) > 3 
                                      ? AppTheme.iosOrange 
                                      : AppTheme.iosGreen,
                                  ),
                                ),
                                Text(
                                  '${worker['profile']['vehicle_current_gallons'] ?? 0}L left',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.iosGray),
                                ),
                              ],
                            ),
                            if (isAssigned) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_rounded,
                                  color: AppTheme.iosGreen),
                            ],
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          Navigator.pop(context);
                          _assignWorker(
                              ref, delivery.id, worker['profile']['id']);
                        },
                      );
                    },
                  ),
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: (error, _) => Text('Error: $error'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _assignWorker(
      WidgetRef ref, int deliveryId, int workerId) async {
    await ref
        .read(assignWorkerToDeliveryProvider.notifier)
        .assignWorker(deliveryId, workerId);
  }

  void _showStatusFilter(
      BuildContext context, WidgetRef ref, DeliveriesFilter filter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        margin: EdgeInsets.zero,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.iosGray4,
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                title: const Text('All Status',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: filter.status == null
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(deliveriesFilterProvider.notifier).state =
                      filter.copyWith(clearStatus: true);
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            ...['pending', 'in_progress', 'completed', 'cancelled'].map(
              (status) => ListTile(
                leading: Icon(
                  StatusColors.getIcon(status),
                  color: StatusColors.getColor(status),
                ),
                title: Text(_getStatusDisplay(context, status)),
                trailing: filter.status == status
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(deliveriesFilterProvider.notifier).state =
                      filter.copyWith(status: status);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ));
  }

  void _showDatePicker(
      BuildContext context, WidgetRef ref, DeliveriesFilter filter) async {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: Text(l10n.today),
              onTap: () {
                final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                ref.read(deliveriesFilterProvider.notifier).state = filter.copyWith(startDate: today, endDate: today);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.singleDate),
              onTap: () async {
                Navigator.pop(context);
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: filter.startDate != null ? DateTime.parse(filter.startDate!) : DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (selectedDate != null) {
                  final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                  ref.read(deliveriesFilterProvider.notifier).state = filter.copyWith(startDate: dateStr, endDate: dateStr);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: Text(l10n.dateRange),
              onTap: () async {
                Navigator.pop(context);
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (range != null) {
                  ref.read(deliveriesFilterProvider.notifier).state = filter.copyWith(
                    startDate: DateFormat('yyyy-MM-dd').format(range.start),
                    endDate: DateFormat('yyyy-MM-dd').format(range.end),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliveryDetails(BuildContext context, Delivery delivery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(24),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: AppTheme.iosGray4,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.delivery} #${delivery.id}',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontSize: 28),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                        backgroundColor: AppTheme.iosGray6),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildDetailRow(
                  l10n.client, delivery.clientName, Icons.person_rounded),
              _buildDetailRow(
                  l10n.phone, delivery.clientPhone, Icons.phone_rounded),
              _buildDetailRow(
                  l10n.address, delivery.clientAddress, Icons.location_on_rounded),
              const Divider(height: 32),
              _buildDetailRow(
                  l10n.worker, delivery.workerName, Icons.local_shipping_rounded),
              _buildDetailRow(l10n.gallonsDelivered,
                  '${delivery.gallonsDelivered}L', Icons.water_drop_rounded),
              _buildDetailRow(
                  l10n.emptyGallonsCollected,
                  '${delivery.gallonsReturned ?? 0}L',
                  Icons.delete_outline_rounded),
              const Divider(height: 32),
              _buildDetailRow(
                  l10n.status, _getStatusDisplay(context, delivery.status), Icons.info_outline_rounded),
              _buildDetailRow(l10n.date, _formatDate(delivery.deliveryDate),
                  Icons.calendar_today_rounded),
              if (delivery.scheduledTime != null)
                _buildDetailRow(l10n.scheduledTime, delivery.scheduledTime!,
                    Icons.schedule_rounded),
              if (delivery.actualDeliveryTime != null)
                _buildDetailRow(
                    l10n.completedAt,
                    _formatDateTime(delivery.actualDeliveryTime!),
                    Icons.check_circle_outline_rounded),
              if (delivery.notes != null && delivery.notes!.isNotEmpty)
                _buildDetailRow(
                    'Notes', delivery.notes!, Icons.note_alt_outlined),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.iosGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatFilterDate(BuildContext context, String dateStr) {
    try {
      final l10n = AppLocalizations.of(context)!;
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return l10n.today;
      }
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusDisplay(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'in_progress':
        return l10n.inProgress;
      case 'completed':
        return l10n.completed;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return status;
    }
  }

  void _confirmDeleteDelivery(
      BuildContext context, WidgetRef ref, Delivery delivery) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('${l10n.deleteConfirmation} ${l10n.delivery}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(adminServiceProvider).deleteDelivery(delivery.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(deliveriesListProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.deliveryDeleted),
                      backgroundColor: AppTheme.iosGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: AppTheme.iosRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.iosRed),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deliveries'),
        content: Text('Delete ${_selectedIds.length} selected deliveries?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.iosRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete() async {
    for (final id in _selectedIds) {
      await ref.read(adminServiceProvider).deleteDelivery(id);
    }
    _clearSelection();
    ref.invalidate(deliveriesListProvider);
  }

  Future<void> _handleBulkAction(BuildContext context, String status) async {
    for (final id in _selectedIds) {
      await ref.read(updateDeliveryStatusProvider.notifier).updateStatus(id, status);
    }
    _clearSelection();
    ref.invalidate(deliveriesListProvider);
  }

  void _showQuickDeliveryDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    int gallons = 50;
    int emptyGallons = 0;
    int paidCoupons = 0;
    double paidAmount = 0;
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    int? selectedClientId;
    int? selectedWorkerId;
    String? selectedClientSubscription;
    int? remainingCoupons;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isCouponBook = selectedClientSubscription == 'coupon_book';
          final isCash = selectedClientSubscription == 'cash' || selectedClientSubscription == 'pay_as_you_go';
          
          return AlertDialog(
            title: Text(l10n.quickDelivery),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder(
                    future: ref.read(adminServiceProvider).getUsers(role: 'client', limit: 1000),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final clients = snapshot.data!.where((c) => c['profile'] != null).toList();
                      return DropdownButtonFormField<int>(
                        value: selectedClientId,
                        decoration: InputDecoration(labelText: '${l10n.client} *'),
                        items: clients.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
                          value: c['profile']['id'],
                          child: Text('${c['profile']['full_name']} (${c['username']})'),
                        )).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedClientId = v;
                            final client = clients.firstWhere((c) => c['profile']['id'] == v);
                            selectedClientSubscription = client['profile']['subscription_type'];
                            remainingCoupons = client['profile']['remaining_coupons'] ?? 0;
                            paidCoupons = 0;
                            if (!isCouponBook) {
                              paidAmount = gallons * 10.0;
                              priceController.text = paidAmount.toStringAsFixed(2);
                            }
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: ref.read(adminServiceProvider).getUsers(role: 'delivery_worker', limit: 1000),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final workers = snapshot.data!;
                      return DropdownButtonFormField<int>(
                        value: selectedWorkerId,
                        decoration: InputDecoration(labelText: '${l10n.worker} *'),
                        items: workers.map<DropdownMenuItem<int>>((w) => DropdownMenuItem<int>(
                          value: w['profile']?['id'],
                          child: Text('${w['profile']?['full_name'] ?? w['username']}'),
                        )).toList(),
                        onChanged: (v) => setState(() => selectedWorkerId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Gallons Delivered
                  Text(l10n.gallons, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        onPressed: () => setState(() {
                          if (gallons > 0) {
                            gallons--;
                            if (isCash) {
                              paidAmount = gallons * 10.0;
                              priceController.text = paidAmount.toStringAsFixed(2);
                            }
                          }
                        }),
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.iosGray4),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('$gallons', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                      ),
                      IconButton.filled(
                        onPressed: () => setState(() {
                          gallons++;
                          if (isCash) {
                            paidAmount = gallons * 10.0;
                            priceController.text = paidAmount.toStringAsFixed(2);
                          }
                        }),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Empty Gallons
                  Text(l10n.emptyGallons, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        onPressed: () => setState(() { if (emptyGallons > 0) emptyGallons--; }),
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.iosGray4),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('$emptyGallons', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                      ),
                      IconButton.filled(
                        onPressed: () => setState(() => emptyGallons++),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Coupon Book specific
                  if (isCouponBook) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Paid Coupons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${remainingCoupons ?? 0} remaining',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          onPressed: () => setState(() { if (paidCoupons > 0) paidCoupons--; }),
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(backgroundColor: AppTheme.iosGray4),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text('$paidCoupons', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                        ),
                        IconButton.filled(
                          onPressed: () => setState(() { if (paidCoupons < (remainingCoupons ?? 0)) paidCoupons++; }),
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                  
                  // Cash specific
                  if (isCash) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  prefixText: '₪ ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 8),
                              TextField(
                                onChanged: (v) => setState(() => paidAmount = double.tryParse(v) ?? 0),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: paidAmount.toStringAsFixed(2),
                                  prefixText: '₪ ',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(labelText: '${l10n.notes} (${l10n.optional})'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  if (selectedClientId == null || selectedWorkerId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.pleaseSelectClientAndWorker)),
                    );
                    return;
                  }
                  try {
                    final data = {
                      'client_id': selectedClientId,
                      'worker_id': selectedWorkerId,
                      'gallons_delivered': gallons,
                      'empty_gallons_returned': emptyGallons,
                      'notes': notesController.text.isEmpty ? null : notesController.text,
                    };
                    if (isCouponBook) {
                      data['paid_coupons'] = paidCoupons;
                    } else if (isCash) {
                      data['custom_amount'] = double.tryParse(priceController.text) ?? (gallons * 10.0);
                      data['is_paid'] = paidAmount > 0;
                    }
                    await ref.read(adminServiceProvider).createQuickDelivery(data);
                    ref.invalidate(deliveriesListProvider);
                    ref.invalidate(usersProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.deliveryCreatedSuccessfully)),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: AppTheme.iosRed),
                      );
                    }
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDeliveryDialog(BuildContext context, WidgetRef ref, dynamic delivery) {
    final gallonsController = TextEditingController(text: delivery.gallonsDelivered.toString());
    final emptyGallonsController = TextEditingController(text: (delivery.gallonsReturned ?? 0).toString());
    final notesController = TextEditingController(text: delivery.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Delivery'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gallonsController,
                decoration: const InputDecoration(labelText: 'Gallons Delivered *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emptyGallonsController,
                decoration: const InputDecoration(labelText: 'Empty Gallons Returned'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(adminServiceProvider).updateDelivery(delivery.id, {
                  'gallons_delivered': int.parse(gallonsController.text),
                  'empty_gallons_returned': int.parse(emptyGallonsController.text),
                  'notes': notesController.text.isEmpty ? null : notesController.text,
                });
                ref.invalidate(deliveriesListProvider);
                ref.invalidate(usersProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delivery updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.iosRed),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
