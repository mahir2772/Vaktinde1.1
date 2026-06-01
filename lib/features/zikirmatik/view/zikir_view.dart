import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../view_model/zikir_view_model.dart';
import 'zikir_settings_view.dart';
import 'dhikr_list_view.dart';
import 'dhikr_stats_view.dart';

class ZikirView extends StatelessWidget {
  const ZikirView({super.key});

  // --- EKSİK OLAN ÇEVİRİ FONKSİYONU BURAYA EKLENDİ ---
  String _getTranslatedName(String id, AppLocalizations loc) {
    switch (id) {
      case "Sübhanallah":
        return loc.dhikrSubhanallah;
      case "Elhamdülillah":
        return loc.dhikrElhamdulillah;
      case "Allahu Ekber":
        return loc.dhikrAllahuEkber;
      case "Kelime-i Tevhid":
        return loc.dhikrKalima;
      case "Salavat":
        return loc.dhikrSalavat;
      case "Estağfirullah":
        return loc.dhikrEstagfirullah;
      case "La Havle":
        return loc.dhikrLaHavle;
      case "Hasbünallah":
        return loc.dhikrHasbunallah;
      case "Subhanallahi":
        return loc.dhikrSubhanallahi;
      case "Hz. Yunus":
        return loc.dhikrYunus;
      case "Ya Allah":
        return loc.dhikrYaAllah;
      case "Ya Rahman":
        return loc.dhikrYaRahman;
      case "Ya Rahim":
        return loc.dhikrYaRahim;
      case "Ya Şafi":
        return loc.dhikrYaSafi;
      case "Ya Rezzak":
        return loc.dhikrYaRezzak;
      case "Ya Fettah":
        return loc.dhikrYaFettah;
      default:
        return id; // Özel zikirse kullanıcının yazdığı gibi döner
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    const primaryColor = Colors.teal;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(loc.zikirmatikTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false, // İkonlara yer kalsın diye başlığı sola yasladık
        foregroundColor: textColor,
        actions: [
          // 1. ZİKİR LİSTESİ BUTONU
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: loc.dhikrListTitle,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DhikrListView()),
              );
            },
          ),
          // 2. İSTATİSTİKLER (GRAFİK) BUTONU
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: loc.statisticsTitle,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DhikrStatsView()),
              );
            },
          ),
          // 3. AYARLAR BUTONU
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: loc.zikirSettings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ZikirSettingsView(),
                ),
              );
            },
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Consumer<ZikirViewModel>(
        builder: (context, viewModel, child) {
          String arabicText = viewModel.getArabicForDhikr(
            viewModel.selectedDhikr,
          );
          // --- ÇEVİRİ BURADA UYGULANDI ---
          String translatedDhikrName = _getTranslatedName(
            viewModel.selectedDhikr,
            loc,
          );

          return Column(
            children: [
              // --- ÜST BİLGİ PANELİ (ZİKİR VE HEDEF) ---
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // SOL TARAF: Zikir Adı ve Arapçası
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translatedDhikrName, // Dinamik çevrilmiş hali yazdırılır
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (arabicText.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              arabicText,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Amiri', // Varsa şık arapça fontu
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // SAĞ TARAF: Hedef Seçici (Kapsül Tasarım)
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value:
                                viewModel.targetOptions.contains(
                                  viewModel.target,
                                )
                                ? viewModel.target
                                : viewModel.targetOptions.first,
                            isExpanded: true,
                            dropdownColor: cardColor,
                            icon: Icon(
                              Icons.flag,
                              color: primaryColor,
                              size: 20,
                            ),
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            items: viewModel.targetOptions.map((
                              int targetValue,
                            ) {
                              return DropdownMenuItem<int>(
                                value: targetValue,
                                child: Text("Hedef: $targetValue"),
                              );
                            }).toList(),
                            onChanged: (int? newTarget) {
                              if (newTarget != null) {
                                viewModel.setTarget(newTarget);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- ORTA ALAN: GÖRÜNÜM SEÇİMİNE GÖRE (DEV BUTON VEYA TESBİH) ---
              Expanded(
                child: Center(
                  child: viewModel.viewMode == 0
                      ? _buildModernView(
                          context,
                          viewModel,
                          loc,
                          cardColor,
                          textColor,
                          primaryColor,
                          isDark,
                        )
                      : _ClassicTasbihView(viewModel: viewModel, loc: loc),
                ),
              ),

              // --- ALT PANEL: Sıfırlama Butonu ---
              if (viewModel.viewMode == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: ElevatedButton.icon(
                    onPressed: () => _showResetDialog(
                      context,
                      viewModel,
                      loc,
                      cardColor,
                      textColor,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: Text(loc.resetCounter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- MODERN GÖRÜNÜM (DEV BUTON) ---
  Widget _buildModernView(
    BuildContext context, // Context eklendi
    ZikirViewModel viewModel,
    AppLocalizations loc,
    Color cardColor,
    Color textColor,
    Color primaryColor,
    bool isDark,
  ) {
    bool targetReached =
        viewModel.count > 0 && viewModel.count % viewModel.target == 0;

    return GestureDetector(
      onTap: () => viewModel.increment(),
      onLongPress: () => _showEditCountDialog(
        context,
        viewModel,
        loc,
        cardColor,
        textColor,
        primaryColor,
      ), // BASILI TUTUNCA AÇILIR
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(isDark ? 0.15 : 0.3),
              blurRadius: 50,
              spreadRadius: 10,
            ),
          ],
          border: Border.all(
            color: targetReached ? Colors.green : primaryColor.withOpacity(0.5),
            width: 8,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SAYININ TAŞMASINI ENGELLEYEN VE EKRANA SIĞDIRAN KUTU (FittedBox)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${viewModel.count}',
                    style: TextStyle(
                      fontSize: 90,
                      fontWeight: FontWeight.bold,
                      color: targetReached ? Colors.green : textColor,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              if (targetReached)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      loc.targetReached,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // KULLANICIYA GİZLİ İPUCU
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "(Düzenlemek için basılı tutun)",
                  style: TextStyle(
                    color: textColor.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MANUEL SAYI GİRME DİYALOĞU ---
void _showEditCountDialog(
  BuildContext context,
  ZikirViewModel viewModel,
  AppLocalizations loc,
  Color cardColor,
  Color textColor,
  Color primaryColor,
) {
  TextEditingController controller = TextEditingController(
    text: viewModel.count.toString(),
  );
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Sayacı Düzenle",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number, // Sadece klavye sayıları çıkar
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: "Örn: 2000",
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
          ),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              int? newVal = int.tryParse(controller.text);
              if (newVal != null && newVal >= 0) {
                viewModel.setCount(newVal); // YENİ SAYIYI BEYNE GÖNDER
              }
            }
            Navigator.pop(context);
          },
          child: Text(
            loc.save,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

// SIFIRLAMA DİYALOĞU
void _showResetDialog(
  BuildContext context,
  ZikirViewModel viewModel,
  AppLocalizations loc,
  Color cardColor,
  Color textColor,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        loc.resetCounter,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      content: Text(
        "Sayacı sıfırlamak istediğinize emin misiniz?",
        style: TextStyle(color: textColor.withOpacity(0.8)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            viewModel.reset();
            Navigator.pop(context);
          },
          child: const Text(
            "Sıfırla",
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

// --- AŞAĞI ÇEKMELİ KLASİK TESBİH ANİMASYONU ---
class _ClassicTasbihView extends StatefulWidget {
  final ZikirViewModel viewModel;
  final AppLocalizations loc;

  const _ClassicTasbihView({required this.viewModel, required this.loc});

  @override
  State<_ClassicTasbihView> createState() => _ClassicTasbihViewState();
}

class _ClassicTasbihViewState extends State<_ClassicTasbihView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int visibleBeads = 6;
  final double beadHeight = 65.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pullBead() {
    if (_controller.isAnimating) return;
    widget.viewModel.increment();
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    bool targetReached =
        widget.viewModel.count > 0 &&
        widget.viewModel.count % widget.viewModel.target == 0;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // SAYAÇ GÖSTERGESİ
        GestureDetector(
          onLongPress: () => _showEditCountDialog(
            context,
            widget.viewModel,
            widget.loc,
            Theme.of(context).cardColor,
            textColor,
            Colors.teal,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: targetReached
                    ? Colors.green
                    : Colors.teal.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${widget.viewModel.count}',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: targetReached ? Colors.green : textColor,
                      height: 1.0,
                    ),
                  ),
                ),
                if (targetReached)
                  Text(
                    widget.loc.targetReached,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // İP VE BONCUKLAR
        Expanded(
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 0) _pullBead();
            },
            onTap: _pullBead,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return SizedBox(
                  width: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 5, color: Colors.brown.shade800),
                      for (int i = -1; i <= visibleBeads; i++)
                        Positioned(
                          top: (i + _controller.value) * beadHeight + 10,
                          child: Opacity(
                            opacity: (i == visibleBeads)
                                ? 1.0 - _controller.value
                                : (i == -1)
                                ? _controller.value
                                : 1.0,
                            child: _buildBead(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // SIFIRLA BUTONU
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 30),
                child: IconButton(
                  onPressed: () => _showResetDialog(
                    context,
                    widget.viewModel,
                    widget.loc,
                    Theme.of(context).cardColor,
                    textColor,
                  ),
                  icon: const Icon(Icons.refresh, size: 30),
                  color: Colors.redAccent,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBead() {
    return Container(
      width: 55,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.brown.shade600,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 5)),
        ],
        gradient: RadialGradient(
          colors: [Colors.orange.shade300, Colors.brown.shade700],
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
        ),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 45,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
        ),
      ),
    );
  }
}
