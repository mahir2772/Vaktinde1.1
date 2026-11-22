import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/quran_service.dart';

/// "Ayete git": ayet numarası (1–[ayahCount]). Seçilen numarayı döner.
Future<int?> showGoToAyahDialog(
  BuildContext context, {
  required int ayahCount,
}) {
  final loc = AppLocalizations.of(context)!;
  return showNumberDialog(
    context,
    title: loc.quranGoToAyah,
    label: loc.quranAyahNumberLabel(ayahCount),
    confirmLabel: loc.quranGo,
    max: ayahCount,
  );
}

/// Numara penceresi (1–[max]; Arapça-Hint rakamlar da olur): geçerli numara
/// girilince onay düğmesi açılır; seçilen numarayı döner ("Ayete git", hatimde
/// "Sayfa Gir")
Future<int?> showNumberDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  required int max,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => NumberDialog(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
      max: max,
    ),
  );
}

class NumberDialog extends StatefulWidget {
  final String title;
  final String label;
  final String confirmLabel;
  final int max;

  const NumberDialog({
    super.key,
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.max,
  });

  @override
  State<NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<NumberDialog> {
  final TextEditingController _controller = TextEditingController();

  int? get _value {
    final number = int.tryParse(QuranService.searchKey(_controller.text));
    return number != null && number >= 1 && number <= widget.max
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
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]')),
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(labelText: widget.label),
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
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
