import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ad_consent.dart';
import '../ad_helper.dart';

/// Standart banner (320x50). Reklam rızası/SDK hazır olunca yüklenir;
/// yüklenemezse yer kaplamaz.
class AdBannerWidget extends StatefulWidget {
  /// Varsayılan: iç ekran banner'ı
  final String? adUnitId;

  const AdBannerWidget({super.key, this.adUnitId});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (AdConsent.canRequestAds.value) {
      _loadAd();
    } else {
      AdConsent.canRequestAds.addListener(_onConsentChanged);
    }
  }

  void _onConsentChanged() {
    if (!AdConsent.canRequestAds.value || !mounted) return;
    AdConsent.canRequestAds.removeListener(_onConsentChanged);
    _loadAd();
  }

  void _loadAd() {
    if (_bannerAd != null) return;
    try {
      _bannerAd = BannerAd(
        adUnitId: widget.adUnitId ?? AdIds.innerBanner,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) setState(() => _isLoaded = true);
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('Banner yüklenemedi: $err');
            ad.dispose();
            if (identical(_bannerAd, ad)) _bannerAd = null;
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('Banner oluşturulamadı: $e');
      _bannerAd = null;
    }
  }

  @override
  void dispose() {
    AdConsent.canRequestAds.removeListener(_onConsentChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (_isLoaded && ad != null) {
      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: ad.size.height.toDouble(),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
