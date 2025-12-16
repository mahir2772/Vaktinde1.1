import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Sadece sayı girişi için gerekli
import '../../../data/services/storage_service.dart';

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

  // --- YENİ EKLENEN: MANUEL SAYI GİRME FONKSİYONU ---
  void _showManualEntryDialog(String title) {
    TextEditingController controller = TextEditingController(
      text: _missedPrayers[title].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$title Kazasını Düzenle"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ], // Sadece rakam
            decoration: const InputDecoration(
              labelText: "Kaza Sayısı",
              border: OutlineInputBorder(),
              hintText: "Örn: 150",
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                int? newValue = int.tryParse(controller.text);
                if (newValue != null) {
                  setState(() {
                    _missedPrayers[title] = newValue;
                  });
                  _storageService.updateMissedPrayer(title, newValue);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }
  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kaza Takibi"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
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
                          "Kılmadığınız namazları buraya not edip, kıldıkça düşebilirsiniz.\n(Sayıya tıklayarak elle girebilirsiniz)",
                          style: TextStyle(color: Colors.teal.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPrayerItem("Sabah", Icons.wb_twilight),
                _buildPrayerItem("Öğle", Icons.wb_sunny),
                _buildPrayerItem("İkindi", Icons.wb_sunny_outlined),
                _buildPrayerItem("Akşam", Icons.nights_stay_outlined),
                _buildPrayerItem("Yatsı", Icons.nights_stay),
                _buildPrayerItem("Vitir", Icons.star_border),
                const Divider(),
                _buildPrayerItem("Oruç", Icons.restaurant_menu),
              ],
            ),
    );
  }

  Widget _buildPrayerItem(String title, IconData icon) {
    int count = _missedPrayers[title] ?? 0;

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
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _updateCount(title, -1),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              iconSize: 32,
            ),

            // --- BURASI GÜNCELLENDİ: TIKLANABİLİR SAYI ALANI ---
            InkWell(
              onTap: () =>
                  _showManualEntryDialog(title), // Tıklayınca diyalog aç
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
                    color: Colors.teal, // Rengi dikkat çeksin diye teal yaptım
                  ),
                ),
              ),
            ),

            // ---------------------------------------------------
            IconButton(
              onPressed: () => _updateCount(title, 1),
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              iconSize: 32,
            ),
          ],
        ),
      ),
    );
  }
}
