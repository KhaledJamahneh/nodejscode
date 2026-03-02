// lib/features/admin/presentation/screens/admin_requests_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/requests_provider.dart';
import '../../data/models/request_model.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const AdminRequestsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
    _tabController.addListener(() {
      if (_selectedIds.isNotEmpty) {
        setState(() => _selectedIds.clear());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    final requestsAsync = ref.watch(requestsListProvider);
    final filter = ref.watch(requestsFilterProvider);
    final couponFilter = ref.watch(couponRequestsFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isSelecting
            ? Text('${_selectedIds.length} selected')
            : Text(l10n.requests),
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.iosGray,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: l10n.active),
            Tab(text: l10n.cancelled),
            Tab(text: l10n.coupons),
          ],
        ),
        actions: [
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
              itemBuilder: (context) {
                final isCouponTab = _tabController.index == 2;
                return [
                  const PopupMenuItem(
                    value: 'pending',
                    child: Text('Mark as Pending'),
                  ),
                  if (isCouponTab)
                    const PopupMenuItem(
                      value: 'approved',
                      child: Text('Mark as Approved'),
                    ),
                  if (!isCouponTab)
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
                ];
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.invalidate(requestsListProvider);
                ref.invalidate(adminCouponBookRequestsProvider);
              },
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(context, ref, filter, couponFilter),

          // Requests List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Tab
                _buildRequestView(context, ref, requestsAsync, false),
                // Cancelled Tab
                _buildRequestView(context, ref, requestsAsync, true),
                // Coupon Books Tab
                _buildCouponRequestsView(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponRequestsView(BuildContext context, WidgetRef ref) {
    final couponRequestsAsync = ref.watch(adminCouponBookRequestsProvider);
    final l10n = AppLocalizations.of(context)!;

    return couponRequestsAsync.when(
      data: (requests) {
        return requests.isEmpty
            ? _buildEmptyState(context)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(adminCouponBookRequestsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildCouponBookRequestCard(context, ref, request);
                  },
                ),
              );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.iosRed),
            const SizedBox(height: 16),
            Text('${l10n.error}: ${error.toString()}', style: const TextStyle(color: AppTheme.iosGray)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminCouponBookRequestsProvider),
              child: Text(l10n.update),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponBookRequestCard(BuildContext context, WidgetRef ref, Map<String, dynamic> request) {
    final l10n = AppLocalizations.of(context)!;
    final status = request['status'] ?? 'pending';
    final statusColor = status == 'pending' ? AppTheme.midUrgentOrange :
                       status == 'approved' ? AppTheme.iosBlue :
                       status == 'assigned' ? AppTheme.iosIndigo :
                       status == 'completed' ? AppTheme.successGreen : AppTheme.iosGray;
    
    final isSelected = _selectedIds.contains(request['id']);

    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      color: isSelected ? AppTheme.primary.withOpacity(0.1) : null,
      onTap: () => _isSelecting
          ? _toggleSelection(request['id'])
          : _showCouponRequestDetails(context, ref, request),
      onLongPress: () => _toggleSelection(request['id']),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isSelecting) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(request['id']),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusDisplay(context, status).toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '₪${request['total_price']}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.iosGray, size: 20),
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDeleteCouponRequest(context, ref, request['id'], request['client_name']);
                  } else if (value == 'status') {
                    _showCouponStatusDialog(context, ref, request);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_notifications_outlined, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.changeStatus),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: AppTheme.iosRed, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.delete, style: const TextStyle(color: AppTheme.iosRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  request['book_type'] == 'physical' ? Icons.menu_book_rounded : Icons.qr_code_2_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request['client_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                    Text(
                      '${request['book_size']} ${l10n.pages} • ${request['book_type']}',
                      style: const TextStyle(color: AppTheme.iosGray, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.iosGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${request['client_address']}',
                  style: const TextStyle(color: AppTheme.iosGray, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.iosGray),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(request['created_at']),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.iosGray),
                    ),
                  ],
                ),
              ),
              if (request['worker_name'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.iosGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: AppTheme.iosGreen),
                      const SizedBox(width: 6),
                      Text(
                        request['worker_name'],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.iosGreen),
                      ),
                    ],
                  ),
                )
              else if (request['book_type'] == 'physical' && request['status'] != 'cancelled' && request['status'] != 'completed')
                ElevatedButton.icon(
                  onPressed: () => _showAssignWorkerDialogForCoupon(context, ref, request),
                  icon: const Icon(Icons.assignment_ind_rounded, size: 16),
                  label: Text(l10n.assignWorker),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCouponRequestDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> request) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
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
                      '${l10n.coupons} #${request['id']}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.iosGray6),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildDetailRow(l10n.client, request['client_name'], Icons.person_rounded),
              _buildDetailRow(l10n.phone, request['client_phone'] ?? 'N/A', Icons.phone_rounded),
              _buildDetailRow(l10n.address, request['client_address'], Icons.location_on_rounded),
              const Divider(height: 32),
              _buildDetailRow(l10n.type, request['book_type'].toString().toUpperCase(), Icons.category_rounded),
              _buildDetailRow(l10n.coupons, '${request['book_size']} ${l10n.pages}', Icons.menu_book_rounded),
              _buildDetailRow(l10n.price, '₪${request['total_price']}', Icons.payments_rounded),
              _buildDetailRow(l10n.status, _getStatusDisplay(context, request['status']), Icons.info_outline_rounded),
              _buildDetailRow(l10n.date, _formatDate(request['created_at']), Icons.calendar_today_rounded),
              if (request['worker_name'] != null)
                _buildDetailRow(l10n.worker, request['worker_name'], Icons.person_pin_circle_rounded),
            ],
          ),
        ),
      ),
    );
  }

  void _showCouponStatusDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> request) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.changeStatus),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['pending', 'approved', 'assigned', 'completed', 'cancelled'].map((status) {
              final isSelected = request['status'] == status;
              return ListTile(
                leading: Icon(
                  StatusColors.getIcon(status),
                  color: status == 'approved' ? AppTheme.iosBlue :
                         status == 'assigned' ? AppTheme.iosIndigo :
                         StatusColors.getColor(status),
                ),
                title: Text(
                  _getStatusDisplay(context, status),
                  style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
                trailing: isSelected ? const Icon(Icons.check_rounded, color: AppTheme.iosGreen) : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(context);
                  _updateCouponRequestStatus(context, ref, request['id'], status);
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

  Future<void> _updateCouponRequestStatus(BuildContext context, WidgetRef ref, int requestId, String status) async {
    await ref.read(updateCouponBookRequestStatusProvider.notifier).updateStatus(requestId, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.statusUpdated)),
      );
    }
  }

  Future<void> _confirmDeleteCouponRequest(BuildContext context, WidgetRef ref, int requestId, String clientName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteRequestConfirm(clientName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.iosRed),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(deleteCouponRequestProvider.notifier).deleteRequest(requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.requestDeleted)),
        );
      }
    }
  }

  void _showAssignWorkerDialogForCoupon(BuildContext context, WidgetRef ref, Map<String, dynamic> request) {
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
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.person_rounded, color: AppTheme.primary),
                        ),
                        title: Text(worker['username']),
                        subtitle: Text(worker['phone_number']),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${worker['profile']['active_tasks_count']} Active',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (worker['profile']['active_tasks_count'] ?? 0) > 3 
                                  ? AppTheme.iosOrange 
                                  : AppTheme.iosGreen,
                              ),
                            ),
                            Text(
                              '${worker['profile']['vehicle_current_gallons']}L left',
                              style: const TextStyle(fontSize: 10, color: AppTheme.iosGray),
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () async {
                          Navigator.pop(context);
                          await _assignWorkerForCoupon(context, ref, request['id'], worker['profile']['id']);
                        },
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator.adaptive()),
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

  Future<void> _assignWorkerForCoupon(BuildContext context, WidgetRef ref, int requestId, int workerId) async {
    await ref.read(assignCouponBookWorkerProvider.notifier).assignWorker(requestId, workerId);

    final state = ref.read(assignCouponBookWorkerProvider);
    final l10n = AppLocalizations.of(context)!;
    if (context.mounted) {
      state.when(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.workerAssigned)),
          );
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppTheme.iosRed,
            ),
          );
        },
      );
    }
  }

  Widget _buildRequestView(BuildContext context, WidgetRef ref,
      AsyncValue<List<DeliveryRequest>> requestsAsync, bool showCancelled) {
    final l10n = AppLocalizations.of(context)!;
    return requestsAsync.when(
      data: (requests) {
        final filteredRequests = requests.where((r) {
          if (showCancelled) {
            return r.status == 'cancelled';
          } else {
            return r.status != 'cancelled';
          }
        }).toList();

        return filteredRequests.isEmpty
            ? _buildEmptyState(context)
            : _buildRequestsList(context, ref, filteredRequests);
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.iosRed),
            const SizedBox(height: 16),
            Text('${l10n.error}: ${error.toString()}',
                style: const TextStyle(color: AppTheme.iosGray)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(requestsListProvider),
              child: Text(l10n.update),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, RequestsFilter filter, String? couponFilter) {
    final tabIndex = _tabController.index;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: SingleChildScrollView(
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

            if (tabIndex != 2) ...[
              // Priority Filter
              _buildFilterChip(
                context: context,
                label: filter.priority == null
                    ? l10n.allPriorities
                    : _getPriorityDisplay(context, filter.priority!),
                selected: filter.priority != null,
                color: filter.priority != null
                    ? PriorityColors.getColor(filter.priority!)
                    : null,
                onTap: () => _showPriorityFilter(context, ref, filter),
              ),
              const SizedBox(width: 8),

              // Status Filter - Only show for Active tab
              if (tabIndex == 0) ...[
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
              ],

              // Clear All
              if (filter.hasFilters)
                TextButton.icon(
                  onPressed: () {
                    ref.read(requestsFilterProvider.notifier).state =
                        RequestsFilter();
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: Text(l10n.clearAll),
                ),
            ] else ...[
              // Coupon status filter
              _buildFilterChip(
                context: context,
                label: couponFilter == null
                    ? l10n.allStatus
                    : _getStatusDisplay(context, couponFilter),
                selected: couponFilter != null,
                color: couponFilter != null ? AppTheme.primary : null,
                onTap: () => _showCouponStatusFilter(context, ref, couponFilter),
              ),
              const SizedBox(width: 8),
              
              if (couponFilter != null)
                TextButton.icon(
                  onPressed: () {
                    ref.read(couponRequestsFilterProvider.notifier).state = null;
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: Text(l10n.clearAll),
                ),
            ],
          ],
        ),
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
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05)),
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
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: color ?? AppTheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(
      BuildContext context, WidgetRef ref, List<DeliveryRequest> requests) {
    // Sort: Urgent first, then by date
    final sortedRequests = List<DeliveryRequest>.from(requests)
      ..sort((a, b) {
        // Urgent first
        if (a.isUrgent && !b.isUrgent) return -1;
        if (!a.isUrgent && b.isUrgent) return 1;
        // Then by date (newest first)
        return b.requestDate.compareTo(a.requestDate);
      });

    return RefreshIndicator(
      onRefresh: () => ref.refresh(requestsListProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: sortedRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final request = sortedRequests[index];
          return _buildRequestCard(context, ref, request);
        },
      ),
    );
  }

  Widget _buildRequestCard(
      BuildContext context, WidgetRef ref, DeliveryRequest request) {
    final l10n = AppLocalizations.of(context)!;
    final isUrgent = request.isUrgent;
    final isSelected = _selectedIds.contains(request.id);

    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      color: isSelected ? AppTheme.primary.withOpacity(0.1) : null,
      boxShadow: isUrgent
          ? [
              BoxShadow(
                  color: AppTheme.iosRed.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]
          : null,
      onTap: () => _isSelecting
          ? _toggleSelection(request.id)
          : _showRequestDetails(context, ref, request),
      onLongPress: () => _toggleSelection(request.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Selection Checkbox
              if (_isSelecting) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(request.id),
                ),
                const SizedBox(width: 8),
              ],
              // Priority Badge
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: PriorityColors.getColor(request.priority)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PriorityColors.getIcon(request.priority),
                        size: 14,
                        color: PriorityColors.getColor(request.priority),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _getPriorityDisplay(context, request.priority)
                              .toUpperCase(),
                          style: TextStyle(
                            color: PriorityColors.getColor(request.priority),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        StatusColors.getColor(request.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getStatusDisplay(context, request.status).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: StatusColors.getColor(request.status),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Spacer(),

              // Gallons
              Text(
                '${request.requestedGallons}${l10n.gallons}',
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
                        const Icon(Icons.edit_notifications_outlined,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.changeStatus),
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
                    _showStatusDialog(context, ref, request);
                  } else if (value == 'delete') {
                    _confirmDelete(context, ref, request);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Client Info
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  size: 18, color: AppTheme.iosGray),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
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
                  request.clientAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Phone
          Row(
            children: [
              const Icon(Icons.phone_rounded,
                  size: 18, color: AppTheme.iosGray),
              const SizedBox(width: 8),
              Text(
                request.clientPhone,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Notes
          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.iosYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined,
                      size: 16, color: AppTheme.iosOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.notes!,
                      style: const TextStyle(
                          fontSize: 13, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              // Date
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 16, color: AppTheme.iosGray),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(request.requestDate),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.iosGray,
                      ),
                    ),
                  ],
                ),
              ),

              // Assigned Worker or Assign Button
              if (request.assignedWorkerName != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.iosGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 14, color: AppTheme.iosGreen),
                      const SizedBox(width: 6),
                      Text(
                        request.assignedWorkerName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.iosGreen,
                        ),
                      ),
                    ],
                  ),
                )
              else if (request.canAssignWorker)
                ElevatedButton.icon(
                  onPressed: () =>
                      _showAssignWorkerDialog(context, ref, request),
                  icon: const Icon(Icons.assignment_ind_rounded, size: 16),
                  label: Text(l10n.assignWorker),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 80, color: AppTheme.iosGray.withOpacity(0.2)),
          const SizedBox(height: 24),
          const Text(
            'No requests found',
            style: TextStyle(
                fontSize: 18,
                color: AppTheme.iosGray,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(color: AppTheme.iosGray),
          ),
        ],
      ),
    );
  }

  void _showPriorityFilter(
      BuildContext context, WidgetRef ref, RequestsFilter filter) {
    final l10n = AppLocalizations.of(context)!;
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
                title: Text(l10n.allPriorities,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: filter.priority == null
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(requestsFilterProvider.notifier).state =
                      filter.copyWith(clearPriority: true);
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            ...['urgent', 'mid_urgent', 'non_urgent'].map(
              (priority) => ListTile(
                leading: Icon(
                  PriorityColors.getIcon(priority),
                  color: PriorityColors.getColor(priority),
                ),
                title: Text(_getPriorityDisplay(context, priority)),
                trailing: filter.priority == priority
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(requestsFilterProvider.notifier).state =
                      filter.copyWith(priority: priority);
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

  void _showStatusFilter(
      BuildContext context, WidgetRef ref, RequestsFilter filter) {
    final l10n = AppLocalizations.of(context)!;
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
                title: Text(l10n.allStatus,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: filter.status == null
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(requestsFilterProvider.notifier).state =
                      filter.copyWith(clearStatus: true);
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            ...['pending', 'in_progress', 'completed'].map(
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
                  ref.read(requestsFilterProvider.notifier).state =
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

  void _showCouponStatusFilter(BuildContext context, WidgetRef ref, String? currentStatus) {
    final l10n = AppLocalizations.of(context)!;
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
                decoration: BoxDecoration(color: AppTheme.iosGray4, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                title: Text(l10n.allStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: currentStatus == null ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                onTap: () {
                  ref.read(couponRequestsFilterProvider.notifier).state = null;
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...['pending', 'approved', 'assigned', 'completed', 'cancelled'].map(
                (status) => ListTile(
                  leading: Icon(
                    StatusColors.getIcon(status),
                    color: status == 'approved' ? AppTheme.iosBlue :
                           status == 'assigned' ? AppTheme.iosIndigo :
                           StatusColors.getColor(status),
                  ),
                  title: Text(_getStatusDisplay(context, status)),
                  trailing: currentStatus == status ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                  onTap: () {
                    ref.read(couponRequestsFilterProvider.notifier).state = status;
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(
      BuildContext context, WidgetRef ref, DeliveryRequest request) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
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
                      '${l10n.requests} #${request.id}',
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
                  l10n.client, request.clientName, Icons.person_rounded),
              _buildDetailRow(
                  l10n.phone, request.clientPhone, Icons.phone_rounded),
              _buildDetailRow(l10n.address, request.clientAddress,
                  Icons.location_on_rounded),
              const Divider(height: 32),
              _buildDetailRow(
                  l10n.gallons,
                  '${request.requestedGallons}${l10n.gallons}',
                  Icons.water_drop_rounded),
              _buildDetailRow(
                  'Priority',
                  _getPriorityDisplay(context, request.priority),
                  Icons.priority_high_rounded),
              _buildDetailRow(
                  l10n.status,
                  _getStatusDisplay(context, request.status),
                  Icons.info_outline_rounded),
              _buildDetailRow(l10n.date, _formatDate(request.requestDate),
                  Icons.calendar_today_rounded),
              if (request.assignedWorkerName != null)
                _buildDetailRow(l10n.worker, request.assignedWorkerName!,
                    Icons.person_pin_circle_rounded),
              if (request.notes != null && request.notes!.isNotEmpty)
                _buildDetailRow(
                    l10n.notes, request.notes!, Icons.note_alt_outlined),
            ],
          ),
        ),
      ),
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

  void _showAssignWorkerDialog(
      BuildContext context, WidgetRef ref, DeliveryRequest request) {
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
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.person_rounded,
                              color: AppTheme.primary),
                        ),
                        title: Text(worker['username']),
                        subtitle: Text(worker['phone_number']),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${worker['profile']['active_tasks_count']} Active',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (worker['profile']['active_tasks_count'] ?? 0) > 3 
                                  ? AppTheme.iosOrange 
                                  : AppTheme.iosGreen,
                              ),
                            ),
                            Text(
                              '${worker['profile']['vehicle_current_gallons']}L left',
                              style: const TextStyle(fontSize: 10, color: AppTheme.iosGray),
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: () async {
                          Navigator.pop(context);
                          await _assignWorker(context, ref, request.id,
                              worker['profile']['id']);
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
      BuildContext context, WidgetRef ref, int requestId, int workerId) async {
    await ref
        .read(assignWorkerProvider.notifier)
        .assignWorker(requestId, workerId);

    final state = ref.read(assignWorkerProvider);
    final l10n = AppLocalizations.of(context)!;
    if (context.mounted) {
      state.when(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.workerAssigned)),
          );
          ref.invalidate(requestsListProvider);
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error: ${error.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppTheme.iosRed,
            ),
          );
        },
      );
    }
  }

  void _showStatusDialog(
      BuildContext context, WidgetRef ref, DeliveryRequest request) {
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
              final isSelected = request.status == status;
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
                  _updateStatus(context, ref, request.id, status);
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

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, int requestId, String status) async {
    await ref
        .read(updateRequestStatusProvider.notifier)
        .updateStatus(requestId, status);

    final state = ref.read(updateRequestStatusProvider);
    final l10n = AppLocalizations.of(context)!;
    if (context.mounted) {
      state.when(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.statusUpdated)),
          );
          ref.invalidate(requestsListProvider);
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error: ${error.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppTheme.iosRed,
            ),
          );
        },
      );
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, DeliveryRequest request) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('${l10n.delete} ${l10n.requests}?'),
        content: Text(l10n.deleteRequestConfirm(request.clientName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRequest(context, ref, request.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.iosRed),
            child:
                Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRequest(
      BuildContext context, WidgetRef ref, int requestId) async {
    await ref.read(deleteRequestProvider.notifier).deleteRequest(requestId);

    final state = ref.read(deleteRequestProvider);
    final l10n = AppLocalizations.of(context)!;
    if (context.mounted) {
      state.when(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.requestDeleted)),
          );
          ref.invalidate(requestsListProvider);
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error: ${error.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppTheme.iosRed,
            ),
          );
        },
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return DateFormat('MMM d, y').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _getPriorityDisplay(BuildContext context, String priority) {
    final l10n = AppLocalizations.of(context)!;
    switch (priority) {
      case 'urgent':
        return l10n.urgent;
      case 'mid_urgent':
        return l10n.midUrgent;
      case 'non_urgent':
        return l10n.normal;
      default:
        return priority;
    }
  }

  String _getStatusDisplay(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'approved':
        return l10n.approved;
      case 'assigned':
        return l10n.assigned;
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

  void _showBulkDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Requests'),
        content: Text('Delete ${_selectedIds.length} selected requests?'),
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
    final isCouponTab = _tabController.index == 2;
    for (final id in _selectedIds) {
      if (isCouponTab) {
        await ref.read(deleteCouponRequestProvider.notifier).deleteRequest(id);
      } else {
        await ref.read(deleteRequestProvider.notifier).deleteRequest(id);
      }
    }
    _clearSelection();
    if (isCouponTab) {
      ref.invalidate(adminCouponBookRequestsProvider);
    } else {
      ref.invalidate(requestsListProvider);
    }
  }

  Future<void> _handleBulkAction(BuildContext context, String status) async {
    final isCouponTab = _tabController.index == 2;
    for (final id in _selectedIds) {
      if (isCouponTab) {
        await ref.read(updateCouponBookRequestStatusProvider.notifier).updateStatus(id, status);
      } else {
        await ref.read(updateRequestStatusProvider.notifier).updateStatus(id, status);
      }
    }
    _clearSelection();
    if (isCouponTab) {
      ref.invalidate(adminCouponBookRequestsProvider);
    } else {
      ref.invalidate(requestsListProvider);
    }
  }
}
