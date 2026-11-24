import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

/// Fallback for "add from clipboard" when the system pasteboard cannot be read
/// (missing permission, empty clipboard, or an unsupported record type).
///
/// On HarmonyOS this dialog is important: Flutter's own clipboard channel
/// depends on a runtime permission that may be denied, while a text field can
/// always receive text through the system paste control / keyboard.
class PasteLinkDialog extends StatefulWidget {
  const PasteLinkDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String hint;
  final String cancelLabel;
  final String confirmLabel;

  @override
  State<PasteLinkDialog> createState() => _PasteLinkDialogState();
}

class _PasteLinkDialogState extends State<PasteLinkDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (text.trim().isNotEmpty) {
        _controller.text = text.trim();
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      }
    } catch (_) {
      // The keyboard paste gesture still works even when this channel fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title, style: theme.textTheme.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.hint, style: theme.textTheme.bodySmall),
            const Gap(12),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const Gap(8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste, size: 18),
                label: Text(MaterialLocalizations.of(context).pasteButtonLabel),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
