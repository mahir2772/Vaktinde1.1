import 'package:flutter/material.dart';
import '../../esmaul_husna/view/esmaul_husna_view.dart';
import '../../religious_days/view/religious_days_view.dart';
import '../../friday_messages/view/friday_messages_view.dart';
import '../../zakat/view/zakat_view.dart';
import '../../settings/view/settings_view.dart';

class ToolsView extends StatelessWidget {
  const ToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Diğer Araçlar"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _buildToolCard(
            context,
            title: "Zekat Hesapla",
            icon: Icons.calculate,
            color: Colors.green,
            page: const ZakatView(),
          ),
          _buildToolCard(
            context,
            title: "Dini Günler",
            icon: Icons.calendar_month,
            color: Colors.purple,
            page: const ReligiousDaysView(),
          ),
          _buildToolCard(
            context,
            title: "Esmaül Hüsna",
            icon: Icons.menu_book,
            color: Colors.blue,
            page: const EsmaulHusnaView(),
          ),
          _buildToolCard(
            context,
            title: "Cuma Mesajları",
            icon: Icons.message,
            color: Colors.teal,
            page: const FridayMessagesView(),
          ),
          _buildToolCard(
            context,
            title: "Ayarlar",
            icon: Icons.settings,
            color: Colors.grey,
            page: const SettingsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            // DÜZELTME: withValues kullanıldı
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                // DÜZELTME: withValues kullanıldı
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
