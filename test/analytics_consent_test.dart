// AB/EEA rızası → Firebase Analytics izinleri (Consent Mode v2): UMP'nin
// yazdığı IAB TCF kaydından sade eşleme; UMP sonucu beklenirken (bilinen AB
// kullanıcısında) izinsiz; "Reklam gizlilik ayarları"ndan sonra yeniden.
import 'package:ezan_saati/features/common/ad_consent.dart';
import 'package:ezan_saati/features/common/app_analytics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _umpChannel = 'plugins.flutter.io/google_mobile_ads/ump';
const _adsChannel = 'plugins.flutter.io/google_mobile_ads';
const _device = MethodChannel('vaktinde/device');

const _granted = AnalyticsConsent.granted;
const _denied = AnalyticsConsent.denied;
const _storageOnly = AnalyticsConsent(
  analyticsStorage: true,
  adStorage: true,
  adUserData: false,
  adPersonalization: false,
);

// UMP Android değerleri: rıza 0 bilinmiyor, 1 gerekmiyor, 2 gerekli, 3 alındı;
// gizlilik seçenekleri 0 gerekmiyor, 1 gerekli, 2 bilinmiyor
const int _unknown = 0;
const int _notRequired = 1;
const int _required = 2;
const int _obtained = 3;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('TCF → izin eşlemesi', () {
    AnalyticsConsent map(
      int? gdpr,
      String? purposes, {
      ConsentRequirement requirement = ConsentRequirement.required,
      bool updated = true,
    }) => AnalyticsConsent.fromTcf(
      gdprApplies: gdpr,
      purposeConsents: purposes,
      requirement: requirement,
      updated: updated,
    );

    test('GDPR geçerli: amaç 1 → saklama; amaç 1+3+4 → reklam verisi ve '
        'kişiselleştirme', () {
      expect(map(1, '1111111111'), _granted);
      expect(map(1, '1011'), _granted);
      expect(map(1, '1000000000'), _storageOnly);
      expect(map(1, '1101111111'), _storageOnly); // amaç 3 yok
      expect(map(1, '1110111111'), _storageOnly); // amaç 4 yok
      expect(map(1, '0111111111'), _denied); // amaç 1 yok: hiçbiri
      expect(map(1, '1'), _storageOnly); // kısa kayıt: eksik amaç onaysız
      expect(map(1, ''), _denied);
      expect(map(1, null), _denied);
      // UMP güncellenemese de cihazdaki son seçim geçerli
      expect(map(1, '1111', updated: false), _granted);
    });

    test('rıza bekleniyorsa (form doldurulmadı/yenilenmeli) eski kayıt '
        'kullanılmaz', () {
      expect(
        map(1, '1111111111', requirement: ConsentRequirement.pending),
        _denied,
      );
      expect(map(null, null, requirement: ConsentRequirement.pending), _denied);
    });

    test('GDPR geçerli değil: hepsi açık', () {
      for (final requirement in ConsentRequirement.values) {
        expect(map(0, null, requirement: requirement), _granted);
        expect(
          map(0, '0000', requirement: requirement, updated: false),
          _granted,
        );
      }
    });

    test(
      'GDPR bilinmiyor: sadece UMP bu oturumda "gerekmiyor" dediyse açık',
      () {
        expect(
          map(null, null, requirement: ConsentRequirement.notRequired),
          _granted,
        );
        expect(
          map(2, null, requirement: ConsentRequirement.notRequired),
          _granted,
        );
        expect(
          map(
            null,
            null,
            requirement: ConsentRequirement.notRequired,
            updated: false,
          ),
          _denied,
        );
        expect(
          map(null, null, requirement: ConsentRequirement.required),
          _denied,
        );
        expect(
          map(null, null, requirement: ConsentRequirement.unknown),
          _denied,
        );
      },
    );

    test('UMP durumu → rıza gerekliliği', () {
      ConsentRequirement of(
        ConsentStatus? status,
        PrivacyOptionsRequirementStatus? privacy,
      ) => AdConsent.requirementOf(status: status, privacyOptions: privacy);
      const required = PrivacyOptionsRequirementStatus.required;
      const notRequired = PrivacyOptionsRequirementStatus.notRequired;
      expect(of(ConsentStatus.required, required), ConsentRequirement.pending);
      expect(of(ConsentStatus.required, null), ConsentRequirement.pending);
      expect(of(ConsentStatus.obtained, required), ConsentRequirement.required);
      expect(
        of(ConsentStatus.obtained, notRequired),
        ConsentRequirement.required,
      );
      expect(of(ConsentStatus.unknown, required), ConsentRequirement.required);
      expect(of(null, required), ConsentRequirement.required);
      expect(
        of(ConsentStatus.notRequired, notRequired),
        ConsentRequirement.notRequired,
      );
      expect(
        of(ConsentStatus.unknown, notRequired),
        ConsentRequirement.unknown,
      );
      expect(of(null, null), ConsentRequirement.unknown);
    });

    test('izin SDK\'ya hatasız iletilir; SDK hatası fırlatılmaz', () async {
      final original = AppAnalytics.consentSink;
      addTearDown(() => AppAnalytics.consentSink = original);
      final sent = <AnalyticsConsent>[];
      AppAnalytics.consentSink = (consent) async => sent.add(consent);
      await AppAnalytics.applyConsent(_storageOnly);
      expect(sent, [_storageOnly]);
      AppAnalytics.consentSink = (consent) => throw StateError('firebase');
      await AppAnalytics.applyConsent(_denied);
      // Firebase başlatılmamış (gerçek SDK): yine fırlatmaz
      AppAnalytics.consentSink = original;
      await AppAnalytics.applyConsent(_granted);
    });
  });

  group('açılış ve gizlilik ayarları', () {
    // Sahte UMP + cihaz kaydı
    late int consentStatus;
    late int privacyStatus;
    late bool updateFails;
    int? gdprApplies;
    String? purposeConsents;
    // Güncelleme sonucu ve formlar kapanınca kullanıcının seçimi (null: form
    // gösterilmedi)
    void Function()? onUpdate;
    void Function()? onConsentForm;
    void Function()? onPrivacyForm;
    late List<String> log;
    final originalSink = AppAnalytics.consentSink;

    String describe(AnalyticsConsent consent) => switch (consent) {
      _granted => 'izin: hepsi',
      _denied => 'izin: hiçbiri',
      _storageOnly => 'izin: saklama',
      _ => 'izin: $consent',
    };

    setUp(() {
      consentStatus = _unknown;
      privacyStatus = 0;
      updateFails = false;
      gdprApplies = null;
      purposeConsents = null;
      onUpdate = null;
      onConsentForm = null;
      onPrivacyForm = null;
      log = [];
      AdConsent.debugReset();
      AdConsent.isSupported = () => true;
      AppAnalytics.consentSink = (consent) async => log.add(describe(consent));
      messenger.setMockMessageHandler(_umpChannel, (message) async {
        const codec = StandardMethodCodec();
        final method =
            const StandardMessageCodec().readValue(ReadBuffer(message!))
                as String;
        switch (method) {
          case 'ConsentInformation#requestConsentInfoUpdate':
            log.add('ump: güncelle');
            if (updateFails) {
              return codec.encodeErrorEnvelope(code: '2', message: 'ağ yok');
            }
            onUpdate?.call();
            return codec.encodeSuccessEnvelope(null);
          case 'UserMessagingPlatform#loadAndShowConsentFormIfRequired':
            if (onConsentForm != null) {
              log.add('ump: form');
              onConsentForm!();
            }
            return codec.encodeSuccessEnvelope(null);
          case 'UserMessagingPlatform#showPrivacyOptionsForm':
            log.add('ump: gizlilik formu');
            onPrivacyForm?.call();
            return codec.encodeSuccessEnvelope(null);
          case 'ConsentInformation#getConsentStatus':
            return codec.encodeSuccessEnvelope(consentStatus);
          case 'ConsentInformation#getPrivacyOptionsRequirementStatus':
            return codec.encodeSuccessEnvelope(privacyStatus);
          case 'ConsentInformation#canRequestAds':
            return codec.encodeSuccessEnvelope(
              consentStatus == _obtained || consentStatus == _notRequired,
            );
          default:
            return codec.encodeSuccessEnvelope(null);
        }
      });
      messenger.setMockMessageHandler(_adsChannel, (message) async {
        const codec = StandardMethodCodec();
        final call = codec.decodeMethodCall(message);
        if (call.method == 'MobileAds#initialize') log.add('reklam: başla');
        return codec.encodeSuccessEnvelope(null);
      });
      messenger.setMockMethodCallHandler(_device, (call) async {
        if (call.method != 'tcfConsent') return null;
        return {'gdprApplies': gdprApplies, 'purposeConsents': purposeConsents};
      });
    });

    tearDown(() {
      AdConsent.isSupported = () => false;
      AppAnalytics.consentSink = originalSink;
      messenger.setMockMessageHandler(_umpChannel, null);
      messenger.setMockMessageHandler(_adsChannel, null);
      messenger.setMockMethodCallHandler(_device, null);
    });

    test('AB, önceki oturumda onay vermiş: UMP sonucuna kadar izinsiz, '
        'sonra TCF\'den (reklamlardan önce)', () async {
      consentStatus = _obtained;
      privacyStatus = 1;
      gdprApplies = 1;
      purposeConsents = '1111111111';
      await AdConsent.gatherAndStartAds();
      expect(log.first, 'izin: hiçbiri');
      expect(
        log.indexOf('izin: hiçbiri'),
        lessThan(log.indexOf('ump: güncelle')),
      );
      expect(
        log.indexOf('izin: hiçbiri'),
        lessThan(log.indexOf('reklam: başla')),
      );
      expect(log.last, 'izin: hepsi');
      expect(log.where((e) => e == 'izin: hiçbiri'), hasLength(1));
    });

    test('AB, ilk açılış: form açıkken izinsiz, sonra seçime göre (amaç 1 '
        'evet, 3/4 hayır)', () async {
      // UMP önbelleği boş; güncelleme rıza gerektiğini bildirir, formdaki
      // seçim TCF kaydına yazılır
      privacyStatus = 2;
      onUpdate = () {
        consentStatus = _required;
        privacyStatus = 1;
        gdprApplies = 1;
      };
      onConsentForm = () {
        consentStatus = _obtained;
        purposeConsents = '1000000000';
      };
      await AdConsent.gatherAndStartAds();
      // Bölge bilinmeden varsayılan yazılmaz; form öncesi izinsiz, sonra seçim
      expect(log.first, 'ump: güncelle');
      expect(log.sublist(1, 3), ['izin: hiçbiri', 'ump: form']);
      expect(log.where((e) => e.startsWith('izin:')), [
        'izin: hiçbiri',
        'izin: saklama',
      ]);
      expect(log.last, 'reklam: başla');
    });

    test('AB dışı: hepsi açık, hiç izinsiz kalmaz', () async {
      consentStatus = _notRequired;
      gdprApplies = 0;
      await AdConsent.gatherAndStartAds();
      expect(log, isNot(contains('izin: hiçbiri')));
      expect(log.last, 'izin: hepsi');
    });

    test('AB dışı, UMP TCF yazmıyor: güncelleme başarılıysa açık', () async {
      consentStatus = _notRequired;
      await AdConsent.gatherAndStartAds();
      expect(log, isNot(contains('izin: hiçbiri')));
      expect(log.last, 'izin: hepsi');
    });

    test('UMP güncellenemezse: bölge bilinmiyorsa izinsiz; AB\'de son '
        'kayıt; GDPR dışı ancak kayıtta biliniyorsa açık', () async {
      updateFails = true;
      await AdConsent.gatherAndStartAds();
      expect(log.last, 'izin: hiçbiri');

      // Önceki oturumda "gerekmiyor" denmişti ama TCF'de bilgi yok
      AdConsent.debugReset();
      log.clear();
      consentStatus = _notRequired;
      await AdConsent.gatherAndStartAds();
      expect(log.last, 'izin: hiçbiri');

      AdConsent.debugReset();
      log.clear();
      gdprApplies = 0;
      await AdConsent.gatherAndStartAds();
      expect(log.last, 'izin: hepsi');

      AdConsent.debugReset();
      log.clear();
      consentStatus = _obtained;
      gdprApplies = 1;
      purposeConsents = '1000000000';
      await AdConsent.gatherAndStartAds();
      expect(log.first, 'izin: hiçbiri');
      expect(log.last, 'izin: saklama');
    });

    test('TCF okunamazsa (kanal yok) AB\'de izinsiz', () async {
      messenger.setMockMethodCallHandler(_device, null);
      consentStatus = _obtained;
      privacyStatus = 1;
      await AdConsent.gatherAndStartAds();
      expect(log, isNotEmpty);
      expect(log.where((e) => e.startsWith('izin:')).toSet(), {
        'izin: hiçbiri',
      });
    });

    test('Reklam gizlilik ayarları: seçim değişince izinler yeniden '
        'verilir', () async {
      consentStatus = _obtained;
      privacyStatus = 1;
      gdprApplies = 1;
      purposeConsents = '1111111111';
      await AdConsent.gatherAndStartAds();
      expect(log.last, 'izin: hepsi');
      expect(AdConsent.privacyOptionsRequired.value, isTrue);

      onPrivacyForm = () => purposeConsents = '0000000000';
      await AdConsent.showPrivacyOptions();
      expect(log.last, 'izin: hiçbiri');
      expect(
        log.indexOf('ump: gizlilik formu'),
        lessThan(log.lastIndexOf('izin: hiçbiri')),
      );

      onPrivacyForm = () => purposeConsents = '1011000000';
      await AdConsent.showPrivacyOptions();
      expect(log.last, 'izin: hepsi');
    });

    test('Analytics izni verilemese de açılış ve reklamlar sürer', () async {
      consentStatus = _obtained;
      privacyStatus = 1;
      gdprApplies = 1;
      purposeConsents = '1111111111';
      AppAnalytics.consentSink = (consent) async =>
          throw PlatformException(code: 'firebase');
      await AdConsent.gatherAndStartAds();
      expect(log, contains('reklam: başla'));
      expect(AdConsent.canRequestAds.value, isTrue);
    });

    test('Android dışında hiçbir şey yapılmaz', () async {
      AdConsent.isSupported = () => false;
      await AdConsent.gatherAndStartAds();
      expect(log, isEmpty);
    });
  });
}
