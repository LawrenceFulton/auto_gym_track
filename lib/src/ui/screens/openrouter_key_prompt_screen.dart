import 'package:flutter/material.dart';

class OpenRouterKeyPromptScreen extends StatefulWidget {
  const OpenRouterKeyPromptScreen({super.key, required this.onSave, this.error, this.isSaving = false});

  final Future<void> Function(String key) onSave;
  final String? error;
  final bool isSaving;

  @override
  State<OpenRouterKeyPromptScreen> createState() => _OpenRouterKeyPromptScreenState();
}

class _OpenRouterKeyPromptScreenState extends State<OpenRouterKeyPromptScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your OpenRouter API key.')));
      return;
    }

    await widget.onSave(key);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.key_rounded),
                      ),
                      const SizedBox(height: 10),
                      Text('Connect OpenRouter', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Enter your OpenRouter API key to enable workout extraction.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'OpenRouter API Key', hintText: 'sk-or-v1-...'),
                  ),
                  if (widget.error != null) ...[
                    const SizedBox(height: 10),
                    Text(widget.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.isSaving ? null : _submit,
                      child: widget.isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Key'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Your key is saved on this device and used for OpenRouter calls.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
