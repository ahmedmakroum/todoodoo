import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/focus_mode_provider.dart';
import '../screens/monthly_vision.dart';
import '../screens/yearly_vision.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final isFocusModeEnabled = ref.watch(focusModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Switcher
            ListTile(
              title: const Text('Theme'),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).state = value;
                },
              ),
            ),
            // Focus Mode Toggle
            ListTile(
              title: const Text('Focus Mode'),
              trailing: Switch(
                value: isFocusModeEnabled,
                onChanged: (value) {
                  ref.read(focusModeProvider.notifier).state = value;
                },
              ),
            ),
            // Monthly Vision
            ListTile(
              title: const Text('Monthly Vision'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MonthlyVisionPage()),
                );
              },
            ),
            // Yearly Vision
            ListTile(
              title: const Text('Yearly Vision'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const YearlyVisionPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}