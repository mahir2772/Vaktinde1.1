// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// --- DİL VE TEMA İMPORTLARI ---
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../common/theme_provider.dart';
// --- REKLAM HELPER İMPORTU EKLENDİ ---
import '../../common/ad_helper.dart';
// ------------------------------
import '../../esmaul_husna/view/esmaul_husna_view.dart';
import '../../religious_days/view/religious_days_view.dart';
import '../../friday_messages/view/friday_messages_view.dart';
import '../../zakat/view/zakat_view.dart';
import '../../settings/view/settings_view.dart';
import '../../missed_prayers/view/missed_prayers_view.dart';
import '../../imsakiye/view/imsakiye_view.dart';

class ToolsView extends StatelessWidget {
  const ToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final bool hasImage = themeProvider.backgroundImage != null;

    const Color primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: hasImage ? Colors.transparent : const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text(
          loc.navMenu,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: hasImage ? Colors.transparent : Colors.white,
        foregroundColor: hasImage ? Colors.white : primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            // --- 1. KISIM: ARAÇLAR BÖLÜMÜ (MODERN GRID) ---
            Expanded(
              child: GridView.count(
                physics: const BouncingScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio:
                    1.1, // Kartları biraz daha yatay/kare arası modern formata çektik
                children: [
                  _buildToolCard(
                    context,
                    hasImage: hasImage,
                    title: loc.imsakiyeTitle,
                    icon: Icons.calendar_month,
                    primaryColor: primaryColor,
                    page: const ImsakiyeView(),
                  ),
                  _buildToolCard(
                    context,
                    hasImage: hasImage,
                    title: loc.missedPrayersTitle,
                    icon: Icons.history_edu,
                    primaryColor: primaryColor,
                    page: const MissedPrayersView(),
                  ),
                  _buildToolCard(
                    context,
                    hasImage: hasImage,
                    title: loc.esmaulHusnaTitle,
                    icon: Icons.menu_book,
                    primaryColor: primaryColor,
                    page: const EsmaulHusnaView(),
                  ),
                  _buildToolCard(
                    context,
                    hasImage: hasImage,
                    title: loc.religiousDaysTitle,
                    icon: Icons.event_note,
                    primaryColor: primaryColor,
                    page: const ReligiousDaysView(),
                  ),
                  _buildToolCard(
                    context,
                    hasImage: hasImage,
                    title: loc.fridayMessagesTitle,
                    icon: Icons.share,
                    primaryColor: primaryColor,
                    page: const FridayMessagesView(),
                  ),
                  _buildToolCard(
                    context,
                    hasImage: hasImage,
                    title: loc.zakatTitle,
                    icon: Icons.calculate,
                    primaryColor: primaryColor,
                    page: const ZakatView(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --- 2. KISIM: SİSTEM/AYARLAR BÖLÜMÜ (GENİŞ KART) ---
            _buildSettingsCard(
              context,
              hasImage: hasImage,
              title: loc.menuTitle,
              icon: Icons.settings_rounded,
              primaryColor: Colors
                  .blueGrey, // Ayarların sistem rengi olduğu hissini verir
              page: const SettingsView(),
            ),
            const SizedBox(
              height: 10,
            ), // Cihazın altına çok yapışmaması için güvenli alan
          ],
        ),
      ),
    );
  }

  // --- KARE ARAÇ KARTLARI İÇİN TASARIM ---
  Widget _buildToolCard(
    BuildContext context, {
    required bool hasImage,
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Widget page,
  }) {
    Color cardColor = hasImage
        ? Theme.of(context).cardTheme.color!.withOpacity(0.85)
        : Colors.white;

    Color textColor = hasImage
        ? Theme.of(context).textTheme.bodyLarge?.color ??
              Colors.blueGrey.shade800
        : Colors.blueGrey.shade800;

    return GestureDetector(
      onTap: () {
        AdHelper.instance.showInterstitialAd();
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20), // Daha modern yuvarlama
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.06), // Gölgeler yumuşatıldı
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  16,
                ), // İkon arka planı kare-oval arası yapıldı
              ),
              child: Icon(icon, size: 30, color: primaryColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GENİŞ AYARLAR KARTI İÇİN TASARIM ---
  Widget _buildSettingsCard(
    BuildContext context, {
    required bool hasImage,
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Widget page,
  }) {
    Color cardColor = hasImage
        ? Theme.of(context).cardTheme.color!.withOpacity(0.85)
        : Colors.white;

    Color textColor = hasImage
        ? Theme.of(context).textTheme.bodyLarge?.color ??
              Colors.blueGrey.shade800
        : Colors.blueGrey.shade800;

    return GestureDetector(
      onTap: () {
        AdHelper.instance.showInterstitialAd();
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
