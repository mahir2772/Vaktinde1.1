import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../common/ad_consent.dart';
import '../../common/ad_helper.dart';

/// Gizlilik ve Reklamlar (Ayarlar > Destek): gizlilik politikası, reklamlar
/// hakkında açıklama ve AB/EEA'da reklam gizlilik ayarları
class PrivacyAdsView extends StatelessWidget {
  /// Gizlilik politikası adresi; boşken satır gizli
  final String privacyPolicyUrl;

  const PrivacyAdsView({
    super.key,
    this.privacyPolicyUrl = AppLinks.privacyPolicy,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppScaffold(
      title: loc.privacyAdsTitle,
      showBanner: false,
      body: ListView(
        // Banner yok: son satır gezinme çubuğunun üstünde kalsın (uçtan uca)
        padding: EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // AB/EEA'da reklam rızası buradan sonradan değiştirilebilir (UMP zorunlu kılarsa)
          ValueListenableBuilder<bool>(
            valueListenable: AdConsent.privacyOptionsRequired,
            builder: (context, privacyRequired, _) => AppListSection(
              children: [
                if (privacyPolicyUrl.isNotEmpty)
                  AppListTile(
                    leadingIcon: Icons.policy_outlined,
                    title: loc.privacyPolicy,
                    onTap: _openPrivacyPolicy,
                  ),
                AppListTile(
                  leadingIcon: Icons.campaign_outlined,
                  title: loc.aboutAds,
                  onTap: () => AdHelper.instance.showAdInfo(context),
                ),
                if (privacyRequired)
                  AppListTile(
                    leadingIcon: Icons.privacy_tip_outlined,
                    title: loc.adPrivacySettings,
                    subtitle: loc.adPrivacySettingsSub,
                    onTap: AdConsent.showPrivacyOptions,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tarayıcıda (uygulama içi görünüm değil)
  Future<void> _openPrivacyPolicy() async {
    try {
      if (!await launchUrl(
        Uri.parse(privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      )) {
        debugPrint("Gizlilik politikası açılamadı");
      }
    } catch (e) {
      debugPrint("Gizlilik politikası açılamadı: $e");
    }
  }
}
