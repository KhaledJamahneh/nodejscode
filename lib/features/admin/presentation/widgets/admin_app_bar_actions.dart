import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';

class AdminAppBarActions extends ConsumerWidget {
  const AdminAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      ],
    );
  }
}
