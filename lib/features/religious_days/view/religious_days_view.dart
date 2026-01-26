import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/json_service.dart';
import '../../common/widgets/ad_banner_widget.dart';

class ReligiousDaysView extends StatefulWidget {
  const ReligiousDaysView({super.key});

  @override
  State<ReligiousDaysView> createState() => _ReligiousDaysViewState();
}

class _ReligiousDaysViewState extends State<ReligiousDaysView> {
  final JsonService jsonService = JsonService();
  int _selectedYear = 2025;
  final List<int> _years = [2025, 2026, 2027, 2028];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
                    child: Text("$year", style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      // --- REKLAM ALANI EKLENDİ ---
      bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
      // ---------------------------
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: jsonService.getReligiousDays(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(loc.errorOccurred(snapshot.error.toString())),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(loc.noDataFound));
          }

          final allData = snapshot.data!;
          final filteredData = allData.where((element) {
            return element['year'] == _selectedYear;
          }).toList();

          if (filteredData.isEmpty) {
            return Center(child: Text(loc.noDataForYear(_selectedYear)));
          }

          return Column(
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
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final day = filteredData[index];
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
                                day['name'],
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
                                  day['date'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  day['day'],
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
          );
        },
      ),
    );
  }
}
