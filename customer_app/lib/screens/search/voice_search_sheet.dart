import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../services/voice_search_controller.dart';

/// Bottom sheet: tap mic -> speak -> see recognized text -> retry / edit /
/// search. Returns the confirmed query string, or null if the user backed
/// out — the caller (HomeScreen) is responsible for actually running the
/// search once it gets a non-null result, so voice never auto-searches.
Future<String?> showVoiceSearchSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => const _VoiceSearchSheet(),
  );
}

class _VoiceSearchSheet extends StatefulWidget {
  const _VoiceSearchSheet();
  @override
  State<_VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

class _VoiceSearchSheetState extends State<_VoiceSearchSheet> {
  final _controller = VoiceSearchController();
  final _editCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _controller.startListening();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.recognizedText;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            if (!_controller.available && _controller.error != null)
              Text(
                AppStrings.lang == 'hi'
                    ? 'आवाज़ पहचान उपलब्ध नहीं है इस डिवाइस पर'
                    : 'Voice recognition is not available on this device',
                textAlign: TextAlign.center,
              )
            else ...[
              GestureDetector(
                onTap: () {
                  if (_controller.listening) {
                    _controller.stopListening();
                  } else {
                    _editing = false;
                    _controller.startListening();
                  }
                },
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: _controller.listening ? AppTheme.accent : AppTheme.primary,
                  child: Icon(_controller.listening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _controller.listening ? AppStrings.t('listening') : AppStrings.t('tap_mic_to_speak'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (text.isNotEmpty && !_editing) ...[
                Text(AppStrings.t('you_said'), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _controller.startListening(),
                        child: Text(AppStrings.t('retry')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _editCtrl.text = text;
                          setState(() => _editing = true);
                        },
                        child: Text(AppStrings.t('edit')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(text),
                  child: Text(AppStrings.t('search')),
                ),
              ] else if (_editing) ...[
                TextField(
                  controller: _editCtrl,
                  autofocus: true,
                  decoration: InputDecoration(hintText: AppStrings.t('search_hint')),
                  onSubmitted: (v) => Navigator.of(context).pop(v),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_editCtrl.text),
                  child: Text(AppStrings.t('search')),
                ),
              ],
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
