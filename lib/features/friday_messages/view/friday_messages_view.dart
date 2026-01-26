import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
// --- DİL İMPORTU ---
import 'package:ezan_saati/l10n/app_localizations.dart';
// -------------------
import '../../../data/services/json_service.dart';
// --- REKLAM İMPORTU ---
import '../../common/widgets/ad_banner_widget.dart';

class FridayMessagesView extends StatefulWidget {
  const FridayMessagesView({super.key});

  @override
  State<FridayMessagesView> createState() => _FridayMessagesViewState();
}

class _FridayMessagesViewState extends State<FridayMessagesView> {
  final JsonService jsonService = JsonService();
  List<String>? _messages;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    String currentLanguage = Localizations.localeOf(context).languageCode;
    if (_messages == null) {
      final list = await jsonService.getFridayMessages(currentLanguage);
      if (mounted) {
        setState(() {
          _messages = list;
          _isLoading = false;
        });
      }
    }
  }

  void _shuffleMessages() {
    if (_messages != null) {
      setState(() {
        _messages!.shuffle();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mesajlar karıştırıldı!"),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.fridayMessagesTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _shuffleMessages,
            icon: const Icon(Icons.shuffle),
            tooltip: "Karıştır",
          ),
        ],
      ),
      backgroundColor: const Color(0xFF2d3436),
      // --- REKLAM ALANI (Koyu zemin üzerine şeffaf bir SafeArea içine) ---
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: AdBannerWidget(),
        ),
      ),
      // ------------------------------------------------------------------
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _messages!.length,
              itemBuilder: (context, index) {
                final message = _messages![index];
                return _buildMessagePage(
                  message,
                  index + 1,
                  _messages!.length,
                  loc,
                );
              },
            ),
    );
  }

  Widget _buildMessagePage(
    String message,
    int currentIndex,
    int totalCount,
    AppLocalizations loc,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2d3436), Color(0xFF00b894)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$currentIndex / $totalCount",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const Spacer(),
          const Icon(Icons.format_quote, color: Colors.white54, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
              fontFamily: 'Roboto',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          const Icon(Icons.format_quote, color: Colors.white54, size: 40),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.copy,
                label: "Kopyala",
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Mesaj kopyalandı"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: 30),
              _buildActionButton(
                icon: Icons.share,
                label: loc.share,
                isPrimary: true,
                onTap: () => Share.share(message),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white30,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.1),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.teal : Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
