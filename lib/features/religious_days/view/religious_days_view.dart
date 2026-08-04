import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:intl/intl.dart'; // Tarih ve gün formatlaması için
import '../../common/widgets/ad_banner_widget.dart';
// KENDİ PROJENE GÖRE DINI GUNLER SERVISININ YOLUNU BURAYA EKLE:
import '../../../data/services/dini_gunler_service.dart';

class ReligiousDaysView extends StatefulWidget {
  const ReligiousDaysView({super.key});

  @override
  State<ReligiousDaysView> createState() => _ReligiousDaysViewState();
}

class _ReligiousDaysViewState extends State<ReligiousDaysView> {
  late int _selectedYear;
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;

    _years = [2025, 2026, 2027, 2028, 2029, 2030];

    if (!_years.contains(_selectedYear)) {
      _years.add(_selectedYear);
      _years.sort();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // Cihazın geçerli dil kodunu alır (örn: 'tr', 'en', 'de')
    final localeCode = Localizations.localeOf(context).languageCode;

    // Seçili yıla göre dini günleri servisten dinamik olarak alıyoruz
    final yilinGunleri = DiniGunlerService.getYilinDiniGunleri(
      loc,
      _selectedYear,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.religiousDaysTitle),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Theme(
            data: Theme.of(context).copyWith(canvasColor: Colors.teal),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedYear = newValue;
                    });
                  }
                },
                items: _years.map<DropdownMenuItem<int>>((int year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(
                      year.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
      body: yilinGunleri.isEmpty
          ? Center(child: Text(loc.noDataForYear(_selectedYear)))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: Colors.teal.shade50,
                  child: Center(
                    child: Text(
                      loc.religiousDaysListTitle(_selectedYear),
                      style: TextStyle(
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: yilinGunleri.length,
                    itemBuilder: (context, index) {
                      final day = yilinGunleri[index];

                      // Tarihi "15 Mart 2025" gibi formatlar
                      final dateStr = DateFormat(
                        'dd MMMM yyyy',
                        localeCode,
                      ).format(day.tarih);
                      // Günü "Cumartesi" gibi formatlar
                      final dayStr = DateFormat(
                        'EEEE',
                        localeCode,
                      ).format(day.tarih);

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  day.isim,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dayStr,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
