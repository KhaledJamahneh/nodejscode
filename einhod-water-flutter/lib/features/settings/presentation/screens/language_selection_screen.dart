import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  Future<void> _updateLanguage(BuildContext context, WidgetRef ref, String languageCode) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.put('/users/language', {'language': languageCode});
      
      ref.read(localeProvider.notifier).setLocale(Locale(languageCode));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.languageUpdated)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update language: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
      ),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: const Text('English'),
            subtitle: const Text('English'),
            value: 'en',
            groupValue: currentLocale.languageCode,
            onChanged: (value) => _updateLanguage(context, ref, value!),
          ),
          RadioListTile<String>(
            title: const Text('العربية'),
            subtitle: const Text('Arabic'),
            value: 'ar',
            groupValue: currentLocale.languageCode,
            onChanged: (value) => _updateLanguage(context, ref, value!),
          ),
        ],
      ),
    );
  }
}
