import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/state/api_key_controller.dart';
import '../../application/state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer2<ApiKeyController, SettingsController>(
        builder: (context, apiController, settingsController, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                context,
                title: 'Account',
                icon: Icons.vpn_key_rounded,
                children: [
                  ListTile(
                    title: const Text('Change API Key'),
                    subtitle: const Text('Update your OpenRouter API key.'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showChangeKeyDialog(context, apiController),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: 'Workout Preferences',
                icon: Icons.settings_rounded,
                children: [
                  ListTile(
                    title: const Text('Default Units'),
                    subtitle: Text('Current unit: ${settingsController.unit}'),
                    trailing: DropdownButton<String>(
                      value: settingsController.unit,
                      onChanged: (val) {
                        if (val != null) settingsController.setUnit(val);
                      },
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'lb', child: Text('lb')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: 'About',
                icon: Icons.info_outline_rounded,
                children: [
                  const ListTile(
                    title: Text('Auto Gym Track'),
                    subtitle: Text('Version 1.0.0'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showChangeKeyDialog(BuildContext context, ApiKeyController controller) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your new OpenRouter API key. This will replace the current one.'),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'New API Key', border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final key = textController.text.trim();
              if (key.isNotEmpty) {
                controller.saveKey(key);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key updated successfully.')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
