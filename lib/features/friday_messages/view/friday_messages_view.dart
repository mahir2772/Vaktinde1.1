import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/json_service.dart';

/// Cuma mesajları: kart listesi; her mesaj kopyalanır veya paylaşılır
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

  Future<void> _copy(String message, AppLocalizations loc) async {
    try {
      await Clipboard.setData(ClipboardData(text: message));
      if (mounted) _snack(loc.messageCopied);
    } catch (_) {
      if (mounted) _snack(loc.shareFailed);
    }
  }

  Future<void> _share(String message, AppLocalizations loc) async {
    try {
      await Share.share(message);
    } catch (_) {
      if (mounted) _snack(loc.shareFailed);
    }
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
        itemBuilder: (context, index) => _MessageCard(
          message: messages[index],
          position: '${index + 1} / ${messages.length}',
          copyLabel: loc.copy,
          shareLabel: loc.share,
          onCopy: () => _copy(messages[index], loc),
          onShare: () => _share(messages[index], loc),
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

class _MessageCard extends StatelessWidget {
  final String message;
  final String position;
  final String copyLabel;
  final String shareLabel;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _MessageCard({
    required this.message,
    required this.position,
    required this.copyLabel,
    required this.shareLabel,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: scheme.primary, size: 28),
              const Spacer(),
              Text(
                position,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelMedium!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyLarge!.copyWith(
              height: 1.6,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 20),
                label: Text(copyLabel),
              ),
              FilledButton.tonalIcon(
                onPressed: onShare,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, AppSizes.minTouch),
                ),
                icon: const Icon(Icons.share, size: 20),
                label: Text(shareLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
