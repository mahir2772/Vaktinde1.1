import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../view_model/zikir_view_model.dart';
import '../../common/widgets/ad_banner_widget.dart';

class DhikrListView extends StatelessWidget {
  const DhikrListView({super.key});

  // Hazır zikirlerin çevirilerini eşleştirmek için yardımcı fonksiyon
  String _getTranslatedName(String id, AppLocalizations loc) {
    switch (id) {
      case "Sübhanallah":
        return loc.dhikrSubhanallah;
      case "Elhamdülillah":
        return loc.dhikrElhamdulillah;
      case "Allahu Ekber":
        return loc.dhikrAllahuEkber;
      case "Kelime-i Tevhid":
        return loc.dhikrKalima;
      case "Salavat":
        return loc.dhikrSalavat;
      case "Estağfirullah":
        return loc.dhikrEstagfirullah;
      case "La Havle":
        return loc.dhikrLaHavle;
      case "Hasbünallah":
        return loc.dhikrHasbunallah;
      case "Subhanallahi":
        return loc.dhikrSubhanallahi;
      case "Hz. Yunus":
        return loc.dhikrYunus;
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    const primaryColor = Colors.teal;

    // DefaultTabController ile listeyi 2 sekmeye (Tab) ayırıyoruz
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(loc.dhikrListTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: textColor,
          bottom: TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: textColor.withOpacity(0.5),
            indicatorColor: primaryColor,
            tabs: [
              Tab(text: loc.mainDhikrs),
              Tab(text: loc.esmaulHusnaTab),
            ],
          ),
        ),
        body: Consumer<ZikirViewModel>(
          builder: (context, viewModel, child) {
            return TabBarView(
              children: [
                // --- 1. SEKME: TEMEL ZİKİRLER VE ÖZEL ZİKİRLER ---
                ListView(
                  padding: const EdgeInsets.all(15),
                  children: [
                    ...viewModel.predefinedDhikrsList.map((dhikrMap) {
                      String id = dhikrMap["id"]!;
                      String ar = dhikrMap["ar"]!;
                      String displayName = _getTranslatedName(id, loc);
                      bool isSelected = viewModel.selectedDhikr == id;

                      return _buildDhikrCard(
                        context: context,
                        title: displayName,
                        arabic: ar,
                        subtitle: "",
                        isSelected: isSelected,
                        primaryColor: primaryColor,
                        textColor: textColor,
                        onTap: () {
                          viewModel.changeDhikr(id);
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.dhikrOther.toUpperCase(),
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          "${viewModel.customDhikrs.length}/20",
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (viewModel.customDhikrs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            loc.statsEmpty,
                            style: TextStyle(color: textColor.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    ...viewModel.customDhikrs.map((customName) {
                      bool isSelected = viewModel.selectedDhikr == customName;
                      return _buildDhikrCard(
                        context: context,
                        title: customName,
                        arabic: "",
                        subtitle: "",
                        isSelected: isSelected,
                        primaryColor: primaryColor,
                        textColor: textColor,
                        onDelete: () => viewModel.removeCustomDhikr(customName),
                        onTap: () {
                          viewModel.changeDhikr(customName);
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const SizedBox(
                      height: 80,
                    ), // Fab butonu üstüne binmesin diye boşluk
                  ],
                ),

                // --- 2. SEKME: ESMAÜL HÜSNA (99 İSİM) ---
                ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: viewModel.esmaulHusnaList.length,
                  itemBuilder: (context, index) {
                    final dhikrMap = viewModel.esmaulHusnaList[index];
                    String id = dhikrMap["id"]!;
                    String ar = dhikrMap["ar"]!;

                    // DİNAMİK DİL SEÇİCİ (Cihazın dil kodunu alır: tr, en, fr, de, ar)
                    String langCode = Localizations.localeOf(
                      context,
                    ).languageCode;

                    // Varsa o dili al, yoksa İngilizceyi al, o da yoksa Türkçeyi ver
                    String meaning =
                        dhikrMap[langCode] ??
                        dhikrMap["en"] ??
                        dhikrMap["tr"] ??
                        "";

                    bool isSelected = viewModel.selectedDhikr == id;

                    return _buildDhikrCard(
                      context: context,
                      title: id,
                      arabic: ar,
                      subtitle: meaning, // Çevrilmiş dinamik anlam
                      isSelected: isSelected,
                      primaryColor: primaryColor,
                      textColor: textColor,
                      onTap: () {
                        viewModel.changeDhikr(id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),

        // YENİ EKLE BUTONU (FAB)
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context),
          backgroundColor: primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            loc.addCustomDhikr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
      ),
    );
  }

  // Zikir Kartı Tasarımı (Anlam kısmı eklendi)
  Widget _buildDhikrCard({
    required BuildContext context,
    required String title,
    required String arabic,
    required String subtitle,
    required bool isSelected,
    required Color primaryColor,
    required Color textColor,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 10),
      color: isSelected
          ? primaryColor.withOpacity(0.1)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (arabic.isNotEmpty)
              Text(
                arabic,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 20,
                  fontFamily: 'Amiri',
                ),
              ),
            if (arabic.isNotEmpty && isSelected) const SizedBox(width: 10),
            if (isSelected) Icon(Icons.check_circle, color: primaryColor),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  // Özel Zikir Ekleme Penceresi
  void _showAddDialog(BuildContext context) {
    final viewModel = context.read<ZikirViewModel>();
    final loc = AppLocalizations.of(context)!;
    TextEditingController controller = TextEditingController();

    if (viewModel.customDhikrs.length >= 20) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.customDhikrLimit)));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          loc.addCustomDhikr,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: loc.customDhikrHint,
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.teal),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                bool added = await viewModel.addCustomDhikr(
                  controller.text.trim(),
                );
                if (added && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(loc.customDhikrAdded)));
                }
              }
            },
            child: Text(
              loc.save,
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
