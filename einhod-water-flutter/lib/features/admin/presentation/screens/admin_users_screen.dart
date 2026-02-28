// lib/features/admin/presentation/screens/admin_users_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../worker/presentation/providers/worker_provider.dart';
import '../../../worker/data/models/worker_models.dart';
import '../providers/users_provider.dart';
import '../providers/admin_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/models/shift_model.dart';
import 'admin_shifts_screen.dart' show shiftsProvider;

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  final Set<int> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      _selectedUserIds.clear();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final filter = ref.watch(usersFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.adminView + ' ' + l10n.users),
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
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
          if (_tabController.index == 1)
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => context.push('/admin/coupon-settings'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(usersProvider),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.workers),
            Tab(text: l10n.clients),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filters
          _buildFilters(context, filter),

          // Users List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final workers = users.where((u) => 
                  u.roles.contains('delivery_worker') || 
                  u.roles.contains('onsite_worker') ||
                  u.roles.contains('administrator')
                ).toList();
                final clients = users.where((u) => u.roles.contains('client')).toList();
                return TabBarView(
                  controller: _tabController,
                  children: [
                    workers.isEmpty ? _buildEmptyState(context) : _buildUsersList(workers),
                    clients.isEmpty ? _buildEmptyState(context) : _buildUsersList(clients),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
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
                      onPressed: () => ref.invalidate(usersProvider),
                      child: Text(l10n.update),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedUserIds.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateUserDialog(context),
              icon: const Icon(Icons.person_add_rounded),
              label: Text(l10n.createUser),
              elevation: 4,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : FloatingActionButton.extended(
              onPressed: () => _showBatchShiftAssignment(),
              icon: const Icon(Icons.schedule_rounded),
              label: Text('${l10n.assignWorker} (${_selectedUserIds.length})'),
              elevation: 4,
              backgroundColor: AppTheme.iosGreen,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _buildFilters(BuildContext context, UsersFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.6)
                            : null,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(usersFilterProvider.notifier).state =
                            filter.copyWith(clearSearch: true);
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              ref.read(usersFilterProvider.notifier).state = filter.copyWith(
                  search: value.isEmpty ? null : value,
                  clearSearch: value.isEmpty);
            },
          ),
          const SizedBox(height: 16),

          // Filter Chips
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

                // Role Filter
                _buildFilterChip(
                  label: filter.role == null
                      ? l10n.allRoles
                      : _getRoleDisplay(context, filter.role!),
                  selected: filter.role != null,
                  onTap: () => _showRoleFilter(context, filter),
                ),
                const SizedBox(width: 8),

                // Status Filter
                _buildFilterChip(
                  label: filter.isActive == null
                      ? l10n.allStatus
                      : (filter.isActive! ? l10n.active : l10n.inactive),
                  selected: filter.isActive != null,
                  onTap: () => _showStatusFilter(context, filter),
                ),
                const SizedBox(width: 8),

                // On-Shift Filter (only show for workers tab)
                if (_tabController.index == 0)
                  _buildFilterChip(
                    label: filter.onShift == null
                        ? l10n.allWorkers
                        : l10n.onShiftOnly,
                    selected: filter.onShift != null,
                    onTap: () => _showOnShiftFilter(context, filter),
                  ),
                if (_tabController.index == 0) const SizedBox(width: 8),

                // Payment Method Filter (only show for clients tab)
                if (_tabController.index == 1)
                  _buildFilterChip(
                    label: filter.paymentMethod == null
                        ? l10n.allPaymentMethods
                        : (filter.paymentMethod == 'coupons' ? l10n.coupons : l10n.cash),
                    selected: filter.paymentMethod != null,
                    onTap: () => _showPaymentMethodFilter(context, filter),
                  ),
                if (_tabController.index == 1) const SizedBox(width: 8),

                // Coupon Size Filter (only show for clients tab with coupons)
                if (_tabController.index == 1 && filter.paymentMethod == 'coupons')
                  _buildFilterChip(
                    label: filter.couponSize == null
                        ? l10n.allSizes
                        : _getCouponSizeDisplay(filter.couponSize!),
                    selected: filter.couponSize != null,
                    onTap: () => _showCouponSizeFilter(context, filter),
                  ),
                if (_tabController.index == 1 && filter.paymentMethod == 'coupons') const SizedBox(width: 8),

                // Clear All
                if (filter.role != null ||
                    filter.isActive != null ||
                    filter.search != null ||
                    filter.onShift != null ||
                    filter.paymentMethod != null ||
                    filter.couponSize != null)
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(usersFilterProvider.notifier).state =
                          UsersFilter();
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: Text(l10n.clearAll),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.primary : (Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down_rounded,
                  size: 16, color: AppTheme.primary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(List<User> users) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(usersProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final l10n = AppLocalizations.of(context)!;
    final primaryRole = user.roles.isNotEmpty ? user.roles.first : 'client';
    final roleColor = _getRoleColor(primaryRole);
    final isSelected = _selectedUserIds.contains(user.id);
    final isWorker = user.roles.any((r) => ['delivery_worker', 'onsite_worker'].contains(r));

    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      borderColor: isSelected ? AppTheme.primary : null,
      borderWidth: isSelected ? 2.5 : null,
      onTap: _selectedUserIds.isEmpty ? () => _showUserDetails(context, user.id) : () {
        setState(() {
          if (isSelected) {
            _selectedUserIds.remove(user.id);
          } else {
            _selectedUserIds.add(user.id);
          }
        });
      },
      onLongPress: isWorker ? () {
        setState(() {
          if (isSelected) {
            _selectedUserIds.remove(user.id);
          } else {
            _selectedUserIds.add(user.id);
          }
        });
      } : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getRoleIcon(primaryRole),
                  color: roleColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.phoneNumber,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.iosGray),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? AppTheme.iosGreen.withOpacity(0.1)
                        : AppTheme.iosRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user.statusDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: user.isActive ? AppTheme.iosGreen : AppTheme.iosRed,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.iosGray, size: 20),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_rounded,
                          size: 18,
                          color: user.isActive
                              ? AppTheme.iosOrange
                              : AppTheme.iosGreen,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            user.isActive ? l10n.deactivate : l10n.activate,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await _toggleUserActive(user);
                    },
                  ),
                  if (user.roles.any((r) => ['delivery_worker', 'onsite_worker'].contains(r)))
                    PopupMenuItem(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Manage Shift',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showShiftDialog(user);
                      },
                    ),
                  if (user.roles.any((r) => ['delivery_worker', 'onsite_worker'].contains(r)))
                    PopupMenuItem(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_busy_rounded,
                              color: AppTheme.iosOrange, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Add Leave',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showLeaveDialog(user);
                      },
                    ),
                  if (user.roles.any((r) => ['delivery_worker', 'onsite_worker'].contains(r)))
                    PopupMenuItem(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.salaryAdvance,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showSalaryAdvanceDialog(user);
                      },
                    ),
                  PopupMenuItem(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.iosRed, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.delete,
                            style: const TextStyle(color: AppTheme.iosRed),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _confirmDeleteUser(user);
                    },
                  ),
                  PopupMenuItem(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.editInfo,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _showEditUserDialog(context, user);
                    },
                  ),
                ],
              ),
            ],
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1)),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: user.roles
                      .map((role) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(role).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _getRoleColor(role).withOpacity(0.2)),
                            ),
                            child: Text(
                              _getRoleDisplay(context, role),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getRoleColor(role),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              if (user.roles.contains('client') && user.profile != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 14, color: AppTheme.iosBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${user.profile!['coupon_book_size'] ?? user.profile!['remaining_coupons'] ?? 0} (${user.profile!['remaining_coupons'] ?? 0} ${l10n.left})',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.iosBlue),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.inventory_2_outlined,
                          size: 14, color: AppTheme.iosGreen),
                      const SizedBox(width: 4),
                      Text(
                        '${user.profile!['gallons_on_hand'] ?? 0}G',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.iosGreen),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Worker shift and leave info
          if (user.isWorker) ...[
            const SizedBox(height: 12),
            if (user.currentLeave != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.iosOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.iosOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 16, color: AppTheme.iosOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${user.currentLeave!.typeDisplay}: ${DateFormat('MMM d').format(DateTime.parse(user.currentLeave!.startDate))} - ${DateFormat('MMM d').format(DateTime.parse(user.currentLeave!.endDate))}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.iosOrange),
                      ),
                    ),
                  ],
                ),
              )
            else if (user.shift != null)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isActiveNow ? AppTheme.iosGreen.withOpacity(0.1) : AppTheme.iosGray.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.isActiveNow ? Icons.circle : Icons.circle_outlined,
                          size: 8,
                          color: user.isActiveNow ? AppTheme.iosGreen : AppTheme.iosGray,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getShiftDisplay(context, user.shift!.name),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: user.isActiveNow ? AppTheme.iosGreen : AppTheme.iosGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.shift!.timeDisplay(Localizations.localeOf(context).languageCode),
                      style: const TextStyle(fontSize: 11, color: AppTheme.iosGray),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.iosRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_rounded, size: 16, color: AppTheme.iosRed),
                    SizedBox(width: 8),
                    Text(
                      'No shift assigned',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.iosRed),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserScreen(
          user: user,
          onUserUpdated: () => ref.invalidate(usersProvider),
        ),
      ),
    );
  }

  void _showUserDetails(BuildContext context, int userId) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final userAsync = ref.watch(userDetailsProvider(userId));

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => GlassCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(24),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              child: userAsync.when(
                data: (user) => ListView(
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
                            '${l10n.profile} ${l10n.viewDetails}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.1)
                                : AppTheme.iosGray6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Basic Info Section
                    _buildSectionTitle(context, l10n.accountInfo),
                    _buildDetailRow(context, l10n.username, user.username,
                        Icons.person_outline_rounded),
                    _buildDetailRow(context, l10n.role, 
                        user.roles.map((r) => _getRoleDisplay(context, r)).join(', '),
                        Icons.admin_panel_settings_outlined),
                    _buildDetailRow(context, l10n.phone, user.phoneNumber,
                        Icons.phone_outlined),
                    if (user.email != null)
                      _buildDetailRow(context, l10n.email, user.email!,
                          Icons.email_outlined),
                    _buildDetailRow(
                        context,
                        l10n.status,
                        user.isActive ? l10n.active : l10n.inactive,
                        Icons.info_outline_rounded),
                    _buildDetailRow(
                        context,
                        l10n.date,
                        _formatDateTime(user.createdAt, Localizations.localeOf(context).languageCode),
                        Icons.calendar_today_rounded),
                    if (user.lastLogin != null)
                      _buildDetailRow(
                          context,
                          l10n.login,
                          _formatDateTime(user.lastLogin!, Localizations.localeOf(context).languageCode),
                          Icons.login_rounded),

                    const SizedBox(height: 32),

                    // Profile Info Section
                    if (user.profile != null) ...[
                      _buildSectionTitle(context, l10n.profileDetails),
                      if (user.roles.contains('client')) ...[
                        Text(l10n.clientView,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.primary)),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                            context,
                            l10n.fullName,
                            user.profile!['full_name'] ?? l10n.notAvailable,
                            Icons.badge_outlined),
                        _buildDetailRow(
                            context,
                            l10n.address,
                            user.profile!['address'] ?? l10n.notAvailable,
                            Icons.location_on_outlined),
                        _buildDetailRow(
                            context,
                            l10n.subscription,
                            user.profile!['subscription_type'] != null
                                ? _getSubscriptionTypeDisplay(context, user.profile!['subscription_type'])
                                : l10n.notAvailable,
                            Icons.card_membership_rounded),
                        _buildDetailRow(
                            context,
                            l10n.couponBookSize,
                            '${user.profile!['coupon_book_size'] ?? 0}',
                            Icons.book_outlined),
                        _buildDetailRow(
                            context,
                            l10n.coupons,
                            '${user.profile!['remaining_coupons'] ?? 0} ${l10n.remaining}',
                            Icons.confirmation_number_outlined),
                        _buildDetailRow(
                            context,
                            l10n.gallonsOnHand,
                            '${user.profile!['gallons_on_hand'] ?? 0} ${l10n.gallons}',
                            Icons.inventory_2_outlined),
                        const SizedBox(height: 8),
                        if (user.profile!['dispensers_count'] != null && user.profile!['dispensers_count'] > 0) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.water_drop_outlined, size: 20, color: AppTheme.iosGray),
                                const SizedBox(width: 12),
                                Text(
                                  '${l10n.dispensers} (${user.profile!['dispensers_count']})',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          ...List.generate(
                            (user.profile!['dispensers'] as List?)?.length ?? 0,
                            (index) {
                              final dispenser = user.profile!['dispensers'][index];
                              final serialNumber = dispenser['serial_number']?.toString().trim();
                              return InkWell(
                                onTap: () => _showDispenserInfoDialog(context, dispenser['id']),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.iosGray.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.qr_code, size: 18, color: AppTheme.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          (serialNumber == null || serialNumber.isEmpty) ? 'No Serial Number' : serialNumber,
                                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.iosGray),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildDetailRow(
                            context,
                            l10n.balance,
                            '₪${user.profile!['current_debt'] ?? 0.00}',
                            Icons.money_off_outlined),
                        const SizedBox(height: 16),
                      ],
                      if (user.roles.contains('delivery_worker') ||
                          user.roles.contains('onsite_worker')) ...[
                        Text(l10n.workerView,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.primary)),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                            context,
                            l10n.fullName,
                            user.profile!['full_name'] ?? l10n.notAvailable,
                            Icons.badge_outlined),
                        _buildDetailRow(
                            context,
                            l10n.workerType,
                            user.profile!['worker_type'] != null 
                                ? _getWorkerTypeDisplay(context, user.profile!['worker_type'])
                                : l10n.notAvailable,
                            Icons.work_outline_rounded),
                        _buildDetailRow(
                            context,
                            l10n.date,
                            user.profile!['hire_date'] != null
                                ? _formatDate(user.profile!['hire_date'], Localizations.localeOf(context).languageCode)
                                : l10n.notAvailable,
                            Icons.calendar_month_outlined),
                        if (user.roles.contains('delivery_worker'))
                          _buildDetailRow(
                              context,
                              l10n.vehicleCapacity,
                              '${user.profile!['vehicle_current_gallons'] ?? 0} gal',
                              Icons.water_drop_outlined),
                        _buildDetailRow(
                            context,
                            l10n.salary,
                            '₪${user.profile!['current_salary'] ?? '0.00'}',
                            Icons.payments_outlined),
                        _buildDetailRow(
                            context,
                            l10n.salaryAdvance,
                            '₪${user.profile!['debt_advances'] ?? '0.00'}',
                            Icons.account_balance_wallet_outlined),
                        if (user.roles.contains('onsite_worker')) ...[
                          const SizedBox(height: 16),
                          Consumer(
                            builder: (context, ref, _) {
                              final stationsAsync =
                                  ref.watch(fillingStationsProvider);
                              return stationsAsync.when(
                                data: (stations) {
                                  if (stations.isEmpty)
                                    return const SizedBox.shrink();
                                  final station = stations.first;

                                  // Determine status display
                                  String statusText;
                                  Color statusColor;

                                  switch (station.currentStatus) {
                                    case StationStatus.open:
                                      statusText = l10n.open.toUpperCase();
                                      statusColor = AppTheme.successGreen;
                                      break;
                                    case StationStatus.temporarilyClosed:
                                      statusText = l10n.tempClosed.toUpperCase();
                                      statusColor = AppTheme.midUrgentOrange;
                                      break;
                                    case StationStatus.closedUntilTomorrow:
                                      statusText = l10n.closedUntilTomorrow.toUpperCase();
                                      statusColor = const Color(0xFF64748B); // ✅ FIX #7: neutral slate, same as worker screen
                                      break;
                                    default:
                                      statusText = l10n.unknown.toUpperCase();
                                      statusColor = AppTheme.iosGray;
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                              Icons.factory_rounded,
                                              size: 20,
                                              color: AppTheme.primary),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.assignedStation,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme.iosGray,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                station.name,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: statusColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  statusText,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                loading: () => const SizedBox(
                                    height: 30,
                                    child: Center(
                                        child: CircularProgressIndicator
                                            .adaptive())),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                        ],
                      ],
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50)),
                        child: Text(l10n.close),
                      ),
                    ),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
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

  void _showRoleFilter(BuildContext context, UsersFilter filter) {
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
                title: Text(l10n.allRoles,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: filter.role == null
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(usersFilterProvider.notifier).state =
                      filter.copyWith(clearRole: true);
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            ...['client', 'delivery_worker', 'onsite_worker', 'administrator']
                .map(
              (role) => ListTile(
                title: Text(_getRoleDisplay(context, role)),
                trailing: filter.role == role
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(usersFilterProvider.notifier).state =
                      filter.copyWith(role: role);
                  Navigator.pop(context);
                  
                  // Switch to appropriate tab
                  if (role == 'client') {
                    _tabController.animateTo(1);
                  } else if (role == 'delivery_worker' || role == 'onsite_worker') {
                    _tabController.animateTo(0);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ));
  }

  void _showStatusFilter(BuildContext context, UsersFilter filter) {
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
                trailing: filter.isActive == null
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(usersFilterProvider.notifier).state =
                      filter.copyWith(clearActive: true);
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            ListTile(
              title: Text(l10n.active),
              trailing: filter.isActive == true
                  ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                  : null,
              onTap: () {
                ref.read(usersFilterProvider.notifier).state =
                    filter.copyWith(isActive: true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.inactive),
              trailing: filter.isActive == false
                  ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                  : null,
              onTap: () {
                ref.read(usersFilterProvider.notifier).state =
                    filter.copyWith(isActive: false, clearOnShift: true);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ));
  }

  void _showOnShiftFilter(BuildContext context, UsersFilter filter) {
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
                title: Text(l10n.allWorkers,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: filter.onShift == null
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(usersFilterProvider.notifier).state =
                      filter.copyWith(clearOnShift: true);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                title: Text(l10n.onShiftOnly),
                trailing: filter.onShift == true
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(usersFilterProvider.notifier).state =
                      filter.copyWith(onShift: true);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodFilter(BuildContext context, UsersFilter filter) {
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
                title: Text(l10n.allPaymentMethods,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: filter.paymentMethod == null
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(usersFilterProvider.notifier).state =
                      filter.copyWith(clearPaymentMethod: true, clearCouponSize: true);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                title: Text(l10n.coupons),
                trailing: filter.paymentMethod == 'coupons'
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(usersFilterProvider.notifier).state =
                      filter.copyWith(paymentMethod: 'coupons');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(l10n.cash),
                trailing: filter.paymentMethod == 'cash'
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(usersFilterProvider.notifier).state =
                      filter.copyWith(paymentMethod: 'cash', clearCouponSize: true);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showCouponSizeFilter(BuildContext context, UsersFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    final couponSizesAsync = ref.read(couponSizesProvider);
    
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
                title: Text(l10n.allSizes,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: filter.couponSize == null
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  ref.read(usersFilterProvider.notifier).state =
                      filter.copyWith(clearCouponSize: true);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              couponSizesAsync.when(
                data: (sizes) => Column(
                  children: sizes.map((size) => ListTile(
                    title: Text('$size ${l10n.coupons}'),
                    trailing: filter.couponSize == size.toString()
                        ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      ref.read(usersFilterProvider.notifier).state =
                          filter.copyWith(couponSize: size.toString());
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (_, __) => ListTile(
                  title: Text(l10n.error),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _getCouponSizeDisplay(String size) {
    final l10n = AppLocalizations.of(context)!;
    return '$size ${l10n.coupons}';
  }

  void _showCouponSizesManagement(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final couponSizesAsync = ref.watch(couponSizesProvider);
          
          return GlassCard(
            margin: EdgeInsets.zero,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${l10n.manage} ${l10n.coupons} ${l10n.sizes}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () => _showAddCouponSizeDialog(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    couponSizesAsync.when(
                      data: (sizes) => Column(
                        children: sizes.map((size) => ListTile(
                          leading: const Icon(Icons.confirmation_number_rounded),
                          title: Text('$size ${l10n.coupons}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showEditCouponSizeDialog(context, size),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _deleteCouponSize(size),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator.adaptive()),
                      ),
                      error: (_, __) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(l10n.error),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCouponSizeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.add} ${l10n.coupons} ${l10n.size}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.coupons,
            hintText: '100',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final size = int.tryParse(controller.text);
              if (size != null && size > 0) {
                await _addCouponSize(size);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _showEditCouponSizeDialog(BuildContext context, int currentSize) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentSize.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.edit} ${l10n.coupons} ${l10n.size}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.coupons,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newSize = int.tryParse(controller.text);
              if (newSize != null && newSize > 0 && newSize != currentSize) {
                await _editCouponSize(currentSize, newSize);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _addCouponSize(int size) async {
    try {
      final service = ref.read(adminServiceProvider);
      await service.createCouponSize(
        size: size,
        totalGallons: size * 10,
        price: size * 10,
      );
      ref.invalidate(couponSizesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.success)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error)),
        );
      }
    }
  }

  Future<void> _editCouponSize(int oldSize, int newSize) async {
    if (mounted) {
      context.push('/admin/coupon-settings');
    }
  }

  Future<void> _deleteCouponSize(int size) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text('${l10n.delete} $size ${l10n.coupons}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(adminServiceProvider);
        final sizeData = await service.getCouponSizes();
        final sizeId = sizeData.firstWhere((s) => s['size'] == size)['id'];
        
        await service.deleteCouponSize(sizeId);
        ref.invalidate(couponSizesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.success)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error)),
          );
        }
      }
    }
  }

  Future<void> _toggleUserActive(User user) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(user.isActive
            ? '${l10n.deactivate} ${l10n.user}?'
            : '${l10n.activate} ${l10n.user}?'),
        content: Text(
          user.isActive
              ? l10n.deactivateUserConfirm(user.username)
              : l10n.activateUserConfirm(user.username),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  user.isActive ? AppTheme.iosRed : AppTheme.iosGreen,
            ),
            child: Text(user.isActive ? l10n.deactivate : l10n.activate),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(toggleUserActiveProvider.notifier).toggleActive(user.id);

      final state = ref.read(toggleUserActiveProvider);
      if (mounted) {
        state.when(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(user.isActive
                      ? l10n.userDeactivated
                      : l10n.userActivated)),
            );
            ref.invalidate(usersProvider);
          },
          loading: () {},
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: $error'),
                  backgroundColor: AppTheme.iosRed),
            );
          },
        );
      }
    }
  }

  void _showSalaryAdvanceDialog(User user) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.salaryAdvance),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${user.profile?['full_name']} - ${l10n.salaryAdvance}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${l10n.balance} (₪)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                try {
                  await ref.read(adminServiceProvider).updateWorkerAdvance(user.id, amount);
                  ref.refresh(usersProvider);
                  ref.refresh(userDetailsProvider(user.id));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.salaryAdvance} ${l10n.statusUpdated}')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.iosRed),
                    );
                  }
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteUser(User user) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.deleteUserConfirm(user.username)),
        content: Text(l10n.cannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.iosRed),
            child:
                Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteUser(user.id);
    }
  }

  Future<void> _deleteUser(int userId) async {
    await ref.read(deleteUserProvider.notifier).deleteUser(userId);

    final state = ref.read(deleteUserProvider);
    final l10n = AppLocalizations.of(context)!;
    if (mounted) {
      state.when(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userDeleted)),
          );
          ref.invalidate(usersProvider);
        },
        loading: () {},
        error: (error, _) {
          final errorKey = error.toString().replaceAll('Exception: ', '');
          final message = errorKey == 'cannotDeleteUserWithRecords'
              ? l10n.cannotDeleteUserWithRecords
              : errorKey;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppTheme.iosRed,
              duration: const Duration(seconds: 4),
            ),
          );
        },
      );
    }
  }

  void _showCreateUserDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateUserScreen(
          onUserCreated: () => ref.invalidate(usersProvider),
        ),
      ),
    );
  }

  void _showShiftDialog(User user) async {
    final service = ref.read(adminServiceProvider);
    final shifts = await service.getShifts();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assign Shift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...shifts.map((s) {
              final shift = WorkShift.fromJson(s);
              final isAssigned = user.profile?['shift_id'] == shift.id;
              return ListTile(
                leading: Icon(
                  isAssigned ? Icons.check_circle : Icons.schedule_rounded,
                  color: isAssigned ? AppTheme.iosGreen : AppTheme.primary,
                ),
                title: Text(_getShiftDisplay(context, shift.name)),
                subtitle: Text('${shift.daysDisplayLocalized(context)}\n${shift.timeDisplay(Localizations.localeOf(context).languageCode)}'),
                isThreeLine: true,
                selected: isAssigned,
                onTap: () async {
                  await service.assignShift(user.id, shift.id);
                  ref.invalidate(usersProvider);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shift assigned')),
                    );
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog(User user) {
    final startController = TextEditingController();
    final endController = TextEditingController();
    final reasonController = TextEditingController();
    String leaveType = 'vacation';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Leave'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: leaveType,
                decoration: const InputDecoration(labelText: 'Leave Type'),
                items: const [
                  DropdownMenuItem(value: 'vacation', child: Text('Vacation')),
                  DropdownMenuItem(value: 'sick_leave', child: Text('Sick Leave')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => leaveType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startController,
                decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason (optional)'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final service = ref.read(adminServiceProvider);
                await service.createLeave({
                  'user_id': user.id,
                  'leave_type': leaveType,
                  'start_date': startController.text,
                  'end_date': endController.text,
                  'reason': reasonController.text.isEmpty ? null : reasonController.text,
                });
                ref.invalidate(usersProvider);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leave added')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBatchShiftAssignment() async {
    final l10n = AppLocalizations.of(context)!;
    final shiftsAsync = await ref.read(shiftsProvider.future);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.assignWorker} (${_selectedUserIds.length} ${l10n.workers})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: shiftsAsync.map((shift) => ListTile(
            leading: const Icon(Icons.schedule_rounded),
            title: Text(_getShiftDisplay(context, shift.name)),
            subtitle: Text('${shift.daysDisplayLocalized(context)}\n${shift.timeDisplay(Localizations.localeOf(context).languageCode)}'),
            isThreeLine: true,
            onTap: () async {
              Navigator.pop(context);
              await _assignShiftToMultiple(shift.id);
            },
          )).toList(),
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

  Future<void> _assignShiftToMultiple(int shiftId) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(adminServiceProvider);
    
    try {
      for (final userId in _selectedUserIds) {
        await service.assignShift(userId, shiftId);
      }
      
      ref.invalidate(usersProvider);
      setState(() => _selectedUserIds.clear());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.workShifts} ${l10n.update}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: AppTheme.iosRed),
        );
      }
    }
  }

  Future<void> _showDispenserInfoDialog(BuildContext context, int dispenserId) async {
    final service = ref.read(adminServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final dispensers = await service.getDispensers();
      final dispenser = dispensers.firstWhere((d) => d['id'] == dispenserId);
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.water_drop, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.dispensers)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(l10n.serialNumber, dispenser['serial_number'] ?? 'N/A'),
                const Divider(),
                _buildInfoRow(l10n.status, dispenser['status'] ?? 'N/A'),
                const Divider(),
                _buildInfoRow(l10n.type, dispenser['type_name'] ?? 'N/A'),
                const Divider(),
                _buildInfoRow(l10n.assignedTo, dispenser['client_name'] ?? l10n.none),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/admin/dispenser-detail/$dispenserId');
              },
              child: Text(l10n.viewDetails),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.iosGray),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Common Helper Methods
String _getRoleDisplay(BuildContext context, String role) {
  final l10n = AppLocalizations.of(context)!;
  switch (role) {
    case 'client':
      return l10n.client;
    case 'delivery_worker':
      return l10n.deliveryWorker;
    case 'onsite_worker':
      return l10n.onsiteWorker;
    case 'administrator':
      return l10n.administrator;
    case 'owner':
      return l10n.owner;
    default:
      return role;
  }
}

String _getWorkerTypeDisplay(BuildContext context, String workerType) {
  final l10n = AppLocalizations.of(context)!;
  switch (workerType) {
    case 'delivery':
      return l10n.deliveryWorker;
    case 'onsite':
      return l10n.onsiteWorker;
    default:
      return workerType;
  }
}

String _getSubscriptionTypeDisplay(BuildContext context, String subscriptionType) {
  final l10n = AppLocalizations.of(context)!;
  switch (subscriptionType) {
    case 'coupon_book':
      return l10n.coupons;
    case 'cash':
    case 'pay_as_you_go':
      return l10n.payAsYouGo;
    default:
      return subscriptionType;
  }
}

String _getShiftDisplay(BuildContext context, String shiftName) {
  final l10n = AppLocalizations.of(context)!;
  switch (shiftName) {
    case 'Morning Shift':
      return l10n.morningShift;
    case 'Evening Shift':
      return l10n.eveningShift;
    case 'Full Day':
      return l10n.fullDay;
    default:
      return shiftName;
  }
}

IconData _getRoleIcon(String role) {
  switch (role) {
    case 'client':
      return Icons.person_rounded;
    case 'delivery_worker':
      return Icons.local_shipping_rounded;
    case 'onsite_worker':
      return Icons.business_rounded;
    case 'administrator':
      return Icons.admin_panel_settings_rounded;
    case 'owner':
      return Icons.verified_user_rounded;
    default:
      return Icons.person_rounded;
  }
}

Color _getRoleColor(String role) {
  switch (role) {
    case 'client':
      return AppTheme.iosBlue;
    case 'delivery_worker':
      return AppTheme.iosGreen;
    case 'onsite_worker':
      return AppTheme.iosOrange;
    case 'administrator':
      return AppTheme.iosPurple;
    case 'owner':
      return AppTheme.iosYellow;
    default:
      return AppTheme.iosGray;
  }
}

Widget _buildSectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.iosGray,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
    ),
  );
}

Widget _buildDetailRow(
    BuildContext context, String label, String value, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
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
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatDateTime(String dateTimeStr, [String? locale]) {
  try {
    final dt = DateTime.parse(dateTimeStr);
    return DateFormat('MMM d, y hh:mm a', locale).format(dt);
  } catch (e) {
    return dateTimeStr;
  }
}

String _formatDate(String dateStr, [String? locale]) {
  try {
    final dt = DateTime.parse(dateStr);
    return DateFormat('MMM d, y', locale).format(dt);
  } catch (e) {
    return dateStr;
  }
}

// Create User Screen - Modernized
class CreateUserScreen extends ConsumerStatefulWidget {
  final VoidCallback onUserCreated;

  const CreateUserScreen({super.key, required this.onUserCreated});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();

  List<String> _selectedRoles = ['client'];
  int _initialCoupons = 100;
  String _subscriptionType = 'coupon_book';
  String _selectedWorkerType = 'delivery';
  bool _obscurePassword = true;
  bool _isPaid = false;
  String _paymentMethod = 'cash';
  DateTime? _expiryDate;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createUserState = ref.watch(createUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createUser)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Role Selection (Multiple)
            _buildSectionTitle(context, l10n.assignRoles),
            ModernCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  'client',
                  'delivery_worker',
                  'onsite_worker',
                  'administrator'
                ].map((role) {
                  return CheckboxListTile(
                    title: Text(_getRoleDisplay(context, role),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    value: _selectedRoles.contains(role),
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          // Check if we are adding a worker role for the first time
                          bool hadWorkerRole =
                              _selectedRoles.contains('onsite_worker') ||
                                  _selectedRoles.contains('delivery_worker');

                          _selectedRoles.add(role);

                          // Only auto-select worker type if no worker role was previously selected
                          if (!hadWorkerRole) {
                            if (role == 'onsite_worker')
                              _selectedWorkerType = 'onsite';
                            if (role == 'delivery_worker')
                              _selectedWorkerType = 'delivery';
                          }
                        } else {
                          if (_selectedRoles.length > 1) {
                            _selectedRoles.remove(role);
                          }
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Username
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                  labelText: '${l10n.username} *',
                  prefixIcon: const Icon(Icons.person_rounded)),
              validator: (v) => v!.isEmpty ? l10n.required : null,
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '${l10n.password} *',
                helperText: 'Minimum 4 characters',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.required;
                if (v.length < 4) return 'Minimum 4 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                  labelText: '${l10n.fullName} *',
                  prefixIcon: const Icon(Icons.badge_rounded)),
              validator: (v) => v!.isEmpty ? l10n.required : null,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                  labelText: '${l10n.phone} *',
                  hintText: '05xxxxxxxx',
                  prefixIcon: const Icon(Icons.phone_rounded)),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.required;
                if (!RegExp(r'^05\d{8}$').hasMatch(v)) {
                  return 'Phone must be 05xxxxxxxx format';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                  labelText: '${l10n.email} (${l10n.optional})',
                  prefixIcon: const Icon(Icons.email_rounded)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            // Address (for clients)
            if (_selectedRoles.contains('client')) ...[
              _buildSectionTitle(context, l10n.clientView),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: '${l10n.address} *',
                  prefixIcon: const Icon(Icons.location_on_rounded),
                ),
                maxLines: 2,
                validator: (v) {
                  if (!_selectedRoles.contains('client')) return null;
                  if (v == null || v.isEmpty) return l10n.required;
                  if (v.length < 5)
                    return '${l10n.address} ${l10n.min8Chars.replaceAll('8', '5')}'; // Reuse min8Chars but for 5
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _subscriptionType,
                decoration: InputDecoration(
                    labelText: l10n.subscription,
                    prefixIcon: const Icon(Icons.card_membership_rounded)),
                items: [
                  DropdownMenuItem(
                      value: 'coupon_book', child: Text(l10n.coupons)),
                  DropdownMenuItem(value: 'cash', child: Text(l10n.payAsYouGo)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _subscriptionType = value);
                },
              ),
              const SizedBox(height: 16),
              if (_subscriptionType == 'coupon_book')
                Consumer(
                  builder: (context, ref, child) {
                    final couponSizesAsync = ref.watch(couponSizesProvider);
                    return couponSizesAsync.when(
                      data: (sizes) => DropdownButtonFormField<int>(
                        value: sizes.contains(_initialCoupons) ? _initialCoupons : (sizes.isNotEmpty ? sizes.first : 100),
                        decoration: InputDecoration(
                            labelText: l10n.coupons,
                            prefixIcon: const Icon(Icons.confirmation_number_rounded)),
                        items: sizes.map((size) {
                          return DropdownMenuItem(
                              value: size, child: Text('$size ${l10n.coupons}'));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _initialCoupons = value);
                        },
                      ),
                      loading: () => DropdownButtonFormField<int>(
                        value: _initialCoupons,
                        decoration: InputDecoration(
                            labelText: l10n.coupons,
                            prefixIcon: const Icon(Icons.confirmation_number_rounded)),
                        items: [_initialCoupons].map((size) {
                          return DropdownMenuItem(
                              value: size, child: Text('$size ${l10n.coupons}'));
                        }).toList(),
                        onChanged: null,
                      ),
                      error: (_, __) => DropdownButtonFormField<int>(
                        value: _initialCoupons,
                        decoration: InputDecoration(
                            labelText: l10n.coupons,
                            prefixIcon: const Icon(Icons.confirmation_number_rounded)),
                        items: [100, 200, 300].map((size) {
                          return DropdownMenuItem(
                              value: size, child: Text('$size ${l10n.coupons}'));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _initialCoupons = value);
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              // Payment Status (only for coupon_book)
              if (_subscriptionType == 'coupon_book') ...[
                SwitchListTile(
                  title: Text(l10n.paid, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_isPaid ? l10n.paymentReceived : l10n.addToDebt),
                  value: _isPaid,
                  activeColor: AppTheme.iosGreen,
                  onChanged: (value) => setState(() => _isPaid = value),
                ),
                const SizedBox(height: 8),
                // Payment Method (only if paid)
                if (_isPaid)
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: l10n.paymentMethod,
                      prefixIcon: const Icon(Icons.payment_rounded),
                    ),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text(l10n.cash)),
                      DropdownMenuItem(value: 'credit_card', child: Text(l10n.creditCard)),
                      DropdownMenuItem(value: 'bank_transfer', child: Text(l10n.bankTransfer)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                  ),
              ],
              const SizedBox(height: 24),
            ],

            if (_selectedRoles.contains('delivery_worker') ||
                _selectedRoles.contains('onsite_worker')) ...[
              _buildSectionTitle(context, l10n.workerSettings),
              DropdownButtonFormField<String>(
                value: _selectedWorkerType,
                decoration: InputDecoration(
                    labelText: l10n.workerType,
                    prefixIcon: const Icon(Icons.work_outline_rounded)),
                items: [
                  DropdownMenuItem(
                      value: 'delivery', child: Text(l10n.deliveryWorker)),
                  DropdownMenuItem(
                      value: 'onsite', child: Text(l10n.onsiteWorker)),
                ],
                onChanged: (value) {
                  if (value != null)
                    setState(() => _selectedWorkerType = value);
                },
              ),
              const SizedBox(height: 24),
            ],

            // Create Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: createUserState.isLoading ? null : _handleCreateUser,
                child: createUserState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(l10n.createUser),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateUser() async {
    if (!_formKey.currentState!.validate()) return;

    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) {
      phone = '+970${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      phone = '+970$phone';
    }
    
    final userData = {
      'username': _usernameController.text,
      'password': _passwordController.text,
      'full_name': _fullNameController.text,
      'phone_number': phone,
      'role': _selectedRoles,
      if (_emailController.text.isNotEmpty) 'email': _emailController.text,
      if (_selectedRoles.contains('client') &&
          _addressController.text.isNotEmpty)
        'address': _addressController.text,
      if (_selectedRoles.contains('client')) ...{
        'subscription_type': _subscriptionType,
        if (_subscriptionType == 'coupon_book') ...{
          'initial_coupons': _initialCoupons,
          'is_paid': _isPaid,
          'payment_method': _paymentMethod,
        },
      },
      if (_selectedRoles.contains('delivery_worker') ||
          _selectedRoles.contains('onsite_worker'))
        'worker_type': _selectedWorkerType,
    };

    await ref.read(createUserProvider.notifier).createUser(userData);

    final state = ref.read(createUserProvider);
    if (mounted) {
      state.when(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User created successfully')));
          widget.onUserCreated();
          Navigator.pop(context);
        },
        loading: () {},
        error: (error, _) {
          String message = error.toString().replaceAll('Exception: ', '');
          if (error is DioException) {
            final data = error.response?.data;
            if (data is Map && data.containsKey('message')) {
              message = data['message'];
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppTheme.iosRed),
          );
        },
      );
    }
  }
}

// Edit User Screen
class EditUserScreen extends ConsumerStatefulWidget {
  final User user;
  final VoidCallback onUserUpdated;

  const EditUserScreen(
      {super.key, required this.user, required this.onUserUpdated});

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _fullNameController;
  late TextEditingController _addressController;
  late TextEditingController _salaryController;
  late TextEditingController _advanceController;
  late TextEditingController _capacityController;
  int _initialCoupons = 100;

  List<String> _selectedRoles = [];
  String? _selectedWorkerType;
  String? _selectedSubscriptionType;
  bool _initialized = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _passwordController = TextEditingController();
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _selectedRoles = List<String>.from(widget.user.roles);

    final profile = widget.user.profile;
    _fullNameController = TextEditingController(text: profile?['full_name']);
    _addressController = TextEditingController(text: profile?['address']);
    _salaryController =
        TextEditingController(text: profile?['current_salary']?.toString());
    _advanceController =
        TextEditingController(text: profile?['debt_advances']?.toString() ?? '0');
    _capacityController = TextEditingController(
        text: profile?['vehicle_current_gallons']?.toString());
    _initialCoupons = profile?['coupon_book_size'] ?? profile?['remaining_coupons'] ?? 100;
    _selectedWorkerType = profile?['worker_type'];
    _selectedSubscriptionType = profile?['subscription_type'];
    _initialized = profile != null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    _advanceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailedUserAsync = ref.watch(userDetailsProvider(widget.user.id));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editUserInfo)),
      body: _initialized
          ? _buildEditForm(context)
          : detailedUserAsync.when(
              data: (user) {
                if (!_initialized) {
                  _selectedRoles = List<String>.from(user.roles);
                  if (user.profile != null) {
                    _fullNameController.text = user.profile!['full_name'] ?? '';
                    _addressController.text = user.profile!['address'] ?? '';
                    _salaryController.text =
                        user.profile!['current_salary']?.toString() ?? '';
                    _advanceController.text =
                        user.profile!['debt_advances']?.toString() ?? '0';
                    _capacityController.text =
                        user.profile!['vehicle_current_gallons']?.toString() ??
                            '';
                    _initialCoupons = user.profile!['remaining_coupons'] ?? 100;
                    _selectedWorkerType = user.profile!['worker_type'];
                    _selectedSubscriptionType =
                        user.profile!['subscription_type'];
                  }
                  _initialized = true;
                }
                return _buildEditForm(context);
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    final updateState = ref.watch(updateUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle(context, l10n.basicInformation),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
                labelText: '${l10n.username} *',
                prefixIcon: const Icon(Icons.person_rounded)),
            validator: (v) => v!.isEmpty ? l10n.required : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '${l10n.newPassword} (${l10n.optional})',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
                labelText: '${l10n.phone} *',
                hintText: '05xxxxxxxx',
                prefixIcon: const Icon(Icons.phone_rounded)),
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.required;
              if (!RegExp(r'^05\d{8}$').hasMatch(v)) {
                return 'Phone must be 05xxxxxxxx format';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_rounded)),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, l10n.assignRoles),
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                'client',
                'delivery_worker',
                'onsite_worker',
                'administrator',
                'owner'
              ].map((role) {
                return CheckboxListTile(
                  title: Text(_getRoleDisplay(context, role),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  value: _selectedRoles.contains(role),
                  activeColor: AppTheme.primary,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        // Check if we are adding a worker role for the first time
                        bool hadWorkerRole =
                            _selectedRoles.contains('onsite_worker') ||
                                _selectedRoles.contains('delivery_worker');

                        _selectedRoles.add(role);

                        // Only auto-select worker type if no worker role was previously selected
                        if (!hadWorkerRole) {
                          if (role == 'onsite_worker')
                            _selectedWorkerType = 'onsite';
                          if (role == 'delivery_worker')
                            _selectedWorkerType = 'delivery';
                        }
                      } else {
                        if (_selectedRoles.length > 1) {
                          _selectedRoles.remove(role);
                        }
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, l10n.profileDetails),
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
                labelText: '${l10n.fullName} *',
                prefixIcon: const Icon(Icons.badge_rounded)),
            validator: (v) => v!.isEmpty ? l10n.required : null,
          ),
          if (_selectedRoles.contains('client')) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                  labelText: l10n.address,
                  prefixIcon: const Icon(Icons.location_on_rounded)),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: ['coupon_book', 'cash'].contains(_selectedSubscriptionType)
                  ? _selectedSubscriptionType
                  : 'coupon_book',
              decoration: InputDecoration(
                  labelText: l10n.subscription,
                  prefixIcon: const Icon(Icons.card_membership_rounded)),
              items: [
                DropdownMenuItem(
                    value: 'coupon_book', child: Text(l10n.coupons)),
                DropdownMenuItem(value: 'cash', child: Text(l10n.payAsYouGo)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedSubscriptionType = v);
              },
            ),
            if (_selectedSubscriptionType == 'coupon_book') ...[
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final couponSizesAsync = ref.watch(couponSizesProvider);
                  return couponSizesAsync.when(
                    data: (sizes) {
                      final allSizes = {...sizes, _initialCoupons}.toList()..sort();
                      return DropdownButtonFormField<int>(
                        value: _initialCoupons,
                        decoration: InputDecoration(
                            labelText: l10n.coupons,
                            prefixIcon: const Icon(Icons.confirmation_number_rounded)),
                        items: allSizes.map((size) {
                          return DropdownMenuItem(
                              value: size, child: Text('$size ${l10n.coupons}'));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _initialCoupons = value);
                        },
                      );
                    },
                    loading: () => DropdownButtonFormField<int>(
                      value: _initialCoupons,
                      decoration: InputDecoration(
                          labelText: l10n.coupons,
                          prefixIcon: const Icon(Icons.confirmation_number_rounded)),
                      items: [_initialCoupons].map((size) {
                        return DropdownMenuItem(
                            value: size, child: Text('$size ${l10n.coupons}'));
                      }).toList(),
                      onChanged: null,
                    ),
                    error: (_, __) => DropdownButtonFormField<int>(
                      value: _initialCoupons,
                      decoration: InputDecoration(
                          labelText: l10n.coupons,
                          prefixIcon: const Icon(Icons.confirmation_number_rounded)),
                      items: {100, 200, 300, _initialCoupons}.map((size) {
                        return DropdownMenuItem(
                            value: size, child: Text('$size ${l10n.coupons}'));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _initialCoupons = value);
                      },
                    ),
                  );
                },
              ),
            ],
          ],
          if (_selectedRoles.contains('delivery_worker') ||
              _selectedRoles.contains('onsite_worker')) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: ['delivery', 'onsite'].contains(_selectedWorkerType)
                  ? _selectedWorkerType
                  : (_selectedRoles.contains('delivery_worker')
                      ? 'delivery'
                      : 'onsite'),
              decoration: InputDecoration(
                  labelText: l10n.workerType,
                  prefixIcon: const Icon(Icons.work_outline_rounded)),
              items: [
                DropdownMenuItem(
                    value: 'delivery', child: Text(l10n.deliveryWorker)),
                DropdownMenuItem(
                    value: 'onsite', child: Text(l10n.onsiteWorker)),
              ],
              onChanged: (v) => setState(() => _selectedWorkerType = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _salaryController,
              decoration: InputDecoration(
                  labelText: l10n.salary,
                  prefixIcon: const Icon(Icons.payments_rounded)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _advanceController,
              decoration: InputDecoration(
                  labelText: l10n.salaryAdvance,
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined)),
              keyboardType: TextInputType.number,
            ),
            if (_selectedRoles.contains('delivery_worker')) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(
                    labelText: '${l10n.vehicleCapacity} (${l10n.gallons})',
                    prefixIcon: const Icon(Icons.water_drop_rounded)),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
          const SizedBox(height: 32),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: updateState.isLoading ? null : _handleUpdate,
              child: updateState.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(l10n.saveChanges),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) {
      phone = '+970${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      phone = '+970$phone';
    }

    final data = {
      'username': _usernameController.text,
      if (_passwordController.text.isNotEmpty)
        'password': _passwordController.text,
      'phone_number': phone,
      'email': _emailController.text,
      'role': _selectedRoles,
      'full_name': _fullNameController.text,
      if (_selectedRoles.contains('client')) ...{
        'address': _addressController.text,
        'subscription_type': _selectedSubscriptionType,
        'remaining_coupons': _initialCoupons,
      },
      if (_selectedRoles.contains('delivery_worker') ||
          _selectedRoles.contains('onsite_worker')) ...{
        'worker_type': _selectedWorkerType,
        'current_salary': double.tryParse(_salaryController.text),
        'debt_advances': double.tryParse(_advanceController.text) ?? 0,
        if (_selectedRoles.contains('delivery_worker'))
          'vehicle_current_gallons': int.tryParse(_capacityController.text),
      },
    };

    await ref
        .read(updateUserProvider.notifier)
        .updateUser(widget.user.id, data);

    final state = ref.read(updateUserProvider);
    if (mounted) {
      state.when(
        data: (_) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.userUpdated)));
          widget.onUserUpdated();
          Navigator.pop(context);
        },
        loading: () {},
        error: (error, _) {
          String message = error.toString().replaceAll('Exception: ', '');
          if (error is DioException) {
            final data = error.response?.data;
            if (data is Map && data.containsKey('message')) {
              message = data['message'];
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppTheme.iosRed),
          );
        },
      );
    }
  }

}
