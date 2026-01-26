// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// --- DİL VE TEMA İMPORTLARI ---
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../common/theme_provider.dart'; // <--- TEMA İÇİN EKLENDİ
// ------------------------------
import '../../esmaul_husna/view/esmaul_husna_view.dart';
import '../../religious_days/view/religious_days_view.dart';
import '../../friday_messages/view/friday_messages_view.dart';
import '../../zakat/view/zakat_view.dart';
import '../../settings/view/settings_view.dart';
import '../../missed_prayers/view/missed_prayers_view.dart';

class ToolsView extends StatelessWidget {
  const ToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Çeviri nesnesi
    final loc = AppLocalizations.of(context)!;
    // Tema sağlayıcısını dinliyoruz
    final themeProvider = context.watch<ThemeProvider>();
    final bool hasImage = themeProvider.backgroundImage != null;

    const Color primaryColor = Colors.teal;

    return Scaffold(
      // Arka plan rengi tema ile uyumlu olsun (Resim varsa şeffaf)
      backgroundColor: hasImage ? Colors.transparent : const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text(
          loc.navMenu, // "Menü"
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // AppBar rengi: Resim varsa şeffaf, yoksa beyaz
        backgroundColor: hasImage ? Colors.transparent : Colors.white,
        foregroundColor: hasImage ? Colors.white : primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
                children: [
                  // 1. KAZA TAKİBİ
                  _buildSoftCard(
                    context,
                    hasImage: hasImage,
                    title: loc.missedPrayersTitle,
                    icon: Icons.history_edu,
                    primaryColor: primaryColor,
                    page: const MissedPrayersView(),
                  ),

                  // 2. ESMAÜL HÜSNA
                  _buildSoftCard(
                    context,
                    hasImage: hasImage,
                    title: loc.esmaulHusnaTitle,
                    icon: Icons.menu_book,
                    primaryColor: primaryColor,
                    page: const EsmaulHusnaView(),
                  ),

                  // 3. DİNİ GÜNLER
                  _buildSoftCard(
                    context,
                    hasImage: hasImage,
                    title: loc.religiousDaysTitle,
                    icon: Icons.event_note,
                    primaryColor: primaryColor,
                    page: const ReligiousDaysView(),
                  ),

                  // 4. CUMA MESAJLARI
                  _buildSoftCard(
                    context,
                    hasImage: hasImage,
                    title: loc.fridayMessagesTitle,
                    icon: Icons.share,
                    primaryColor: primaryColor,
                    page: const FridayMessagesView(),
                  ),

                  // 5. ZEKAT HESAPLA
                  _buildSoftCard(
                    context,
                    hasImage: hasImage,
                    title: loc.zakatTitle,
                    icon: Icons.calculate,
                    primaryColor: primaryColor,
                    page: const ZakatView(),
                  ),

                  // 6. AYARLAR
                  _buildSoftCard(
                    context,
                    hasImage: hasImage,
                    title: loc.menuTitle,
                    icon: Icons.settings,
                    primaryColor: primaryColor,
                    page: const SettingsView(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoftCard(
    BuildContext context, {
    required bool hasImage, // Resim var mı bilgisi
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Widget page,
  }) {
    // Kart rengi: Resim varsa %85 şeffaf beyaz/siyah, yoksa tam beyaz
    Color cardColor = hasImage
        ? Theme.of(context).cardTheme.color!.withOpacity(0.85)
        : Colors.white;

    // Yazı rengi: Resim varsa ve tema koyuysa açık renk, yoksa koyu
    Color textColor = hasImage
        ? Theme.of(context).textTheme.bodyLarge?.color ??
              Colors.blueGrey.shade800
        : Colors.blueGrey.shade800;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(
                0.08,
              ), // withValues yerine withOpacity
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // İkon arka planı
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
