// lib/features/admin/presentation/screens/admin_shifts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/shift_model.dart';
import '../providers/admin_provider.dart';

final shiftsProvider = FutureProvider<List<WorkShift>>((ref) async {
  final service = ref.read(adminServiceProvider);
  final data = await service.getShifts();
  return data.map((s) => WorkShift.fromJson(s)).toList();
});

class AdminShiftsScreen extends ConsumerWidget {
  const AdminShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workShifts)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showShiftDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: shiftsAsync.when(
        data: (shifts) => shifts.isEmpty
            ? Center(child: Text(l10n.noShifts))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: shifts.length,
                itemBuilder: (context, index) {
                  final shift = shifts[index];
                  final displayName = _getShiftDisplayName(context, shift.name);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        Icons.schedule_rounded,
                        color: shift.isActive ? AppTheme.primary : AppTheme.iosGray,
                      ),
                      title: Text(displayName),
                      subtitle: Text('${shift.daysDisplayLocalized(context)}\n${shift.timeDisplay(Localizations.localeOf(context).languageCode)}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                          PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showShiftDialog(context, ref, shift);
                          } else if (value == 'delete') {
                            _deleteShift(context, ref, shift.id);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      ),
    );
  }

  void _showShiftDialog(BuildContext context, WidgetRef ref, WorkShift? shift) {
    final l10n = AppLocalizations.of(context)!;
    final isCustom = shift != null && !['Morning Shift', 'Evening Shift', 'Full Day'].contains(shift.name);
    final nameController = TextEditingController(text: isCustom ? shift.name : '');
    final startController = TextEditingController(text: shift?.startTime ?? '08:00:00');
    final endController = TextEditingController(text: shift?.endTime ?? '16:00:00');
    final selectedDays = Set<int>.from(shift?.daysOfWeek ?? [1, 2, 3, 4, 5]);
    String? selectedPreset = shift != null && !isCustom ? shift.name : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(shift == null ? l10n.createShift : l10n.editShift),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (shift == null || isCustom) ...[
                  DropdownButtonFormField<String?>(
                    value: selectedPreset,
                    decoration: InputDecoration(labelText: l10n.shiftName),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.custom)),
                      DropdownMenuItem(value: 'Morning Shift', child: Text(l10n.morningShift)),
                      DropdownMenuItem(value: 'Evening Shift', child: Text(l10n.eveningShift)),
                      DropdownMenuItem(value: 'Full Day', child: Text(l10n.fullDay)),
                    ],
                    onChanged: (value) => setState(() => selectedPreset = value),
                  ),
                  if (selectedPreset == null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: '${l10n.custom} ${l10n.shiftName}'),
                    ),
                  ],
                ] else
                  Text(_getShiftDisplayName(context, shift.name), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: startController,
                  decoration: InputDecoration(labelText: '${l10n.startTime} (HH:mm:ss)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endController,
                  decoration: InputDecoration(labelText: '${l10n.endTime} (HH:mm:ss)'),
                ),
                const SizedBox(height: 16),
                Text(l10n.daysOfWeek, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < 7; i++)
                      FilterChip(
                        label: Text([l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat][i]),
                        selected: selectedDays.contains(i),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(i);
                            } else {
                              selectedDays.remove(i);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final shiftName = selectedPreset ?? nameController.text;
                if (shiftName.isEmpty) return;

                final service = ref.read(adminServiceProvider);
                final data = {
                  'name': shiftName,
                  'days_of_week': selectedDays.toList()..sort(),
                  'start_time': startController.text,
                  'end_time': endController.text,
                  'is_active': true,
                };

                if (shift == null) {
                  await service.createShift(data);
                } else {
                  await service.updateShift(shift.id, data);
                }

                ref.invalidate(shiftsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(shift == null ? l10n.shiftCreated : l10n.shiftUpdated)),
                  );
                }
              },
              child: Text(shift == null ? l10n.createShift : l10n.update),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteShift(BuildContext context, WidgetRef ref, int id) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteShift),
        content: Text(l10n.deleteShiftConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.iosRed),
            onPressed: () async {
              final service = ref.read(adminServiceProvider);
              await service.deleteShift(id);
              ref.invalidate(shiftsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.shiftDeleted)),
                );
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  String _getShiftDisplayName(BuildContext context, String shiftName) {
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
}
