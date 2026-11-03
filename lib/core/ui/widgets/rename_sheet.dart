import 'package:flutter/material.dart';

import '../../i18n/message_key.dart';
import 'app_sheet.dart';
import 'name_field.dart';

/// The Rename sheet (FR-3, FR-5): "שינוי שם" with a name field pre-filled
/// with [current], limited to [maxLength] grapheme clusters.
///
/// The sheet owns the save so errors stay inside it: "שמירה" (or the keyboard
/// action) calls [onSave], which returns the error to show, or `null` on
/// success. On success the sheet closes with `true`; on an error it stays
/// open with the message under the field. "ביטול", the scrim or system back
/// close it with `null` and write nothing.
Future<bool?> showRenameSheet(
  BuildContext context, {
  required String current,
  required int maxLength,
  required Future<MessageKey?> Function(String name) onSave,
}) => showAppSheet<bool>(
  context,
  builder: (_) =>
      _RenameSheet(current: current, maxLength: maxLength, onSave: onSave),
);

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({
    required this.current,
    required this.maxLength,
    required this.onSave,
  });

  final String current;
  final int maxLength;
  final Future<MessageKey?> Function(String name) onSave;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _controller = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.current,
      selection: TextSelection.collapsed(offset: widget.current.length),
    ),
  );
  MessageKey? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final error = await widget.onSave(_controller.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = error;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetLayout(
      title: MessageKey.renameTitle.text,
      body: NameField(
        controller: _controller,
        maxLength: widget.maxLength,
        autofocus: true,
        error: _error,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmit: _save,
      ),
      primary: FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(MessageKey.save.text),
      ),
      secondary: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(MessageKey.cancel.text),
      ),
    );
  }
}
