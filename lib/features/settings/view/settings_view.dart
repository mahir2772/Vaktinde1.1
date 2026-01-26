// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
// --- DİL VE TEMA İMPORTLARI ---
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../common/language_provider.dart';
import '../../common/theme_provider.dart';
// ------------------------------
import '../../home/view_model/home_view_model.dart';
// --- REKLAM İMPORTU ---
import '../../common/widgets/ad_banner_widget.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  final String appLink =
      "https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde";

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(loc.menuTitle), centerTitle: true),
      // --- REKLAM ALANI EKLENDİ ---
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 5.0),
          child: AdBannerWidget(),
        ),
      ),
      // ---------------------------
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Text(
              loc.sectionAppearance,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          _buildSettingsCard(context, [
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.purple),
              title: Text(loc.appearanceSettings),
              subtitle: Text(loc.appearanceSub),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showAppearanceSettings(context, loc),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.teal),
              title: Text(loc.changeLanguage),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context),
            ),
          ]),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Text(
              loc.sectionLocation,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          _buildSettingsCard(context, [
            ListTile(
              leading: const Icon(Icons.location_city, color: Colors.blue),
              title: Text(loc.changeLocation),
              subtitle: Consumer<HomeViewModel>(
                builder: (context, viewModel, child) {
                  String displayCity = viewModel.city ?? loc.citySelect;
                  if (viewModel.district != null &&
                      viewModel.district!.isNotEmpty) {
                    return Text("${viewModel.district}, $displayCity");
                  }
                  return Text(displayCity);
                },
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCityDistrictDialog(context, loc),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.notifications_active,
                color: Colors.orange,
              ),
              title: Text(loc.menuNotifications),
              subtitle: Text(loc.menuNotificationsSub),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Geolocator.openAppSettings(),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.battery_alert, color: Colors.redAccent),
              title: Text(loc.menuTroubleshoot),
              subtitle: Text(loc.menuTroubleshootSub),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showBatteryOptimizationDialog(context, loc),
            ),
          ]),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Text(
              loc.sectionSupport,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          _buildSettingsCard(context, [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: Text(loc.shareApp),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Share.share(loc.shareText(appLink));
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text(loc.rateApp),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final InAppReview inAppReview = InAppReview.instance;
                try {
                  await inAppReview.openStoreListing(
                    appStoreId: 'com.mmdigital.vaktinde',
                  );
                } catch (e) {
                  final Uri url = Uri.parse(appLink);
                  if (!await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  )) {
                    debugPrint("Link açılamadı");
                  }
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.mail, color: Colors.red),
              title: Text(loc.contactUs),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'mmdigitall.dev@gmail.com',
                  query: 'subject=${loc.appTitle} - Destek',
                );
                if (!await launchUrl(emailLaunchUri)) {
                  debugPrint("Mail açılamadı");
                }
              },
            ),
          ]),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                const Icon(Icons.mosque, color: Colors.teal, size: 40),
                const SizedBox(height: 10),
                Text(
                  loc.appTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  "Versiyon 1.0.0",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Made with ❤️ by mmdigital",
                  style: TextStyle(color: Colors.teal, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  void _showAppearanceSettings(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.appearanceSettings,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.themeMode,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildThemeOption(
                    context,
                    Icons.brightness_auto,
                    loc.themeSystem,
                    ThemeMode.system,
                  ),
                  _buildThemeOption(
                    context,
                    Icons.wb_sunny,
                    loc.themeLight,
                    ThemeMode.light,
                  ),
                  _buildThemeOption(
                    context,
                    Icons.dark_mode,
                    loc.themeDark,
                    ThemeMode.dark,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                loc.bgImage,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildBgOption(context, null, loc.bgDefault),
                    _buildBgOption(
                      context,
                      "bg_mosque1.jpg",
                      "${loc.bgMosque} 1",
                    ),
                    _buildBgOption(
                      context,
                      "bg_mosque2.jpg",
                      "${loc.bgMosque} 2",
                    ),
                    _buildBgOption(
                      context,
                      "bg_mosque3.jpg",
                      "${loc.bgMosque} 3",
                    ),
                    _buildBgOption(
                      context,
                      "bg_mosque4.jpg",
                      "${loc.bgMosque} 4",
                    ),
                    _buildBgOption(
                      context,
                      "bg_mosque5.jpg",
                      "${loc.bgMosque} 5",
                    ),
                    _buildBgOption(
                      context,
                      "bg_mosque6.jpg",
                      "${loc.bgMosque} 6",
                    ),
                    _buildBgOption(
                      context,
                      "bg_kaaba1.jpg",
                      "${loc.bgKaaba} 1",
                    ),
                    _buildBgOption(
                      context,
                      "bg_kaaba2.jpg",
                      "${loc.bgKaaba} 2",
                    ),
                    _buildBgOption(
                      context,
                      "bg_kaaba3.jpg",
                      "${loc.bgKaaba} 3",
                    ),
                    _buildBgOption(
                      context,
                      "bg_kaaba4.jpg",
                      "${loc.bgKaaba} 4",
                    ),
                    _buildBgOption(context, "bg_quran.jpg", loc.bgQuran),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    IconData icon,
    String label,
    ThemeMode mode,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    final isSelected = themeProvider.themeMode == mode;

    return InkWell(
      onTap: () => themeProvider.setThemeMode(mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.teal : Colors.grey),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.teal : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBgOption(BuildContext context, String? image, String label) {
    final themeProvider = context.watch<ThemeProvider>();
    final isSelected = themeProvider.backgroundImage == image;

    return GestureDetector(
      onTap: () => themeProvider.setBackgroundImage(image),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Colors.teal, width: 3) : null,
          color: Colors.grey.shade300,
          image: image != null
              ? DecorationImage(
                  image: AssetImage("assets/images/backgrounds/$image"),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: image == null
            ? Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              _buildLanguageItem(context, "Türkçe", "tr", "🇹🇷"),
              _buildLanguageItem(context, "English", "en", "🇬🇧"),
              _buildLanguageItem(context, "Deutsch", "de", "🇩🇪"),
              _buildLanguageItem(context, "Français", "fr", "🇫🇷"),
              _buildLanguageItem(context, "العربية", "ar", "🇸🇦"),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(
    BuildContext context,
    String name,
    String code,
    String flag,
  ) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      onTap: () {
        context.read<LanguageProvider>().setLanguage(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  void _showCityDistrictDialog(BuildContext context, AppLocalizations loc) {
    final viewModel = context.read<HomeViewModel>();

    if (viewModel.allCitiesAndDistricts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.loading), backgroundColor: Colors.orange),
      );
      return;
    }

    String? selectedCity;
    String? selectedDistrict;
    List<String> districtList = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.changeLocation),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.locationWarning,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: loc.citySelect,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_city),
                    ),
                    initialValue: selectedCity,
                    items: viewModel.citiesList.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCity = value;
                        selectedDistrict = null;
                        if (value != null) {
                          districtList =
                              viewModel.allCitiesAndDistricts[value] ?? [];
                        } else {
                          districtList = [];
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: loc.districtSelect,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.map),
                    ),
                    value: selectedDistrict,
                    items: districtList.isEmpty
                        ? []
                        : districtList.map((district) {
                            return DropdownMenuItem(
                              value: district,
                              child: Text(district),
                            );
                          }).toList(),
                    onChanged: selectedCity == null
                        ? null
                        : (value) {
                            setState(() {
                              selectedDistrict = value;
                            });
                          },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    loc.cancel,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (selectedCity != null) {
                      viewModel.changeCityAndDistrict(
                        selectedCity!,
                        selectedDistrict,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "$selectedCity ${selectedDistrict ?? ''}...",
                          ),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.citySelect),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(loc.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBatteryOptimizationDialog(
    BuildContext context,
    AppLocalizations loc,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.batteryDialogTitle),
        content: SingleChildScrollView(child: Text(loc.batteryDialogBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              loc.okUnderstood,
              style: const TextStyle(color: Colors.teal),
            ),
          ),
        ],
      ),
    );
  }
}
