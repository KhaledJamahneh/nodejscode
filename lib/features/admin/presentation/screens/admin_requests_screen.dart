// lib/features/admin/presentation/screens/admin_requests_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/requests_provider.dart';
import '../providers/users_provider.dart';
import '../providers/admin_provider.dart';
import '../../../worker/presentation/providers/worker_provider.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const AdminRequestsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(requestsListProvider);
    final couponRequestsAsync = ref.watch(adminCouponBookRequestsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(l10n.requests, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.glassBg.withOpacity(0.8),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(requestsListProvider);
              ref.invalidate(adminCouponBookRequestsProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryBlue,
          tabs: [
            Tab(text: l10n.water),
            Tab(text: l10n.cancelled),
            Tab(text: l10n.coupons.toUpperCase()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWaterRequests(requestsAsync),
          _buildCancelledRequests(requestsAsync),
          _buildCouponRequests(couponRequestsAsync),
        ],
      ),
    );
  }

  Widget _buildWaterRequests(AsyncValue<List<dynamic>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
        final active = requests.where((r) => r['status'] != 'cancelled').toList();
        if (active.isEmpty) return _buildEmptyState();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: active.length,
          itemBuilder: (context, index) => _RequestCard(request: active[index], type: 'water'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildCancelledRequests(AsyncValue<List<dynamic>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
        final cancelled = requests.where((r) => r['status'] == 'cancelled').toList();
        if (cancelled.isEmpty) return _buildEmptyState();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cancelled.length,
          itemBuilder: (context, index) => _RequestCard(request: cancelled[index], type: 'water'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildCouponRequests(AsyncValue<List<dynamic>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) return _buildEmptyState();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) => _RequestCard(request: requests[index], type: 'coupon'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No requests found'));
  }
}

class _RequestCard extends ConsumerWidget {
  final dynamic request;
  final String type;
  const _RequestCard({required this.request, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final String status = request['status'] ?? 'pending';
    final String clientName = request['client_name'] ?? 'Unknown';
    final String address = request['client_address'] ?? 'No address';
    final Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text(
                  type == 'water' ? '${request['requested_gallons']} Gallons' : 'Coupon Book',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(address, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                if (status == 'pending' || status == 'approved')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAssignDialog(context, ref),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('ASSIGN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.iosGray.withOpacity(0.1)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppTheme.midUrgentOrange;
      case 'approved': return AppTheme.primaryBlue;
      case 'assigned': return AppTheme.iosIndigo;
      case 'in_progress': return Colors.orange;
      case 'completed': return AppTheme.successGreen;
      case 'cancelled': return AppTheme.criticalRed;
      default: return AppTheme.iosGray;
    }
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.read(workersListProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Worker'),
        content: SizedBox(
          width: double.maxFinite,
          child: workersAsync.when(
            data: (workers) => ListView.builder(
              shrinkWrap: true,
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final w = workers[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(w['full_name'] ?? w['username']),
                  onTap: () async {
                    if (type == 'water') {
                      await ref.read(assignWorkerProvider.notifier).assignWorker(request['id'], w['profile']['id']);
                    } else {
                      await ref.read(assignCouponBookWorkerProvider.notifier).assignWorker(request['id'], w['profile']['id']);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading workers'),
          ),
        ),
      ),
    );
  }
}
