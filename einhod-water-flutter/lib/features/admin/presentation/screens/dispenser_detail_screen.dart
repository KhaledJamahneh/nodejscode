import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';
import '../providers/admin_provider.dart';
import 'barcode_scanner_screen.dart';

class DispenserDetailScreen extends ConsumerStatefulWidget {
  final int? dispenserId;

  const DispenserDetailScreen({super.key, this.dispenserId});

  @override
  ConsumerState<DispenserDetailScreen> createState() => _DispenserDetailScreenState();
}

class _DispenserDetailScreenState extends ConsumerState<DispenserDetailScreen> {
  final _serialController = TextEditingController();
  int? _selectedTypeId;
  List<int> _selectedFeatures = [];
  String _selectedStatus = 'new';
  int? _selectedClientId;
  
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _features = [];
  List<Map<String, dynamic>> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final service = ref.read(adminServiceProvider);
      _types = await service.getDispenserTypes();
      _features = await service.getDispenserFeatures();
      _clients = await service.getClients();
      
      if (widget.dispenserId != null) {
        final dispensers = await service.getDispensers();
        final dispenser = dispensers.firstWhere((d) => d['id'] == widget.dispenserId);
        _serialController.text = dispenser['serial_number'] ?? '';
        _selectedTypeId = dispenser['type_id'] as int?;
        _selectedFeatures = List<int>.from(dispenser['features'] ?? []);
        
        // Validate status
        final status = dispenser['status'] ?? 'new';
        const validStatuses = ['new', 'used', 'disabled', 'in_maintenance'];
        _selectedStatus = validStatuses.contains(status) ? status : 'used';
        
        _selectedClientId = dispenser['current_client_id'] as int?;
      }
      
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dispenserId == null ? '${l10n.add} ${l10n.dispensers}' : '${l10n.edit} ${l10n.dispensers}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/admin/dispenser-settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.basicInformation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _serialController,
                          decoration: InputDecoration(
                            labelText: l10n.serialNumber,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _scanBarcode,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: l10n.status,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(value: 'new', child: Text(l10n.newItem)),
                            DropdownMenuItem(value: 'used', child: Text(l10n.used)),
                            DropdownMenuItem(value: 'disabled', child: Text(l10n.disabled)),
                            DropdownMenuItem(value: 'in_maintenance', child: Text(l10n.maintenance)),
                          ],
                          onChanged: (val) => setState(() => _selectedStatus = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.types, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (_types.isEmpty)
                          Text('${l10n.no} ${l10n.types}. ${l10n.add} ${l10n.types} ${l10n.inSettings}.')
                        else
                          DropdownButtonFormField<int?>(
                            value: _selectedTypeId,
                            decoration: InputDecoration(
                              labelText: '${l10n.dispensers} ${l10n.types}',
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem<int?>(value: null, child: Text('${l10n.no} ${l10n.types}')),
                              ..._types.map<DropdownMenuItem<int?>>((t) => DropdownMenuItem<int?>(
                                value: t['id'] as int,
                                child: Text(t['name']),
                              )),
                            ],
                            onChanged: (val) => setState(() => _selectedTypeId = val),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.features, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_features.isEmpty)
                          Text('${l10n.no} ${l10n.features}. ${l10n.add} ${l10n.features} ${l10n.inSettings}.')
                        else
                          ..._features.map((f) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(f['name']),
                            value: _selectedFeatures.contains(f['id']),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedFeatures.add(f['id'] as int);
                                } else {
                                  _selectedFeatures.remove(f['id']);
                                }
                              });
                            },
                          )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.assignment, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (_clients.isEmpty)
                          Text('${l10n.no} ${l10n.clients}')
                        else
                          InkWell(
                            onTap: () => _showClientSearchDialog(),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.client,
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.search),
                              ),
                              child: Text(
                                _selectedClientId == null 
                                  ? l10n.unassigned 
                                  : _clients.firstWhere((c) => c['id'] == _selectedClientId)['full_name'] ?? '',
                                style: TextStyle(
                                  color: _selectedClientId == null ? Colors.grey : null,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l10n.save.toUpperCase()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _save() async {
    try {
      final service = ref.read(adminServiceProvider);
      
      if (widget.dispenserId == null) {
        await service.createDispenser(
          _serialController.text,
          _selectedTypeId,
          _selectedFeatures,
          _selectedStatus,
          _selectedClientId,
        );
      } else {
        await service.updateDispenser(
          widget.dispenserId!,
          _serialController.text,
          _selectedTypeId,
          _selectedFeatures,
          _selectedStatus,
          _selectedClientId,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispenser saved successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showClientSearchDialog() {
    final l10n = AppLocalizations.of(context)!;
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = _clients.where((c) {
            final query = searchController.text.toLowerCase();
            final name = (c['full_name'] ?? '').toLowerCase();
            final phone = (c['phone_number'] ?? '').toLowerCase();
            return name.contains(query) || phone.contains(query);
          }).toList();

          return AlertDialog(
            title: Text(l10n.client),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: '${l10n.search}...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          title: Text(l10n.unassigned),
                          onTap: () {
                            setState(() => _selectedClientId = null);
                            Navigator.pop(context);
                          },
                        ),
                        ...filtered.map((c) => ListTile(
                          title: Text(c['full_name'] ?? ''),
                          subtitle: Text(c['phone_number'] ?? ''),
                          onTap: () {
                            setState(() => _selectedClientId = c['id'] as int);
                            Navigator.pop(context);
                          },
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );
      
      if (result != null && result is String) {
        setState(() {
          _serialController.text = result;
        });
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
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }
}
