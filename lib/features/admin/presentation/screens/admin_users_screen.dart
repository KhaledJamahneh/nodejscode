// lib/features/admin/presentation/screens/admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../providers/users_provider.dart';
import '../../data/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final filter = ref.watch(usersFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor.withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.adminWorkerManagement, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add, size: 20),
            label: Text(l10n.addNew),
            onPressed: () {
              // TODO: Implement Add New Worker
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              _buildSearchBar(context, ref, filter),
              _buildFilterChips(context, ref, filter),
            ],
          ),
        ),
      ),
      body: usersAsync.when(
        data: (users) {
          final workers = users.where((u) => u.roles.any((r) => r.contains('worker'))).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              // Example of a selected worker for detail view
              if (index == 0) {
                return _SelectedWorkerCard(worker: workers[index]);
              }
              return _WorkerListCard(worker: workers[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
      ),
       bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, UsersFilter filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search delivery personnel...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // TODO: Show advanced filters
            },
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          ref.read(usersFilterProvider.notifier).state = filter.copyWith(search: value);
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, UsersFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: filter.onShift == null && filter.isActive == null,
            onSelected: (selected) {
               if(selected) ref.read(usersFilterProvider.notifier).state = filter.copyWith(clearOnShift: true, clearActive: true);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('On Delivery'),
            selected: filter.onShift == true,
             onSelected: (selected) {
               if(selected) ref.read(usersFilterProvider.notifier).state = filter.copyWith(onShift: true, isActive: true);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Available'),
            selected: filter.onShift == false && filter.isActive == true,
             onSelected: (selected) {
                if(selected) ref.read(usersFilterProvider.notifier).state = filter.copyWith(onShift: false, isActive: true);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Off Duty'),
            selected: filter.isActive == false,
             onSelected: (selected) {
               if(selected) ref.read(usersFilterProvider.notifier).state = filter.copyWith(isActive: false, clearOnShift: true);
            },
          ),
        ],
      ),
    );
  }
}

class _SelectedWorkerCard extends StatelessWidget {
  final User worker;
  const _SelectedWorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 28, /* TODO: Add image */),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(worker.profile?['full_name'] ?? worker.username, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const Row(
                          children: [
                            Chip(label: Text('On Delivery', style: TextStyle(fontSize: 10)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                            SizedBox(width: 8),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Text('4.9'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 16),
            // TODO: Replace with actual map widget
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text('Map Preview')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.list_alt), label: const Text('View Orders'), onPressed: (){})),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.map_outlined), label: const Text('Track Live'), onPressed: (){})),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerListCard extends StatelessWidget {
  final User worker;
  const _WorkerListCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: const CircleAvatar(radius: 24, /* TODO: Add image */),
        title: Text(worker.profile?['full_name'] ?? worker.username, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Available • 4.5 ★'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Show selected worker view
        },
      ),
    );
  }
}

Widget _buildBottomNav(BuildContext context) {
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: 1, // Workers tab
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Workers'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Orders'),
      BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
    ],
     onTap: (index) {
        switch (index) {
          case 0:
            context.go('/admin/home');
            break;
          case 1:
             context.go('/admin/users');
            break;
          case 2:
             context.go('/admin/requests');
            break;
          case 3:
            // Add navigation to settings
            break;
        }
      },
  );
}
