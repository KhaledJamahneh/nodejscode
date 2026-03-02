import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../data/models/schedule_model.dart';
import '../../providers/schedules_provider.dart';
import '../../providers/users_provider.dart';

class ScheduleFormSheet extends ConsumerStatefulWidget {
  final ScheduledDelivery? schedule;

  const ScheduleFormSheet({super.key, this.schedule});

  @override
  ConsumerState<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends ConsumerState<ScheduleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final Set<int> _clientIds = {};
  late int _gallons;
  late ScheduleType _type;
  late TimeOfDay _time;
  late DateTime _startDate;
  DateTime? _endDate;
  final Set<int> _days = {};
  int? _freqWeek;
  int? _freqMonth;
  String? _notes;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    if (s != null) _clientIds.addAll(s.clientIds);
    _gallons = s?.gallons ?? 5;
    _type = s?.scheduleType ?? ScheduleType.weekly;
    _time = s != null ? _parseTime(s.scheduleTime) : const TimeOfDay(hour: 9, minute: 0);
    _startDate = s?.startDate ?? DateTime.now();
    _endDate = s?.endDate;
    if (s?.scheduleDays != null) _days.addAll(s!.scheduleDays!);
    _freqWeek = s?.frequencyPerWeek;
    _freqMonth = s?.frequencyPerMonth;
    _notes = s?.notes;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    final l10n = AppLocalizations.of(context)!;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? l10n.am : l10n.pm;
    return '$hour:$minute $period';
  }

  String _getTypeDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_type) {
      case ScheduleType.daily:
        return l10n.deliveryEveryDay;
      case ScheduleType.weekly:
        return l10n.deliveryOnSelectedDaysEachWeek;
      case ScheduleType.biweekly:
        return l10n.deliveryOnSelectedDaysEveryOtherWeek;
      case ScheduleType.monthly:
        return l10n.deliveryXTimesPerMonth;
      case ScheduleType.custom:
        return l10n.customIrregularSchedule;
    }
  }

  void _showClientPicker(BuildContext context, List<dynamic> clients) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String search = '';
          final filtered = clients.where((c) {
            final name = (c.profile?['name'] ?? c.username).toString().toLowerCase();
            return name.contains(search.toLowerCase());
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.searchClients,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setModalState(() => search = v),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: filtered.map((c) {
                      final clientId = c.profile!['id'] as int;
                      return CheckboxListTile(
                        title: Text(c.profile?['name'] ?? c.username),
                        value: _clientIds.contains(clientId),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) _clientIds.add(clientId); else _clientIds.remove(clientId);
                          });
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.doneSelected(_clientIds.length)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usersAsync = ref.watch(usersProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.schedule == null ? l10n.addSchedule : l10n.editSchedule, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              usersAsync.when(
                data: (users) {
                  final clients = users.where((u) => u.roles.contains('client') && u.profile != null && u.profile!['id'] != null).toList();
                  if (clients.isEmpty) {
                    return Text(l10n.noClientsAvailable);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.clients}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showClientPicker(context, clients),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _clientIds.isEmpty
                              ? Text(l10n.tapToSelectClients, style: const TextStyle(color: Colors.grey))
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _clientIds.map((id) {
                                    final client = clients.firstWhere((c) => c.profile!['id'] == id);
                                    return Chip(
                                      label: Text(client.profile?['name'] ?? client.username),
                                      deleteIcon: const Icon(Icons.close, size: 18),
                                      onDeleted: () => setState(() => _clientIds.remove(id)),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                      if (_clientIds.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(l10n.selectAtLeastOneClient, style: TextStyle(color: Colors.red[700], fontSize: 12)),
                        ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => Text(l10n.error),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _gallons.toString(),
                decoration: InputDecoration(labelText: l10n.gallons),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? l10n.required : null,
                onSaved: (v) => _gallons = int.parse(v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ScheduleType>(
                value: _type,
                decoration: InputDecoration(labelText: l10n.scheduleType),
                items: ScheduleType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label(context)))).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 8),
              Text(
                _getTypeDescription(context),
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
              if (_type == ScheduleType.weekly || _type == ScheduleType.biweekly) ...[
                const SizedBox(height: 16),
                Text('${l10n.selectDays}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 0; i < 7; i++)
                      FilterChip(
                        label: Text([l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat][i]),
                        selected: _days.contains(i),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _days.add(i);
                              // Auto-switch to daily if all 7 days selected
                              if (_days.length == 7 && _type == ScheduleType.weekly) {
                                _type = ScheduleType.daily;
                                _days.clear();
                              }
                            } else {
                              _days.remove(i);
                            }
                          });
                        },
                      ),
                  ],
                ),
                if (_days.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l10n.selectAtLeastOneDay, style: TextStyle(color: Colors.red[700], fontSize: 12)),
                  ),
              ],
              if (_type == ScheduleType.monthly) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _freqMonth?.toString() ?? '4',
                  decoration: InputDecoration(labelText: l10n.timesPerMonth),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _freqMonth = int.tryParse(v ?? '4'),
                ),
              ],
              if (_type == ScheduleType.custom) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _freqWeek?.toString() ?? '',
                        decoration: InputDecoration(labelText: l10n.everyNDays, hintText: 'e.g., 3'),
                        keyboardType: TextInputType.number,
                        onSaved: (v) => _freqWeek = int.tryParse(v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _freqMonth?.toString() ?? '',
                        decoration: InputDecoration(labelText: l10n.nTimes, hintText: 'e.g., 2'),
                        keyboardType: TextInputType.number,
                        onSaved: (v) => _freqMonth = int.tryParse(v ?? ''),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.customScheduleExample,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                title: Text(l10n.time),
                subtitle: Text(_formatTime(context, _time)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: _time);
                  if (t != null) setState(() => _time = t);
                },
              ),
              ListTile(
                title: Text(l10n.startDate),
                subtitle: Text('${_startDate.year}-${_startDate.month}-${_startDate.day}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) setState(() => _startDate = d);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _notes,
                decoration: InputDecoration(labelText: l10n.notes),
                maxLines: 2,
                onSaved: (v) => _notes = v,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel))),
                  const SizedBox(width: 16),
                  Expanded(child: ElevatedButton(onPressed: _save, child: Text(l10n.save))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_clientIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectAtLeastOneClient)));
      return;
    }
    _formKey.currentState!.save();

    final payload = {
      'client_id': _clientIds.toList(),
      'gallons': _gallons,
      'schedule_type': _type.key,
      'schedule_time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00',
      'start_date': '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
      if (_endDate != null) 'end_date': '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
      if (_days.isNotEmpty) 'schedule_days': _days.toList(),
      if (_freqWeek != null) 'frequency_per_week': _freqWeek,
      if (_freqMonth != null) 'frequency_per_month': _freqMonth,
      if (_notes != null && _notes!.isNotEmpty) 'notes': _notes,
      'is_active': true,
    };

    try {
      if (widget.schedule == null) {
        await ref.read(schedulesProvider.notifier).create(payload);
      } else {
        await ref.read(schedulesProvider.notifier).update(widget.schedule!.id, payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }
}
