import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../main_wrapper/main_wrapper.dart';

class IntroView extends StatefulWidget {
  const IntroView({super.key});

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // Kullanıcı tanıtımı bitirince hafızaya kaydedip ana sayfaya atarız
  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_intro_seen', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    const primaryColor = Colors.teal;

    // Tanıtım Kartlarının İçerikleri (İkon, Başlık, Açıklama)
    final List<Map<String, dynamic>> introData = [
      {
        "icon": Icons.mosque_rounded,
        "title": loc.introTitle1,
        "desc": loc.introDesc1,
      },
      {
        "icon": Icons.notifications_active_rounded,
        "title": loc.introTitle2,
        "desc": loc.introDesc2,
      },
      {
        "icon": Icons.dashboard_customize_rounded,
        "title": loc.introTitle3,
        "desc": loc.introDesc3,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // "GEÇ" Butonu (Sadece son sayfada değilse görünür)
          if (_currentPage != introData.length - 1)
            TextButton(
              onPressed: _completeIntro,
              child: Text(
                loc.introSkip,
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // KAYDIRILABİLİR KARTLAR (PageView)
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: introData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Şık İkon Arka Planı
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(
                              isDark ? 0.1 : 0.05,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            introData[index]["icon"],
                            size: 100,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 50),
                        // Başlık
                        Text(
                          introData[index]["title"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Açıklama
                        Text(
                          introData[index]["desc"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ALT KISIM (Noktalar ve İleri/Başla Butonu)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Noktalar (İndikatör)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        introData.length,
                        (index) => _buildDot(index, primaryColor),
                      ),
                    ),

                    // İleri veya Başla Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == introData.length - 1) {
                            _completeIntro(); // Son sayfadaysa bitir
                          } else {
                            // Değilse bir sonraki sayfaya kaydır
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: isDark ? 0 : 5,
                        ),
                        child: Text(
                          _currentPage == introData.length - 1
                              ? loc.introStart
                              : loc.introNext,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nokta (İndikatör) Animasyonu
  Widget _buildDot(int index, Color primaryColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? primaryColor
            : primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
