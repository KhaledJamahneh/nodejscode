import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';
import '../providers/admin_provider.dart';

final _typesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(adminServiceProvider).getDispenserTypes();
});

final _featuresProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(adminServiceProvider).getDispenserFeatures();
});

class DispenserSettingsScreen extends ConsumerWidget {
  const DispenserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.dispenserSettings),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.types),
              Tab(text: l10n.features),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TypesTab(),
            _FeaturesTab(),
          ],
        ),
      ),
    );
  }
}

class _TypesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(_typesProvider);
    final l10n = AppLocalizations.of(context)!;

    return typesAsync.when(
      data: (types) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: types.length + 1,
        itemBuilder: (context, index) {
          if (index == types.length) {
            return ElevatedButton.icon(
              onPressed: () => _showTypeDialog(context, ref, null),
              icon: const Icon(Icons.add),
              label: Text(l10n.addType),
            );
          }
          final type = types[index];
          return ModernCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(type['name']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showTypeDialog(context, ref, type),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deleteType(context, ref, type['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, __) => Center(child: Text('${l10n.error}: ${l10n.types}')),
    );
  }

  void _showTypeDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? type) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: type?['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == null ? l10n.addType : l10n.editType),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.typeName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (type == null) {
                await ref.read(adminServiceProvider).createDispenserType(controller.text);
              } else {
                await ref.read(adminServiceProvider).updateDispenserType(type['id'], controller.text);
              }
              Navigator.pop(context);
              ref.invalidate(_typesProvider);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteType(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.delete} ${l10n.types}'),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminServiceProvider).deleteDispenserType(id);
      ref.invalidate(_typesProvider);
    }
  }
}

class _FeaturesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresAsync = ref.watch(_featuresProvider);
    final l10n = AppLocalizations.of(context)!;

    return featuresAsync.when(
      data: (features) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: features.length + 1,
        itemBuilder: (context, index) {
          if (index == features.length) {
            return ElevatedButton.icon(
              onPressed: () => _showFeatureDialog(context, ref, null),
              icon: const Icon(Icons.add),
              label: Text(l10n.addFeature),
            );
          }
          final feature = features[index];
          return ModernCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(feature['name']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showFeatureDialog(context, ref, feature),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deleteFeature(context, ref, feature['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (_, __) => Center(child: Text('${l10n.error}: ${l10n.features}')),
    );
  }

  void _showFeatureDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? feature) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: feature?['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature == null ? l10n.addFeature : l10n.editFeature),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.featureName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (feature == null) {
                await ref.read(adminServiceProvider).createDispenserFeature(controller.text);
              } else {
                await ref.read(adminServiceProvider).updateDispenserFeature(feature['id'], controller.text);
              }
              Navigator.pop(context);
              ref.invalidate(_featuresProvider);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFeature(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.delete} ${l10n.features}'),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminServiceProvider).deleteDispenserFeature(id);
      ref.invalidate(_featuresProvider);
    }
  }
}
