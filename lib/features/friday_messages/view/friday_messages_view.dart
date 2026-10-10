import 'package:flutter/material.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/json_service.dart';
import '../../common/share_card.dart';

/// Cuma mesajları: kart listesi; her mesaj kopyalanır, metin ya da resim
/// (Play bağlantılı) olarak paylaşılır
class FridayMessagesView extends StatefulWidget {
  const FridayMessagesView({super.key});

  @override
  State<FridayMessagesView> createState() => _FridayMessagesViewState();
}

class _FridayMessagesViewState extends State<FridayMessagesView> {
  final JsonService _jsonService = JsonService();
  List<String>? _messages;
  bool _isLoading = true;
  bool _failed = false;
  String? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language != _language) {
      _language = language;
      _loadMessages();
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _failed = false;
    });
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final language = _language ?? 'tr';
    try {
      final list = await _jsonService.getFridayMessages(language);
      if (!mounted || language != _language) return;
      setState(() {
        _messages = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _isLoading = false;
      });
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }

  void _shuffleMessages(AppLocalizations loc) {
    final messages = _messages;
    if (messages == null || messages.isEmpty) return;
    setState(() => messages.shuffle());
    _snack(loc.messagesShuffled);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final messages = _messages;

    Widget body;
    if (_isLoading) {
      body = const LoadingState();
    } else if (_failed || messages == null) {
      body = ErrorState(message: loc.noDataFound, onRetry: _retry);
    } else if (messages.isEmpty) {
      body = EmptyState(icon: Icons.forum_outlined, title: loc.noDataFound);
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: messages.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => MessageCard(
          message: messages[index],
          position: '${index + 1} / ${messages.length}',
          title: loc.fridayGreeting,
          campaign: 'friday',
        ),
      );
    }

    return AppScaffold(
      title: loc.fridayMessagesTitle,
      actions: [
        IconButton(
          onPressed: (messages == null || messages.isEmpty)
              ? null
              : () => _shuffleMessages(loc),
          icon: const Icon(Icons.shuffle),
          tooltip: loc.shuffle,
        ),
      ],
      body: body,
    );
  }
}
