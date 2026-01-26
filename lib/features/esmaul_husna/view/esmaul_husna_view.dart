import 'package:flutter/material.dart';
// --- DİL İMPORTU ---
import 'package:ezan_saati/l10n/app_localizations.dart';
// -------------------
import '../../../data/services/json_service.dart';
// --- REKLAM İMPORTU ---
import '../../common/widgets/ad_banner_widget.dart';

class EsmaulHusnaView extends StatelessWidget {
  const EsmaulHusnaView({super.key});

  @override
  Widget build(BuildContext context) {
    final JsonService jsonService = JsonService();
    final loc = AppLocalizations.of(context)!;
    String currentLanguage = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.esmaulHusnaTitle),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // --- REKLAM ALANI EKLENDİ ---
      bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
      // ---------------------------
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: jsonService.getEsmaulHusna(currentLanguage),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final data = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];

              return GestureDetector(
                onTap: () {
                  _showDetailDialog(context, data, index, loc);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['arabic'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item['name'],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              width: 30,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  item['meaning'],
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.touch_app_outlined,
                              size: 14,
                              color: Colors.teal.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(15),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    List<Map<String, dynamic>> allData,
    int initialIndex,
    AppLocalizations loc,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final item = allData[initialIndex];
            bool isFirst = initialIndex == 0;
            bool isLast = initialIndex == allData.length - 1;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['arabic'],
                      style: const TextStyle(
                        fontSize: 45,
                        color: Colors.teal,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${initialIndex + 1}. ${item['name']}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(color: Colors.teal, thickness: 1, height: 30),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          item['meaning'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filledTonal(
                          onPressed: isFirst
                              ? null
                              : () {
                                  setState(() {
                                    initialIndex--;
                                  });
                                },
                          icon: const Icon(Icons.arrow_back_ios_new),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.teal.shade50,
                            foregroundColor: Colors.teal,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            loc.closeCaps,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: isLast
                              ? null
                              : () {
                                  setState(() {
                                    initialIndex++;
                                  });
                                },
                          icon: const Icon(Icons.arrow_forward_ios),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.teal.shade50,
                            foregroundColor: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
