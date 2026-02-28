import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/schedules_provider.dart';
import '../providers/admin_provider.dart';
import '../../data/models/schedule_model.dart';
import 'widgets/schedule_form_sheet.dart';

class AdminSchedulesScreen extends ConsumerStatefulWidget {
  const AdminSchedulesScreen({super.key});

  @override
  ConsumerState<AdminSchedulesScreen> createState() => _AdminSchedulesScreenState();
}

class _AdminSchedulesScreenState extends ConsumerState<AdminSchedulesScreen> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schedulesAsync = ref.watch(filteredSchedulesProvider);
    final stats = ref.watch(scheduleStatsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _AppBar(l10n: l10n, selectedCount: _selected.length, onClear: () => setState(() => _selected.clear())),
          SliverToBoxAdapter(child: _StatsBar(stats: stats)),
          SliverToBoxAdapter(child: _FilterBar()),
          schedulesAsync.when(
            data: (schedules) => _SchedulesList(schedules: schedules, selected: _selected, onToggle: (id) {
              setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
            }),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      floatingActionButton: _selected.isEmpty ? FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addSchedule),
        backgroundColor: AppTheme.primary,
      ) : null,
      bottomNavigationBar: _selected.isNotEmpty ? _BatchBar(selected: _selected, onClear: () => setState(() => _selected.clear())) : null,
    );
  }

  void _showForm(BuildContext context, [ScheduledDelivery? schedule]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScheduleFormSheet(schedule: schedule),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final AppLocalizations l10n;
  final int selectedCount;
  final VoidCallback onClear;

  const _AppBar({required this.l10n, required this.selectedCount, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar(
      floating: true,
      title: Text(selectedCount > 0 ? '$selectedCount ${l10n.selected}' : l10n.schedules),
      leading: selectedCount > 0 ? IconButton(icon: const Icon(Icons.close), onPressed: onClear) : null,
      actions: [
        Consumer(
          builder: (context, ref, _) => IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(schedulesProvider.notifier).load(),
          ),
        ),
      ],
    );
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final ScheduleStats stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: l10n.total, value: '${stats.total}'),
          _StatItem(label: l10n.active, value: '${stats.active}'),
          _StatItem(label: l10n.weeklyGallons, value: '${stats.weeklyGallons}'),
          _StatItem(label: l10n.avgPerClient, value: '${stats.avgGallonsPerClient.toStringAsFixed(1)}'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(scheduleFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: l10n.searchSchedules,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => ref.read(scheduleFilterProvider.notifier).state = filter.copyWith(search: v),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DateFilterChip(filter: filter),
                const SizedBox(width: 8),
                _AnimatedFilterChip(
                  label: l10n.all,
                  selected: filter.type == null && filter.active == null,
                  onTap: () => ref.read(scheduleFilterProvider.notifier).state = filter.copyWith(clearType: true, clearActive: true),
                ),
                const SizedBox(width: 8),
                ...ScheduleType.values.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _AnimatedFilterChip(
                    label: t.label(context),
                    selected: filter.type == t,
                    onTap: () => ref.read(scheduleFilterProvider.notifier).state = filter.copyWith(type: t, clearActive: true),
                  ),
                )),
                _AnimatedFilterChip(
                  label: l10n.active,
                  selected: filter.active == true,
                  onTap: () => ref.read(scheduleFilterProvider.notifier).state = filter.copyWith(active: filter.active == true ? null : true, clearType: true, clearActive: filter.active == true),
                ),
                const SizedBox(width: 8),
                _AnimatedFilterChip(
                  label: l10n.inactive,
                  selected: filter.active == false,
                  onTap: () => ref.read(scheduleFilterProvider.notifier).state = filter.copyWith(active: filter.active == false ? null : false, clearType: true, clearActive: filter.active == false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _AnimatedFilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: selected ? AppTheme.primary : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey[700]),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey[700],
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateFilterChip extends ConsumerWidget {
  final ScheduleFilter filter;

  const _DateFilterChip({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final isToday = filter.startDate != null && 
                    filter.startDate!.year == now.year &&
                    filter.startDate!.month == now.month &&
                    filter.startDate!.day == now.day &&
                    filter.endDate == null;
    
    String label;
    if (filter.startDate == null) {
      label = l10n.date;
    } else if (isToday) {
      label = l10n.today;
    } else if (filter.endDate == null) {
      label = '${filter.startDate!.month}/${filter.startDate!.day}';
    } else {
      label = '${filter.startDate!.month}/${filter.startDate!.day}-${filter.endDate!.month}/${filter.endDate!.day}';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: filter.startDate != null ? AppTheme.primary : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () async {
            if (filter.startDate != null) {
              ref.read(scheduleFilterProvider.notifier).state = filter.copyWith(clearDates: true);
            } else {
              _showDateOptions(context, ref, filter);
            }
          },
          onLongPress: () => _showDateOptions(context, ref, filter),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today, 
                  size: 18, 
                  color: filter.startDate != null ? Colors.white : Colors.grey[700],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: filter.startDate != null ? Colors.white : Colors.grey[700],
                    fontWeight: filter.startDate != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDateOptions(BuildContext context, WidgetRef ref, ScheduleFilter filter) {
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
                ref.read(scheduleFilterProvider.notifier).state = filter.copyWith(startDate: DateTime.now(), endDate: null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.singleDate),
              onTap: () async {
                Navigator.pop(context);
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  ref.read(scheduleFilterProvider.notifier).state = filter.copyWith(startDate: date, endDate: null);
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
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (range != null) {
                  ref.read(scheduleFilterProvider.notifier).state = filter.copyWith(
                    startDate: range.start,
                    endDate: range.end,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Schedules List ────────────────────────────────────────────────────────────
class _SchedulesList extends StatelessWidget {
  final List<ScheduledDelivery> schedules;
  final Set<int> selected;
  final Function(int) onToggle;

  const _SchedulesList({required this.schedules, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (schedules.isEmpty) {
      return SliverFillRemaining(child: Center(child: Text(l10n.noSchedulesFound)));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _ScheduleCard(schedule: schedules[i], isSelected: selected.contains(schedules[i].id), onToggle: () => onToggle(schedules[i].id)),
        childCount: schedules.length,
      ),
    );
  }
}

class _ScheduleCard extends ConsumerWidget {
  final ScheduledDelivery schedule;
  final bool isSelected;
  final VoidCallback onToggle;

  const _ScheduleCard({required this.schedule, required this.isSelected, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Checkbox(value: isSelected, onChanged: (_) => onToggle()),
        title: InkWell(
          onTap: () => _showClientInfo(context, ref, schedule.clientIds.first, schedule.clientName),
          child: Text(schedule.clientName, style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${schedule.gallons} ${l10n.gal} • ${schedule.repeatSummary}'),
            Text('${schedule.formattedTime} • ${schedule.statusLabel}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditSheet(context, schedule),
            ),
            Switch(
              value: schedule.isActive,
              onChanged: (_) => ref.read(schedulesProvider.notifier).toggleActive(schedule),
            ),
          ],
        ),
        onTap: onToggle,
      ),
    );
  }

  void _showEditSheet(BuildContext context, ScheduledDelivery schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScheduleFormSheet(schedule: schedule),
    );
  }
}

// ── Batch Actions Bar ─────────────────────────────────────────────────────────
class _BatchBar extends ConsumerWidget {
  final Set<int> selected;
  final VoidCallback onClear;

  const _BatchBar({required this.selected, required this.onClear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.delete),
            label: Text(l10n.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(l10n.deleteSchedules),
                  content: Text(l10n.deleteSchedulesConfirm(selected.length)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.delete)),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(schedulesProvider.notifier).batchDelete(selected.toList());
                onClear();
              }
            },
          ),
        ],
      ),
    );
  }
}

void _showClientInfo(BuildContext context, WidgetRef ref, int clientId, String clientName) {
  showDialog(
    context: context,
    builder: (context) => _ClientInfoDialog(clientId: clientId, clientName: clientName),
  );
}

class _ClientInfoDialog extends ConsumerStatefulWidget {
  final int clientId;
  final String clientName;

  const _ClientInfoDialog({required this.clientId, required this.clientName});

  @override
  ConsumerState<_ClientInfoDialog> createState() => _ClientInfoDialogState();
}

class _ClientInfoDialogState extends ConsumerState<_ClientInfoDialog> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(widget.clientName),
      content: Text(l10n.client),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
