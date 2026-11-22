import 'package:flutter/material.dart';

import 'app_card.dart';
import 'app_tokens.dart';
import 'section_header.dart';

/// Ayar/menü satırı: marka renkli 40dp ikon kutusu, başlık, alt yazı, sağda
/// [trailing] ve (dokunulabiliyorsa) RTL'de dönen ok. En az 56dp yükseklik;
/// büyük yazıda satır uzar, taşmaz.
class AppListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.listTileMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                width: AppSizes.iconBox,
                height: AppSizes.iconBox,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  leadingIcon,
                  size: 22,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
            if (onTap != null && showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurfaceVariant,
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: onTap == null ? row : InkWell(onTap: onTap, child: row),
      ),
    );
  }
}

/// Başlıklı kart içinde satır grubu; satırlar arasında ince ayraç
class AppListSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const AppListSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(
          const Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),
        );
      }
      items.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) SectionHeader(title!),
        AppCard(
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: items),
        ),
      ],
    );
  }
}
