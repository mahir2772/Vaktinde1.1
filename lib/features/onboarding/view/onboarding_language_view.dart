import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/language_provider.dart';
// --- YENİ EKLENEN İMPORT ---
import 'intro_view.dart';

class OnboardingLanguageView extends StatelessWidget {
  const OnboardingLanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Icon(
                  Icons.language,
                  size: 80,
                  color: Colors.teal.shade300,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Hoş Geldiniz / Welcome",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Lütfen kullanmak istediğiniz dili seçin.\nPlease select your preferred language.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // DİL LİSTESİ
              Expanded(
                child: ListView(
                  children: [
                    _buildLanguageCard(context, "Türkçe", "tr", "🇹🇷"),
                    _buildLanguageCard(context, "English", "en", "🇬🇧"),
                    _buildLanguageCard(context, "Deutsch", "de", "🇩🇪"),
                    _buildLanguageCard(context, "Français", "fr", "🇫🇷"),
                    _buildLanguageCard(context, "العربية", "ar", "🇸🇦"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    String name,
    String code,
    String flag,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // 1. Dili güncelle ve hafızaya "seçildi" olarak kaydet
          context.read<LanguageProvider>().setLanguage(Locale(code));

          // 2. Ana Sayfa yerine ÖNCE TANITIM (INTRO) sayfasına yönlendir!
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const IntroView()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 20),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
