import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../view_model/zikir_view_model.dart';
import 'dhikr_names.dart';

/// Zikir seçimi: temel + özel zikirler ve Esmâ-ül Hüsnâ (iki sekme)
class DhikrListView extends StatelessWidget {
  const DhikrListView({super.key});

  static const int _customLimit = 20;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: loc.dhikrListTitle,
        bottom: TabBar(
          tabs: [
            Tab(text: loc.mainDhikrs),
            Tab(text: loc.esmaulHusnaTab),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: Text(loc.addCustomDhikr),
        ),
        body: Consumer<ZikirViewModel>(
          builder: (context, viewModel, child) {
            void select(String id) {
              viewModel.changeDhikr(id);
              Navigator.pop(context);
            }

            final langCode = Localizations.localeOf(context).languageCode;
            return TabBarView(
              children: [
                // 1. sekme: temel ve özel zikirler
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    96, // FAB üstüne binmesin
                  ),
                  children: [
                    for (final dhikr in viewModel.predefinedDhikrsList)
                      _DhikrTile(
                        title: dhikrDisplayName(dhikr["id"]!, loc),
                        arabic: dhikr["ar"] ?? "",
                        isSelected: viewModel.selectedDhikr == dhikr["id"],
                        onTap: () => select(dhikr["id"]!),
                      ),
                    SectionHeader(
                      loc.dhikrOther,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.xs,
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.sm,
                      ),
                      trailing: Text(
                        '${viewModel.customDhikrs.length}/$_customLimit',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (viewModel.customDhikrs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          loc.noCustomDhikr,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    for (final custom in viewModel.customDhikrs)
                      _DhikrTile(
                        title: custom,
                        isSelected: viewModel.selectedDhikr == custom,
                        onTap: () => select(custom),
                        onDelete: () =>
                            _confirmDelete(context, viewModel, custom),
                      ),
                  ],
                ),

                // 2. sekme: Esmâ-ül Hüsnâ
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    96,
                  ),
                  itemCount: viewModel.esmaulHusnaList.length,
                  itemBuilder: (context, index) {
                    final dhikr = viewModel.esmaulHusnaList[index];
                    final id = dhikr["id"]!;
                    // Seçili dilde anlam yoksa İngilizce, o da yoksa Türkçe
                    final meaning =
                        dhikr[langCode] ?? dhikr["en"] ?? dhikr["tr"] ?? "";
                    return _DhikrTile(
                      title: id,
                      arabic: dhikr["ar"] ?? "",
                      subtitle: meaning,
                      isSelected: viewModel.selectedDhikr == id,
                      onTap: () => select(id),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ZikirViewModel viewModel,
    String name,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: loc.deleteDhikr,
      message: name,
      confirmLabel: loc.deleteDhikr,
      destructive: true,
    );
    if (confirmed) await viewModel.removeCustomDhikr(name);
  }

  void _showAddDialog(BuildContext context) {
    final viewModel = context.read<ZikirViewModel>();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    if (viewModel.customDhikrs.length >= _customLimit) {
      messenger.showSnackBar(SnackBar(content: Text(loc.customDhikrLimit)));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _AddDhikrDialog(
        onSave: (name) async {
          final added = await viewModel.addCustomDhikr(name);
          if (added) {
            messenger.showSnackBar(
              SnackBar(content: Text(loc.customDhikrAdded)),
            );
          }
          return added;
        },
      ),
    );
  }
}

/// Zikir kartı: ad, altında (tam genişlikte, satır kırarak) Arapça metin ve
/// anlam. Arapça artık sağ köşeye sıkıştırılmaz (uzun dualarda düzen bozuluyordu).
class _DhikrTile extends StatelessWidget {
  final String title;
  final String arabic;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _DhikrTile({
    required this.title,
    this.arabic = "",
    this.subtitle = "",
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        selected: isSelected,
        child: AppCard(
          onTap: onTap,
          color: isSelected ? scheme.primaryContainer : null,
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.md,
            onDelete == null ? AppSpacing.lg : AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: isSelected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    if (arabic.isNotEmpty)
                      Text(
                        arabic,
                        textDirection: TextDirection.rtl,
                        style: arabicDhikrStyle(context).copyWith(
                          color: isSelected
                              ? scheme.onPrimaryContainer
                              : scheme.primary,
                        ),
                      ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: isSelected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.check_circle, color: scheme.primary),
              ],
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  tooltip: loc.deleteDhikr,
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDhikrDialog extends StatefulWidget {
  /// true dönerse pencere kapanır (eklenemezse açık kalır)
  final Future<bool> Function(String name) onSave;

  const _AddDhikrDialog({required this.onSave});

  @override
  State<_AddDhikrDialog> createState() => _AddDhikrDialogState();
}

class _AddDhikrDialogState extends State<_AddDhikrDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final added = await widget.onSave(name);
    if (!mounted) return;
    if (added) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.addCustomDhikr),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: loc.customDhikrHint),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(onPressed: _saving ? null : _save, child: Text(loc.save)),
      ],
    );
  }
}
