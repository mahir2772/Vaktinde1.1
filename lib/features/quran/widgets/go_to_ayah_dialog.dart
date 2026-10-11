import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/quran_service.dart';

/// "Ayete git": ayet numarası (1–[ayahCount]; Arapça-Hint rakamlar da olur).
/// Geçerli numara girilince "Git" açılır; seçilen numarayı döner.
Future<int?> showGoToAyahDialog(
  BuildContext context, {
  required int ayahCount,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => GoToAyahDialog(ayahCount: ayahCount),
  );
}

class GoToAyahDialog extends StatefulWidget {
  final int ayahCount;

  const GoToAyahDialog({super.key, required this.ayahCount});

  @override
  State<GoToAyahDialog> createState() => _GoToAyahDialogState();
}

class _GoToAyahDialogState extends State<GoToAyahDialog> {
  final TextEditingController _controller = TextEditingController();

  int? get _value {
    final number = int.tryParse(QuranService.searchKey(_controller.text));
    return number != null && number >= 1 && number <= widget.ayahCount
        ? number
        : null;
  }

  void _submit() {
    final value = _value;
    if (value != null) Navigator.pop(context, value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.quranGoToAyah),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9\u0660-\u0669]')),
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(
          labelText: loc.quranAyahNumberLabel(widget.ayahCount),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: _value == null ? null : _submit,
          child: Text(loc.quranGo),
        ),
      ],
    );
  }
}
