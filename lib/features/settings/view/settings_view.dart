import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../home/view_model/home_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  final String appLink =
      "https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde";

  // TÜRKİYE'NİN 81 İLİ (AUTOCOMPLETE İÇİN)
  static const List<String> _turkeyCities = [
    "Adana",
    "Adıyaman",
    "Afyonkarahisar",
    "Ağrı",
    "Aksaray",
    "Amasya",
    "Ankara",
    "Antalya",
    "Ardahan",
    "Artvin",
    "Aydın",
    "Balıkesir",
    "Bartın",
    "Batman",
    "Bayburt",
    "Bilecik",
    "Bingöl",
    "Bitlis",
    "Bolu",
    "Burdur",
    "Bursa",
    "Çanakkale",
    "Çankırı",
    "Çorum",
    "Denizli",
    "Diyarbakır",
    "Düzce",
    "Edirne",
    "Elazığ",
    "Erzincan",
    "Erzurum",
    "Eskişehir",
    "Gaziantep",
    "Giresun",
    "Gümüşhane",
    "Hakkâri",
    "Hatay",
    "Iğdır",
    "Isparta",
    "İstanbul",
    "İzmir",
    "Kahramanmaraş",
    "Karabük",
    "Karaman",
    "Kars",
    "Kastamonu",
    "Kayseri",
    "Kilis",
    "Kırıkkale",
    "Kırklareli",
    "Kırşehir",
    "Kocaeli",
    "Konya",
    "Kütahya",
    "Malatya",
    "Manisa",
    "Mardin",
    "Mersin",
    "Muğla",
    "Muş",
    "Nevşehir",
    "Niğde",
    "Ordu",
    "Osmaniye",
    "Rize",
    "Sakarya",
    "Samsun",
    "Şanlıurfa",
    "Siirt",
    "Sinop",
    "Sivas",
    "Şırnak",
    "Tekirdağ",
    "Tokat",
    "Trabzon",
    "Tunceli",
    "Uşak",
    "Van",
    "Yalova",
    "Yozgat",
    "Zonguldak",
    "Lefkoşa", "Gazimağusa", "Girne", // Kıbrıs da bonus olsun
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, bottom: 10),
            child: Text(
              "GENEL",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          _buildSettingsCard([
            // 1. Konum
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.teal),
              title: const Text("Konumu Yeniden Bul"),
              subtitle: const Text("Şehir yanlışsa veya değiştiyse tıkla."),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () {
                context.read<HomeViewModel>().refreshLocationAndTimes();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Konum güncelleniyor...")),
                );
              },
            ),
            const Divider(height: 1),

            // 2. Manuel Şehir (AUTOCOMPLETE İLE GÜNCELLENDİ)
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blue),
              title: const Text("Şehir Ara (Manuel)"),
              subtitle: const Text("Şehri listeden seçerek ekleyin."),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () => _showCitySearchDialog(context),
            ),
            const Divider(height: 1),

            // 3. Bildirim İzinleri
            ListTile(
              leading: const Icon(
                Icons.notifications_active,
                color: Colors.orange,
              ),
              title: const Text("Bildirim İzinleri"),
              subtitle: const Text("Ses gelmiyorsa buradan kontrol et."),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () => Geolocator.openAppSettings(),
            ),

            // --- YENİ EKLENEN: SORUN GİDERME ---
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.battery_alert, color: Colors.redAccent),
              title: const Text("Bildirim Gelmiyor mu?"),
              subtitle: const Text("Samsung/Xiaomi için pil ayarı yapın."),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () => _showBatteryOptimizationDialog(context),
            ),
            // -----------------------------------
          ]),

          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.only(left: 10, bottom: 10),
            child: Text(
              "DESTEK",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text("Arkadaşınla Paylaş"),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () {
                Share.share(
                  "Harika bir Ezan Vakti uygulaması buldum! İndir: $appLink",
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text("Bize Puan Ver"),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () async {
                final InAppReview inAppReview = InAppReview.instance;
                try {
                  await inAppReview.openStoreListing(appStoreId: '1234567890');
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
              title: const Text("İletişim & Hata Bildir"),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'mmdigitall.dev@gmail.com',
                  query: 'subject=Ezan Vakti Uygulaması Hakkında',
                );
                if (!await launchUrl(emailLaunchUri)) {
                  debugPrint("Mail açılamadı");
                }
              },
            ),
          ]),

          const SizedBox(height: 30),

          const Center(
            child: Column(
              children: [
                Icon(Icons.mosque, color: Colors.teal, size: 40),
                SizedBox(height: 10),
                Text(
                  "Vaktinde",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text("Versiyon 1.0.0", style: TextStyle(color: Colors.grey)),
                SizedBox(height: 5),
                Text(
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

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // --- GÜNCELLENEN: AUTOCOMPLETE ŞEHİR ARAMA DİYALOĞU ---
  void _showCitySearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Şehir Seç"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Listeden seçebilir veya manuel yazabilirsiniz:",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  // Türkçe karakter duyarlılığı için basit bir lowercase araması
                  return _turkeyCities.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  // Listeden seçilince direkt işlem yap
                  context.read<HomeViewModel>().changeCityManually(selection);
                  Navigator.pop(ctx); // Diyaloğu kapat
                  Navigator.pop(
                    context,
                  ); // Ayarlar sayfasını kapat (Ana sayfaya dön)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$selection için vakitler getiriliyor..."),
                      backgroundColor: Colors.teal,
                    ),
                  );
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          hintText: "Örn: Erzi...",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        // Klavyeden "Tamam"a basınca da çalışsın (Manuel giriş için)
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            context.read<HomeViewModel>().changeCityManually(
                              value,
                            );
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "$value için vakitler getiriliyor...",
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // --- PİL AYARI DİYALOĞU ---
  void _showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bildirim Sorunu Çözümü"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Telefonunuz pil tasarrufu için uygulamayı kapatıyor olabilir. Bunu önlemek için:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              Text("1. Son Uygulamalar (Kare tuşu) ekranını açın."),
              Text(
                "2. 'Vaktinde' uygulamasının üzerine basılı tutun veya logoya tıklayın.",
              ),
              Text("3. Kilit Simgesine 🔒 basarak kilitleyin."),
              SizedBox(height: 15),
              Text(
                "Ayrıca Ayarlar > Uygulamalar > Vaktinde > Pil > Kısıtlanmamış seçeneğini seçin.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Tamam, Anladım",
              style: TextStyle(color: Colors.teal),
            ),
          ),
        ],
      ),
    );
  }
}
