import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';
import '../providers/admin_provider.dart';
import 'barcode_scanner_screen.dart';

final _dispensersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(adminServiceProvider);
  return await service.getDispensers();
});

final _searchQueryProvider = StateProvider<String>((ref) => '');
final _statusFilterProvider = StateProvider<String?>((ref) => null);
final _assignmentFilterProvider = StateProvider<String?>((ref) => null);

class AdminAssetsScreen extends ConsumerStatefulWidget {
  const AdminAssetsScreen({super.key});

  @override
  ConsumerState<AdminAssetsScreen> createState() => _AdminAssetsScreenState();
}

class _AdminAssetsScreenState extends ConsumerState<AdminAssetsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );
      
      if (result != null && result is String) {
        _searchController.text = result;
        ref.read(_searchQueryProvider.notifier).state = result;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dispensersAsync = ref.watch(_dispensersProvider);
    final searchQuery = ref.watch(_searchQueryProvider);
    final statusFilter = ref.watch(_statusFilterProvider);
    final assignmentFilter = ref.watch(_assignmentFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dispensers),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '${l10n.search}...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => ref.read(_searchQueryProvider.notifier).state = value,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: statusFilter,
                    decoration: InputDecoration(
                      labelText: l10n.status,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      DropdownMenuItem(value: 'new', child: Text(l10n.newItem)),
                      DropdownMenuItem(value: 'used', child: Text(l10n.used)),
                      DropdownMenuItem(value: 'disabled', child: Text(l10n.disabled)),
                      DropdownMenuItem(value: 'in_maintenance', child: Text(l10n.maintenance)),
                    ],
                    onChanged: (val) => ref.read(_statusFilterProvider.notifier).state = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: assignmentFilter,
                    decoration: InputDecoration(
                      labelText: l10n.assignment,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      DropdownMenuItem(value: 'assigned', child: Text(l10n.assigned)),
                      DropdownMenuItem(value: 'unassigned', child: Text(l10n.unassigned)),
                    ],
                    onChanged: (val) => ref.read(_assignmentFilterProvider.notifier).state = val,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dispensersAsync.when(
              data: (dispensers) {
                // Apply filters
                var filtered = dispensers.where((d) {
                  final matchesSearch = searchQuery.isEmpty || 
                    (d['serial_number'] ?? '').toLowerCase().contains(searchQuery.toLowerCase());
                  final matchesStatus = statusFilter == null || d['status'] == statusFilter;
                  final isAssigned = d['current_client_id'] != null;
                  final matchesAssignment = assignmentFilter == null ||
                    (assignmentFilter == 'assigned' && isAssigned) ||
                    (assignmentFilter == 'unassigned' && !isAssigned);
                  return matchesSearch && matchesStatus && matchesAssignment;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text('${l10n.no} ${l10n.dispensers}'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final dispenser = filtered[index];
                    final isAssigned = dispenser['current_client_id'] != null;
                  
                  return ModernCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _showDispenserInfoDialog(context, dispenser['id']),
                      child: ListTile(
                        leading: Icon(
                          Icons.water_drop_rounded,
                          color: isAssigned ? AppTheme.primary : Colors.grey,
                        ),
                        title: Text('${dispenser['serial_number']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l10n.types}: ${dispenser['type_name'] ?? l10n.none} • ${l10n.status}: ${_getStatusDisplay(l10n, dispenser['status'])}'),
                            if (isAssigned)
                              Text('${l10n.assignedTo}: ${dispenser['client_name']}', 
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (dispenser['current_client_id'] == null)
                              IconButton(
                                icon: const Icon(Icons.person_add, size: 20, color: AppTheme.primary),
                                onPressed: () => _showQuickAssignDialog(context, ref, dispenser),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => context.push('/admin/dispenser-detail/${dispenser['id']}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _deleteDispenser(context, ref, dispenser['id']),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
              },
              loading: () => const Center(child: CircularProgressIndicator.adaptive()),
              error: (_, __) => Center(child: Text('${l10n.error}: ${l10n.dispensers}')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/dispenser-detail'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDispenserDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? dispenser) async {
    final l10n = AppLocalizations.of(context)!;
    final clients = await ref.read(adminServiceProvider).getClients();
    final types = await ref.read(adminServiceProvider).getDispenserTypes();
    final features = await ref.read(adminServiceProvider).getDispenserFeatures();
    
    final serialController = TextEditingController(text: dispenser?['serial_number']);
    int? selectedTypeId = dispenser?['type_id'] as int?;
    String selectedStatus = dispenser?['status'] ?? 'new';
    List<int> selectedFeatures = List<int>.from(dispenser?['features'] ?? []);
    
    // Validate status exists in dropdown
    const validStatuses = ['new', 'active', 'maintenance', 'retired'];
    if (!validStatuses.contains(selectedStatus)) {
      selectedStatus = 'active';
    }
    
    int? selectedClientId = dispenser?['current_client_id'] as int?;
    
    // Validate that selectedClientId exists in clients list
    if (selectedClientId != null && !clients.any((c) => c['id'] == selectedClientId)) {
      selectedClientId = null;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(dispenser == null ? 'Add Dispenser' : 'Edit Dispenser'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: serialController,
                  decoration: const InputDecoration(labelText: 'Serial Number'),
                ),
                const SizedBox(height: 16),
                if (types.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    value: selectedTypeId,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('No Type')),
                      ...types.map<DropdownMenuItem<int?>>((t) => DropdownMenuItem<int?>(
                        value: t['id'] as int,
                        child: Text(t['name']),
                      )),
                    ],
                    onChanged: (val) => setState(() => selectedTypeId = val),
                  ),
                const SizedBox(height: 16),
                if (features.isNotEmpty) ...[
                  const Text('Enabled Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...features.map((f) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(f['name']),
                    value: selectedFeatures.contains(f['id']),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedFeatures.add(f['id'] as int);
                        } else {
                          selectedFeatures.remove(f['id']);
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 8),
                ],
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'new', child: Text('New')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                    DropdownMenuItem(value: 'retired', child: Text('Retired')),
                  ],
                  onChanged: (val) => setState(() => selectedStatus = val!),
                ),
                const SizedBox(height: 16),
                if (clients.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    value: selectedClientId,
                    decoration: const InputDecoration(labelText: 'Assigned Client'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
                      ...clients.map<DropdownMenuItem<int?>>((c) => DropdownMenuItem<int?>(
                        value: c['id'] as int,
                        child: Text(c['full_name'] ?? ''),
                      )),
                    ],
                    onChanged: (val) => setState(() => selectedClientId = val),
                  )
                else
                  const Text('No clients available'),
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
                if (dispenser == null) {
                  await ref.read(adminServiceProvider).createDispenser(
                    serialController.text,
                    selectedTypeId,
                    selectedFeatures,
                    selectedStatus,
                    selectedClientId,
                  );
                } else {
                  await ref.read(adminServiceProvider).updateDispenser(
                    dispenser['id'],
                    serialController.text,
                    selectedTypeId,
                    selectedFeatures,
                    selectedStatus,
                    selectedClientId,
                  );
                }
                if (context.mounted) Navigator.pop(context);
                ref.invalidate(_dispensersProvider);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuickAssignDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> dispenser) async {
    final l10n = AppLocalizations.of(context)!;
    final clients = await ref.read(adminServiceProvider).getUsers(role: 'client', limit: 1000);
    int? selectedClientId;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${l10n.assign} ${l10n.dispensers}'),
          content: DropdownButtonFormField<int>(
            value: selectedClientId,
            decoration: InputDecoration(labelText: '${l10n.client} *'),
            items: clients.where((c) => c['profile'] != null).map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
              value: c['profile']['id'],
              child: Text(c['username']),
            )).toList(),
            onChanged: (v) => setState(() => selectedClientId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedClientId == null) return;
                try {
                  await ref.read(adminServiceProvider).updateDispenser(
                    dispenser['id'],
                    dispenser['serial_number'],
                    dispenser['type_id'],
                    List<int>.from(dispenser['features'] ?? []),
                    'used',
                    selectedClientId,
                  );
                  ref.invalidate(_dispensersProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.assigned)),
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
              child: Text(l10n.assign),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDispenser(BuildContext context, WidgetRef ref, int dispenserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dispenser'),
        content: const Text('Are you sure you want to delete this dispenser?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(adminServiceProvider).deleteDispenser(dispenserId);
      ref.invalidate(_dispensersProvider);
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
                _buildInfoRow(l10n.status, _getStatusDisplay(l10n, dispenser['status'] ?? '')),
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

  String _getStatusDisplay(AppLocalizations l10n, String status) {
    switch (status) {
      case 'new': return l10n.newItem;
      case 'used': return l10n.used;
      case 'disabled': return l10n.disabled;
      case 'in_maintenance': return l10n.maintenance;
      default: return status;
    }
  }
}
