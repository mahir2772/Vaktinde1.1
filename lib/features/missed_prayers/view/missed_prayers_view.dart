import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// --- DİL İMPORTU ---
import 'package:ezan_saati/l10n/app_localizations.dart';
// -------------------
import '../../../data/services/storage_service.dart';
// --- REKLAM İMPORTU ---
import '../../common/widgets/ad_banner_widget.dart';

class MissedPrayersView extends StatefulWidget {
  const MissedPrayersView({super.key});

  @override
  State<MissedPrayersView> createState() => _MissedPrayersViewState();
}

class _MissedPrayersViewState extends State<MissedPrayersView> {
  final StorageService _storageService = StorageService();

  Map<String, int> _missedPrayers = {
    "Sabah": 0,
    "Öğle": 0,
    "İkindi": 0,
    "Akşam": 0,
    "Yatsı": 0,
    "Vitir": 0,
    "Oruç": 0,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _storageService.loadMissedPrayers();
    setState(() {
      _missedPrayers = data;
      _isLoading = false;
    });
  }

  void _updateCount(String key, int delta) {
    int current = _missedPrayers[key] ?? 0;
    int newValue = current + delta;
    if (newValue < 0) newValue = 0;

    setState(() {
      _missedPrayers[key] = newValue;
    });
    _storageService.updateMissedPrayer(key, newValue);
  }

  String _getLocalizedTitle(String key, AppLocalizations loc) {
    switch (key) {
      case "Sabah":
        return loc.sabah;
      case "Öğle":
        return loc.ogle;
      case "İkindi":
        return loc.ikindi;
      case "Akşam":
        return loc.aksam;
      case "Yatsı":
        return loc.yatsi;
      case "Vitir":
        return loc.vitir;
      case "Oruç":
        return loc.oruc;
      default:
        return key;
    }
  }

  void _showManualEntryDialog(String key, AppLocalizations loc) {
    String currentValue = _missedPrayers[key].toString();

    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    // DÜZELTİLEN KISIM: Kutu açıldığında metnin tamamı seçili (highlight) olarak gelsin
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: currentValue.length,
    );

    String displayTitle = _getLocalizedTitle(key, loc);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.editMissedTitle(displayTitle)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: loc.missedCountLabel,
              border: const OutlineInputBorder(),
              hintText: loc.missedCountHint,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                loc.cancel,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                int? newValue = int.tryParse(controller.text);
                if (newValue != null) {
                  setState(() {
                    _missedPrayers[key] = newValue;
                  });
                  _storageService.updateMissedPrayer(key, newValue);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.missedPrayersTitle),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // --- REKLAM ALANI EKLENDİ ---
      bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
      // ---------------------------
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.missedPrayersInfo,
                          style: TextStyle(color: Colors.teal.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPrayerItem("Sabah", Icons.wb_twilight, loc),
                _buildPrayerItem("Öğle", Icons.wb_sunny, loc),
                _buildPrayerItem("İkindi", Icons.wb_sunny_outlined, loc),
                _buildPrayerItem("Akşam", Icons.nights_stay_outlined, loc),
                _buildPrayerItem("Yatsı", Icons.nights_stay, loc),
                _buildPrayerItem("Vitir", Icons.star_border, loc),
                const Divider(),
                _buildPrayerItem("Oruç", Icons.restaurant_menu, loc),
              ],
            ),
    );
  }

  Widget _buildPrayerItem(String key, IconData icon, AppLocalizations loc) {
    int count = _missedPrayers[key] ?? 0;
    String displayTitle = _getLocalizedTitle(key, loc);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.teal),
            ),
            const SizedBox(width: 15),
            Text(
              displayTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _updateCount(key, -1),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              iconSize: 32,
            ),
            InkWell(
              onTap: () => _showManualEntryDialog(key, loc),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 60),
                child: Text(
                  "$count",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    color: Colors.teal,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _updateCount(key, 1),
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              iconSize: 32,
            ),
          ],
        ),
      ),
    );
  }
}
