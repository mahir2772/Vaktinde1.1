import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../view_model/zikir_view_model.dart';
import '../../common/widgets/ad_banner_widget.dart';

class DhikrStatsView extends StatelessWidget {
  const DhikrStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    const primaryColor = Colors.teal;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(loc.statisticsTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: textColor,
          bottom: TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: textColor.withOpacity(0.5),
            indicatorColor: primaryColor,
            tabs: [
              Tab(text: loc.monthly),
              Tab(text: loc.yearly),
            ],
          ),
        ),
        body: Consumer<ZikirViewModel>(
          builder: (context, viewModel, child) {
            return TabBarView(
              children: [
                // AYLIK GRAFİK (Günler)
                _buildProfessionalChart(
                  context,
                  viewModel.dailyStats,
                  true,
                  textColor,
                ),
                // YILLIK GRAFİK (Aylar)
                _buildProfessionalChart(
                  context,
                  viewModel.dailyStats,
                  false,
                  textColor,
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
      ),
    );
  }

  // GRAFİK EKSENİNİ (Y-Axis) HESAPLAMA MANTIĞI
  int _calculateNiceTopMax(int maxVal) {
    int topMax = 10;
    while (topMax < maxVal) {
      if (topMax < 50)
        topMax += 10;
      else if (topMax < 500)
        topMax += 50;
      else if (topMax < 5000)
        topMax += 500;
      else if (topMax < 50000)
        topMax += 5000;
      else
        topMax += 50000;
    }
    return topMax;
  }

  // PROFESYONEL BAR GRAFİĞİ TASARIMI
  Widget _buildProfessionalChart(
    BuildContext context,
    Map<String, int> stats,
    bool isMonthly,
    Color textColor,
  ) {
    final now = DateTime.now();
    List<int> values = [];
    List<String> labels = [];
    int totalSum = 0;

    // Görseldeki gibi döngülü şık renkler
    final List<Color> barColors = [
      const Color(0xFFD84B79), // Pembe
      const Color(0xFFF28F1B), // Turuncu
      const Color(0xFFF5E05E), // Sarı
      const Color(0xFF6A9D7E), // Yeşil
      const Color(0xFF35B2C6), // Cam Göbeği
    ];

    if (isMonthly) {
      int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      for (int i = 1; i <= daysInMonth; i++) {
        String key =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
        int val = stats[key] ?? 0;
        values.add(val);
        totalSum += val;
        labels.add(i.toString());
      }
    } else {
      final monthNames = [
        "Oca",
        "Şub",
        "Mar",
        "Nis",
        "May",
        "Haz",
        "Tem",
        "Ağu",
        "Eyl",
        "Eki",
        "Kas",
        "Ara",
      ];
      for (int i = 1; i <= 12; i++) {
        int monthSum = 0;
        stats.forEach((key, value) {
          if (key.startsWith("${now.year}-${i.toString().padLeft(2, '0')}-"))
            monthSum += value;
        });
        values.add(monthSum);
        totalSum += monthSum;
        labels.add(monthNames[i - 1]);
      }
    }

    int maxVal = values.isEmpty
        ? 10
        : values.reduce((curr, next) => curr > next ? curr : next);
    if (maxVal == 0) maxVal = 10;

    int topMax = _calculateNiceTopMax(maxVal);
    int step = topMax ~/ 5; // 5 Satırlık Izgara

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. ARKA PLAN IZGARALARI VE Y EKSENİ ETİKETLERİ
                Positioned(
                  top: 0,
                  bottom: 30,
                  left: 10,
                  right: 10, // Alt etikete 30px boşluk bıraktık
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      int val = topMax - (index * step);
                      return Row(
                        children: [
                          SizedBox(
                            width: 35,
                            child: Text(
                              val.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              height: 1,
                            ),
                          ),
                          SizedBox(
                            width: 35,
                            child: Text(
                              val.toString(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),

                // 2. ÇUBUKLAR VE X EKSENİ ETİKETLERİ (KAYDIRILABİLİR ALAN)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 45,
                      right: 45,
                    ), // Y Ekseninin üstüne binmemesi için padding
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: values.length,
                      itemBuilder: (context, index) {
                        double heightRatio = values[index] / topMax;
                        return Container(
                          width: isMonthly ? 30 : 40,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Çubuğun üstündeki değer
                              if (values[index] > 0)
                                Text(
                                  values[index].toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              // Çubuğun Kendisi (Arka Plan Çizgilerinin sadece 30px üstüne kadar iner)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 30,
                                  ), // Alt etiketlere yer ayır
                                  child: FractionallySizedBox(
                                    heightFactor: heightRatio,
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color:
                                            barColors[index % barColors.length],
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(3),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 3. ALT ETİKETLER (Aylar veya Günler)
                Positioned(
                  bottom: 5,
                  left: 45,
                  right: 45,
                  height: 20,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics:
                        const NeverScrollableScrollPhysics(), // Çubuklarla beraber kayması için iptal edilebilir ama şık dursun diye bıraktık
                    itemCount: labels.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: isMonthly ? 30 : 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor.withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- GÖRSELDEKİ ALT BİLGİ PANELİ ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Yıl Seçici Görünümü
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      now.year.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(Icons.keyboard_arrow_down, color: textColor),
                  ],
                ),
              ),
              // Toplam Zikir Sayısı
              Text(
                "Toplam zikir sayısı $totalSum",
                style: const TextStyle(
                  color: Color(0xFFB57A2A),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
