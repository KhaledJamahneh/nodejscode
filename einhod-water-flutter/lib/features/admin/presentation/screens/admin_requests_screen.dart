// lib/features/admin/presentation/screens/admin_requests_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/requests_provider.dart';
import '../providers/users_provider.dart';
import '../../data/models/request_model.dart';
import '../../data/admin_service.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const AdminRequestsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> {
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
    final requestsAsync = ref.watch(requestsListProvider);
    final filter = ref.watch(requestsFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialIndex,
      child: Scaffold(
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
                onPressed: () {
                  ref.invalidate(requestsListProvider);
                  ref.invalidate(adminCouponBookRequestsProvider);
                },
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: Builder(builder: (context) {
          return Column(
            children: [
              // Filters - Hide for Coupon Books tab
              if (DefaultTabController.of(context).index != 2)
                _buildFilters(context, ref, filter),

              // Requests List
              Expanded(
                child: TabBarView(
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
          );
        }),
      ),
    );
  }

  Widget _buildCouponRequestsView(BuildContext context, WidgetRef ref) {
    final couponRequestsAsync = ref.watch(adminCouponBookRequestsProvider);
    final l10n = AppLocalizations.of(context)!;

    return couponRequestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) return _buildEmptyState(context);
        
        // Group requests by client_id
        final grouped = <int, List<Map<String, dynamic>>>{};
        for (var req in requests) {
          final clientId = req['client_id'] as int;
          grouped.putIfAbsent(clientId, () => []).add(req);
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminCouponBookRequestsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: grouped.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final clientRequests = grouped.values.elementAt(index);
              return _buildGroupedCouponRequests(context, ref, clientRequests);
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
            Text('${l10n.error}: ${ErrorHandler.getMessage(error)}', style: const TextStyle(color: AppTheme.iosGray)),
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

  Widget _buildGroupedCouponRequests(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> requests) {
    final l10n = AppLocalizations.of(context)!;
    final firstReq = requests.first;
    
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${firstReq['client_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.iosGray),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${firstReq['client_address']}',
                            style: const TextStyle(color: AppTheme.iosGray, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (firstReq['client_phone'] != null)
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: AppTheme.primary),
                  onPressed: () {},
                ),
            ],
          ),
          const Divider(height: 24),
          ...requests.map((req) => _buildCouponRequestItem(context, ref, req)),
          const SizedBox(height: 12),
          if (firstReq['assigned_worker_id'] == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAssignWorkerDialog(context, ref, requests.map((r) => r['id'] as int).toList()),
                icon: const Icon(Icons.person_add_rounded),
                label: Text(l10n.assignWorker),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.assignedTo}: ${firstReq['worker_name']}',
                    style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCouponRequestItem(BuildContext context, WidgetRef ref, Map<String, dynamic> request) {
    final l10n = AppLocalizations.of(context)!;
    final status = request['status'] ?? 'pending';
    final statusColor = status == 'pending' ? AppTheme.midUrgentOrange :
                       status == 'approved' || status == 'assigned' ? AppTheme.successGreen :
                       status == 'completed' ? AppTheme.primaryBlue : AppTheme.iosGray;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            request['book_type'] == 'physical' ? Icons.menu_book_rounded : Icons.qr_code_2_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${request['book_size']} ${l10n.pages}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  '${request['book_type']} • ${_getStatusText(status, l10n)}',
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            '₪${request['total_price']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending': return l10n.pending;
      case 'approved': return l10n.approved;
      case 'assigned': return 'Assigned';
      case 'completed': return l10n.delivered;
      case 'cancelled': return l10n.cancelled;
      default: return status;
    }
  }

  void _showAssignWorkerDialog(BuildContext context, WidgetRef ref, List<int> requestIds) {
    final l10n = AppLocalizations.of(context)!;
    final workersAsync = ref.watch(availableWorkersProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assignWorker),
        content: workersAsync.when(
          data: (workers) => SizedBox(
            width: double.maxFinite,
            child: workers.isEmpty
                ? Text(l10n.noWorkersAvailable)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                        title: Text(worker['full_name'] ?? ''),
                        subtitle: Text(worker['worker_type'] ?? ''),
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            for (final id in requestIds) {
                              await ref.read(adminServiceProvider).assignCouponBookWorker(id, worker['id']);
                            }
                            ref.invalidate(adminCouponBookRequestsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.workerAssignedSuccessfully)),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Text('Error: $e'),
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

  Widget _buildCouponBookRequestCard(BuildContext context, WidgetRef ref, Map<String, dynamic> request) {
    final l10n = AppLocalizations.of(context)!;
    final status = request['status'] ?? 'pending';
    final statusColor = status == 'pending' ? AppTheme.midUrgentOrange :
                       status == 'approved' ? AppTheme.successGreen :
                       status == 'delivered' ? AppTheme.primaryBlue : AppTheme.iosGray;
    
    String getStatusText(String status) {
      switch (status) {
        case 'pending': return l10n.pending;
        case 'approved': return l10n.approved;
        case 'delivered': return l10n.delivered;
        case 'cancelled': return l10n.cancelled;
        default: return status;
      }
    }

    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  getStatusText(status).toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: AppTheme.iosGray),
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDeleteCouponRequest(context, ref, request['id']);
                  } else {
                    _updateCouponRequestStatus(context, ref, request['id'], value);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'pending', child: Text(l10n.pending)),
                  PopupMenuItem(value: 'approved', child: Text(l10n.approved)),
                  PopupMenuItem(value: 'delivered', child: Text(l10n.delivered)),
                  PopupMenuItem(value: 'cancelled', child: Text(l10n.cancelled)),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: AppTheme.iosRed, size: 20),
                        const SizedBox(width: 8),
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
              Text(
                '₪${request['total_price']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),
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
        ],
      ),
    );
  }

  Future<void> _updateCouponRequestStatus(BuildContext context, WidgetRef ref, int requestId, String status) async {
    await ref.read(updateCouponBookRequestStatusProvider.notifier).updateStatus(requestId, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
    }
  }

  Future<void> _confirmDeleteCouponRequest(BuildContext context, WidgetRef ref, int requestId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text('Are you sure you want to delete this coupon request?'),
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
          SnackBar(content: Text('Request deleted successfully')),
        );
      }
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
            Text('${l10n.error}: ${ErrorHandler.getMessage(error)}',
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

  Widget _buildFilters(
      BuildContext context, WidgetRef ref, RequestsFilter filter) {
    final tabIndex = DefaultTabController.of(context).index;
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
                      _showAssignWorkerDialog(context, ref, [request.id]),
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
                  'Error: ${ErrorHandler.getMessage(error).replaceAll('Exception: ', '')}'),
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
                  'Error: ${ErrorHandler.getMessage(error).replaceAll('Exception: ', '')}'),
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
    for (final id in _selectedIds) {
      await ref.read(deleteRequestProvider.notifier).deleteRequest(id);
    }
    _clearSelection();
    ref.invalidate(requestsListProvider);
  }

  Future<void> _handleBulkAction(BuildContext context, String status) async {
    for (final id in _selectedIds) {
      await ref.read(updateRequestStatusProvider.notifier).updateStatus(id, status);
    }
    _clearSelection();
    ref.invalidate(requestsListProvider);
  }
}
