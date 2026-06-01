import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';

class ZikirViewModel extends ChangeNotifier {
  String _selectedDhikr = "Sübhanallah";
  int _count = 0;
  int _target = 33;

  bool _isVibrationEnabled = true;
  bool _isSoundEnabled = false;
  bool _isKeepAwakeEnabled = false;
  int _viewMode = 0;

  // İSTATİSTİKLER İÇİN: Tarih (YYYY-MM-DD) -> O gün çekilen toplam zikir sayısı
  Map<String, int> _dailyStats = {};

  // ÖZEL ZİKİRLER LİSTESİ (Max 20)
  List<String> _customDhikrs = [];

  String get selectedDhikr => _selectedDhikr;
  int get count => _count;
  int get target => _target;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isKeepAwakeEnabled => _isKeepAwakeEnabled;
  int get viewMode => _viewMode;
  Map<String, int> get dailyStats => _dailyStats;
  List<String> get customDhikrs => _customDhikrs;

  // HAZIR ZİKİRLER VE ARAPÇALARI
  final List<Map<String, String>> predefinedDhikrsList = [
    {"id": "Sübhanallah", "ar": "سُبْحَانَ ٱللَّٰهِ"},
    {"id": "Elhamdülillah", "ar": "ٱلْحَمْدُ لِلَّٰهِ"},
    {"id": "Allahu Ekber", "ar": "ٱللَّٰهُ أَكْبَرُ"},
    {"id": "Kelime-i Tevhid", "ar": "لَا إِلَٰهَ إِلَّا ٱللَّٰهُ"},
    {"id": "Salavat", "ar": "ٱللَّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ"},
    {"id": "Estağfirullah", "ar": "أَسْتَغْفِرُ ٱللَّٰهَ"},
    {"id": "La Havle", "ar": "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّٰهِ"},
    {"id": "Hasbünallah", "ar": "حَسْبُنَا ٱللَّٰهُ وَنِعْمَ ٱلْوَكِيلُ"},
    {"id": "Subhanallahi", "ar": "سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ"},
    {
      "id": "Hz. Yunus",
      "ar":
          "لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ",
    },
  ];

  // 99 İSİM (ESMAÜL HÜSNA) KÜTÜPHANESİ - ÇOKLU DİL DESTEKLİ
  final List<Map<String, String>> esmaulHusnaList = [
    {
      "id": "Ya Allah",
      "ar": "يَا ٱللَّٰهُ",
      "tr": "Eşi benzeri olmayan, tek ilah.",
      "en": "The One and Only God.",
      "fr": "L'Unique, Le Seul Dieu.",
    },
    {
      "id": "Ya Rahman",
      "ar": "يَا رَحْمَٰنُ",
      "tr": "Dünyada tüm mahlukata merhamet eden.",
      "en": "The Most Gracious.",
      "fr": "Le Tout-Miséricordieux.",
    },
    {
      "id": "Ya Rahim",
      "ar": "يَا رَحِيمُ",
      "tr": "Ahirette sadece müminlere merhamet eden.",
      "en": "The Most Merciful.",
      "fr": "Le Très-Miséricordieux.",
    },
    {
      "id": "Ya Melik",
      "ar": "يَا مَلِكُ",
      "tr": "Mülkün, kainatın gerçek sahibi.",
      "en": "The Absolute Ruler.",
      "fr": "Le Souverain Absolu.",
    },
    {
      "id": "Ya Kuddüs",
      "ar": "يَا قُدُّوسُ",
      "tr": "Her türlü eksiklikten münezzeh olan.",
      "en": "The Pure One.",
      "fr": "Le Pur, Le Saint.",
    },
    {
      "id": "Ya Selam",
      "ar": "يَا سَلَامُ",
      "tr": "Tehlikelerden selamete çıkaran.",
      "en": "The Source of Peace.",
      "fr": "La Source de Paix.",
    },
    {
      "id": "Ya Mü'min",
      "ar": "يَا مُؤْمِنُ",
      "tr": "Güven veren, emin kılan.",
      "en": "The Inspirer of Faith.",
      "fr": "Celui qui donne la foi.",
    },
    {
      "id": "Ya Müheymin",
      "ar": "يَا مُهَيْمِنُ",
      "tr": "Kainatın bütün işlerini gözeten.",
      "en": "The Guardian.",
      "fr": "Le Gardien, Le Protecteur.",
    },
    {
      "id": "Ya Aziz",
      "ar": "يَا عَزِيزُ",
      "tr": "Mağlup edilmesi imkansız olan.",
      "en": "The Victorious.",
      "fr": "Le Tout-Puissant.",
    },
    {
      "id": "Ya Cabbar",
      "ar": "يَا جَبَّارُ",
      "tr": "Dilediğini zorla yaptırmaya muktedir olan.",
      "en": "The Compeller.",
      "fr": "Le Contraignant.",
    },
    {
      "id": "Ya Mütekebbir",
      "ar": "يَا مُتَكَبِّرُ",
      "tr": "Büyüklükte eşi olmayan.",
      "en": "The Greatest.",
      "fr": "Le Superbe.",
    },
    {
      "id": "Ya Halik",
      "ar": "يَا خَالِقُ",
      "tr": "Yaratan, yoktan var eden.",
      "en": "The Creator.",
      "fr": "Le Créateur.",
    },
    {
      "id": "Ya Bari",
      "ar": "يَا بَارِئُ",
      "tr": "Kusursuz ve noksansız yaratan.",
      "en": "The Maker of Order.",
      "fr": "Le Producteur.",
    },
    {
      "id": "Ya Musavvir",
      "ar": "يَا مُصَوِّرُ",
      "tr": "Varlıklara şekil veren.",
      "en": "The Shaper of Beauty.",
      "fr": "Le Formateur.",
    },
    {
      "id": "Ya Gaffar",
      "ar": "يَا غَفَّارُ",
      "tr": "Günahları çokça bağışlayan.",
      "en": "The Forgiving.",
      "fr": "Le Grand Pardonneur.",
    },
    {
      "id": "Ya Kahhar",
      "ar": "يَا قَهَّارُ",
      "tr": "Her şeye galip gelen.",
      "en": "The Subduer.",
      "fr": "Le Dominateur Suprême.",
    },
    {
      "id": "Ya Vehhab",
      "ar": "يَا وَهَّابُ",
      "tr": "Karşılıksız nimetler veren.",
      "en": "The Giver of All.",
      "fr": "Le Donateur Universel.",
    },
    {
      "id": "Ya Rezzak",
      "ar": "يَا رَزَّاقُ",
      "tr": "Rızkı veren ve ihtiyacı karşılayan.",
      "en": "The Provider.",
      "fr": "Le Pourvoyeur.",
    },
    {
      "id": "Ya Fettah",
      "ar": "يَا فَتَّاحُ",
      "tr": "Her türlü sıkıntıyı açan ve gideren.",
      "en": "The Opener.",
      "fr": "L'Ouvreur.",
    },
    {
      "id": "Ya Alim",
      "ar": "يَا عَلِيمُ",
      "tr": "Her şeyi en ince detayına kadar bilen.",
      "en": "The Knower of All.",
      "fr": "L'Omniscient.",
    },
    {
      "id": "Ya Kabıd",
      "ar": "يَا قَابِضُ",
      "tr": "Dilediğine rızkı daraltan.",
      "en": "The Constrictor.",
      "fr": "Celui qui retient.",
    },
    {
      "id": "Ya Basıt",
      "ar": "يَا بَاسِطُ",
      "tr": "Dilediğine rızkı genişleten.",
      "en": "The Reliever.",
      "fr": "Celui qui étend.",
    },
    {
      "id": "Ya Hafıd",
      "ar": "يَا خَافِضُ",
      "tr": "Kafirleri ve zalimleri alçaltan.",
      "en": "The Abaser.",
      "fr": "Celui qui abaisse.",
    },
    {
      "id": "Ya Rafi",
      "ar": "يَا رَافِعُ",
      "tr": "Müminleri yücelten.",
      "en": "The Exalter.",
      "fr": "Celui qui élève.",
    },
    {
      "id": "Ya Muiz",
      "ar": "يَا مُعِزُّ",
      "tr": "Dilediğini aziz eden.",
      "en": "The Bestower of Honors.",
      "fr": "Celui qui donne la puissance.",
    },
    {
      "id": "Ya Müzil",
      "ar": "يَا مُذِلُّ",
      "tr": "Dilediğini zelil eden.",
      "en": "The Dishonorer.",
      "fr": "Celui qui avilit.",
    },
    {
      "id": "Ya Semi",
      "ar": "يَا سَمِيعُ",
      "tr": "Her şeyi en iyi işiten.",
      "en": "The All-Hearing.",
      "fr": "L'Audient.",
    },
    {
      "id": "Ya Basir",
      "ar": "يَا بَصِيرُ",
      "tr": "Her şeyi en iyi gören.",
      "en": "The All-Seeing.",
      "fr": "Le Clairvoyant.",
    },
    {
      "id": "Ya Hakem",
      "ar": "يَا حَكَمُ",
      "tr": "Mutlak hakim, hakkı batıldan ayıran.",
      "en": "The Judge.",
      "fr": "Le Juge.",
    },
    {
      "id": "Ya Adl",
      "ar": "يَا عَدْلُ",
      "tr": "Mutlak adalet sahibi olan.",
      "en": "The Just.",
      "fr": "Le Juste.",
    },
    {
      "id": "Ya Latif",
      "ar": "يَا لَطِيفُ",
      "tr": "Lütuf ve ihsan sahibi olan.",
      "en": "The Subtle One.",
      "fr": "Le Doux, Le Subtil.",
    },
    {
      "id": "Ya Habir",
      "ar": "يَا خَبِيرُ",
      "tr": "Her şeyden haberdar olan.",
      "en": "The All-Aware.",
      "fr": "Le Bien-Informé.",
    },
    {
      "id": "Ya Halim",
      "ar": "يَا حَلِيمُ",
      "tr": "Cezalandırmakta acele etmeyen.",
      "en": "The Forbearing.",
      "fr": "Le Longanime.",
    },
    {
      "id": "Ya Azim",
      "ar": "يَا عَظِيمُ",
      "tr": "Büyüklüğü akıllara sığmayan.",
      "en": "The Magnificent.",
      "fr": "L'Immense.",
    },
    {
      "id": "Ya Gafur",
      "ar": "يَا غَفُورُ",
      "tr": "Affı ve bağışlaması bol olan.",
      "en": "The Forgiver and Hider of Faults.",
      "fr": "Le Tout-Pardonneur.",
    },
    {
      "id": "Ya Şekur",
      "ar": "يَا شَكُورُ",
      "tr": "Az amele çok sevap veren.",
      "en": "The Rewarder of Thankfulness.",
      "fr": "Le Très-Reconnaissant.",
    },
    {
      "id": "Ya Aliy",
      "ar": "يَا عَلِيُّ",
      "tr": "Yücelikte sonsuz olan.",
      "en": "The Highest.",
      "fr": "Le Sublime.",
    },
    {
      "id": "Ya Kebir",
      "ar": "يَا كَبِيرُ",
      "tr": "Büyüklükte eşi olmayan.",
      "en": "The Greatest.",
      "fr": "Le Grand.",
    },
    {
      "id": "Ya Hafız",
      "ar": "يَا حَفِيظُ",
      "tr": "Her şeyi koruyan ve gözeten.",
      "en": "The Preserver.",
      "fr": "Le Gardien.",
    },
    {
      "id": "Ya Mukit",
      "ar": "يَا مُقِيتُ",
      "tr": "Rızıkları yaratan ve veren.",
      "en": "The Nourisher.",
      "fr": "Le Nourricier.",
    },
    {
      "id": "Ya Hasib",
      "ar": "يَا حَسِيبُ",
      "tr": "Hesaba çeken.",
      "en": "The Accounter.",
      "fr": "Celui qui tient compte de tout.",
    },
    {
      "id": "Ya Celil",
      "ar": "يَا جَلِيلُ",
      "tr": "Ululuk ve celal sahibi.",
      "en": "The Mighty.",
      "fr": "Le Majestueux.",
    },
    {
      "id": "Ya Kerim",
      "ar": "يَا كَرِيمُ",
      "tr": "Keremi ve ikramı bol olan.",
      "en": "The Generous.",
      "fr": "Le Généreux.",
    },
    {
      "id": "Ya Rakib",
      "ar": "يَا رَقِيبُ",
      "tr": "Her varlığı gözetleyen.",
      "en": "The Watchful One.",
      "fr": "L'Observateur.",
    },
    {
      "id": "Ya Mücib",
      "ar": "يَا مُجِيبُ",
      "tr": "Dualara icabet eden.",
      "en": "The Responder to Prayer.",
      "fr": "Celui qui exauce.",
    },
    {
      "id": "Ya Vasi",
      "ar": "يَا وَاسِعُ",
      "tr": "Rahmeti her şeyi kuşatan.",
      "en": "The All-Comprehending.",
      "fr": "Le Vaste.",
    },
    {
      "id": "Ya Hakim",
      "ar": "يَا حَكِيمُ",
      "tr": "Her işi hikmetli olan.",
      "en": "The Perfectly Wise.",
      "fr": "Le Sage.",
    },
    {
      "id": "Ya Vedud",
      "ar": "يَا وَدُودُ",
      "tr": "Kullarını çok seven.",
      "en": "The Loving One.",
      "fr": "Le Tout-Aimant.",
    },
    {
      "id": "Ya Mecid",
      "ar": "يَا مَجِيدُ",
      "tr": "Şanı ve şerefi çok yüce olan.",
      "en": "The Majestic One.",
      "fr": "Le Très Glorieux.",
    },
    {
      "id": "Ya Bais",
      "ar": "يَا بَاعِثُ",
      "tr": "Ölüleri dirilten.",
      "en": "The Resurrecter.",
      "fr": "Celui qui ressuscite.",
    },
    {
      "id": "Ya Şehid",
      "ar": "يَا شَهِيدُ",
      "tr": "Her şeye şahit olan.",
      "en": "The Witness.",
      "fr": "Le Témoin.",
    },
    {
      "id": "Ya Hak",
      "ar": "يَا حَقُّ",
      "tr": "Varlığı hiç değişmeyen.",
      "en": "The Truth.",
      "fr": "Le Vrai.",
    },
    {
      "id": "Ya Vekil",
      "ar": "يَا وَكِيلُ",
      "tr": "İşlerini kendisine bırakanların vekili.",
      "en": "The Trustee.",
      "fr": "Le Gérant.",
    },
    {
      "id": "Ya Kavi",
      "ar": "يَا قَوِيُّ",
      "tr": "Kudreti sonsuz olan.",
      "en": "The Possessor of All Strength.",
      "fr": "Le Fort.",
    },
    {
      "id": "Ya Metin",
      "ar": "يَا مَتِينُ",
      "tr": "Çok güçlü ve sağlam olan.",
      "en": "The Forceful One.",
      "fr": "Le Robuste.",
    },
    {
      "id": "Ya Veli",
      "ar": "يَا وَلِيُّ",
      "tr": "Müminlerin dostu olan.",
      "en": "The Protecting Friend.",
      "fr": "Le Protecteur.",
    },
    {
      "id": "Ya Hamid",
      "ar": "يَا حَمِيدُ",
      "tr": "Övgüye en çok layık olan.",
      "en": "The Praised One.",
      "fr": "Le Digne de louanges.",
    },
    {
      "id": "Ya Muhsi",
      "ar": "يَا مُحْصِي",
      "tr": "Yarattıklarının sayısını bilen.",
      "en": "The Appraiser.",
      "fr": "Celui qui compte tout.",
    },
    {
      "id": "Ya Mübdi",
      "ar": "يَا مُبْدِئُ",
      "tr": "Mahlukatı maddesiz yaratan.",
      "en": "The Originator.",
      "fr": "Le Producteur.",
    },
    {
      "id": "Ya Muid",
      "ar": "يَا مُعِيدُ",
      "tr": "Yaratılmışları yok edip tekrar dirilten.",
      "en": "The Restorer.",
      "fr": "Celui qui redonne la vie.",
    },
    {
      "id": "Ya Muhyi",
      "ar": "يَا مُحْيِي",
      "tr": "İhya eden, dirilten.",
      "en": "The Giver of Life.",
      "fr": "Celui qui fait vivre.",
    },
    {
      "id": "Ya Mümit",
      "ar": "يَا مُمِيتُ",
      "tr": "Canlılara ölümü tattıran.",
      "en": "The Taker of Life.",
      "fr": "Celui qui fait mourir.",
    },
    {
      "id": "Ya Hayy",
      "ar": "يَا حَيُّ",
      "tr": "Sonsuz hayat sahibi olan.",
      "en": "The Ever Living One.",
      "fr": "Le Vivant.",
    },
    {
      "id": "Ya Kayyum",
      "ar": "يَا قَيُّومُ",
      "tr": "Varlıkları ayakta tutan.",
      "en": "The Self-Existing One.",
      "fr": "L'Immuable.",
    },
    {
      "id": "Ya Vacid",
      "ar": "يَا وَاجِدُ",
      "tr": "İstediğini, istediği an bulan.",
      "en": "The Finder.",
      "fr": "L'Opulent.",
    },
    {
      "id": "Ya Macid",
      "ar": "يَا مَاجِدُ",
      "tr": "Kadri ve şanı büyük olan.",
      "en": "The Glorious.",
      "fr": "Le Noble.",
    },
    {
      "id": "Ya Vahid",
      "ar": "يَا وَاحِدُ",
      "tr": "Tek olan.",
      "en": "The Unique.",
      "fr": "L'Unique.",
    },
    {
      "id": "Ya Samed",
      "ar": "يَا صَمَدُ",
      "tr": "Hiçbir şeye ihtiyacı olmayan.",
      "en": "The Eternal.",
      "fr": "Le Maître absolu.",
    },
    {
      "id": "Ya Kadir",
      "ar": "يَا قَادِرُ",
      "tr": "Dilediğini yapmaya gücü yeten.",
      "en": "The All-Powerful.",
      "fr": "Le Puissant.",
    },
    {
      "id": "Ya Muktedir",
      "ar": "يَا مُقْتَدِرُ",
      "tr": "Kuvvet ve kudret sahipleri üzerinde tasarruf eden.",
      "en": "The Creator of All Power.",
      "fr": "Le Déterminant.",
    },
    {
      "id": "Ya Mukaddim",
      "ar": "يَا مُقَدِّمُ",
      "tr": "Dilediğini öne alan.",
      "en": "The Expediter.",
      "fr": "Celui qui met en avant.",
    },
    {
      "id": "Ya Muahhir",
      "ar": "يَا مُؤَخِّرُ",
      "tr": "Dilediğini sona bırakan.",
      "en": "The Delayer.",
      "fr": "Celui qui met en arrière.",
    },
    {
      "id": "Ya Evvel",
      "ar": "يَا أَوَّلُ",
      "tr": "İlki ve başlangıcı olmayan.",
      "en": "The First.",
      "fr": "Le Premier.",
    },
    {
      "id": "Ya Ahir",
      "ar": "يَا آخِرُ",
      "tr": "Sonu olmayan.",
      "en": "The Last.",
      "fr": "Le Dernier.",
    },
    {
      "id": "Ya Zahir",
      "ar": "يَا ظَاهِرُ",
      "tr": "Varlığı aşikar olan.",
      "en": "The Manifest One.",
      "fr": "L'Apparent.",
    },
    {
      "id": "Ya Batın",
      "ar": "يَا بَاطِنُ",
      "tr": "Mahiyeti gizli olan.",
      "en": "The Hidden One.",
      "fr": "Le Caché.",
    },
    {
      "id": "Ya Vali",
      "ar": "يَا وَالِي",
      "tr": "Kainatı idare eden.",
      "en": "The Protecting Friend.",
      "fr": "Le Monarque.",
    },
    {
      "id": "Ya Müteali",
      "ar": "يَا مُتَعَالِي",
      "tr": "Noksanlıklardan yüce olan.",
      "en": "The Supreme One.",
      "fr": "Le Sublime.",
    },
    {
      "id": "Ya Berr",
      "ar": "يَا بَرُّ",
      "tr": "İyilik ve ihsanı bol olan.",
      "en": "The Doer of Good.",
      "fr": "Le Bienveillant.",
    },
    {
      "id": "Ya Tevvab",
      "ar": "يَا تَوَّابُ",
      "tr": "Tövbeleri kabul eden.",
      "en": "The Guide to Repentance.",
      "fr": "L'Accueillant au repentir.",
    },
    {
      "id": "Ya Müntakim",
      "ar": "يَا مُنْتَقِمُ",
      "tr": "Zalimlere cezasını veren.",
      "en": "The Avenger.",
      "fr": "Le Vengeur.",
    },
    {
      "id": "Ya Afüv",
      "ar": "يَا عَفُوُّ",
      "tr": "Affı bol olan.",
      "en": "The Forgiver.",
      "fr": "L'Indulgent.",
    },
    {
      "id": "Ya Rauf",
      "ar": "يَا رَءُوفُ",
      "tr": "Çok merhametli ve şefkatli.",
      "en": "The Clement.",
      "fr": "Le Bienveillant.",
    },
    {
      "id": "Ya Malik-ül Mülk",
      "ar": "يَا مَالِكَ ٱلْمُلْكِ",
      "tr": "Mülkün ebedi sahibi.",
      "en": "The Owner of All.",
      "fr": "Le Maître du Pouvoir.",
    },
    {
      "id": "Ya Zül-Celali vel-İkram",
      "ar": "يَا ذُو ٱلْجَلَالِ وَٱلْإِكْرَامِ",
      "tr": "Büyüklük ve ikram sahibi.",
      "en": "The Lord of Majesty and Bounty.",
      "fr": "Le Plein de Majesté.",
    },
    {
      "id": "Ya Muksit",
      "ar": "يَا مُقْسِطُ",
      "tr": "Adaletle hükmeden.",
      "en": "The Equitable One.",
      "fr": "L'Équitable.",
    },
    {
      "id": "Ya Cami",
      "ar": "يَا جَامِعُ",
      "tr": "Mahlukatı bir araya toplayan.",
      "en": "The Gatherer.",
      "fr": "Le Rassembleur.",
    },
    {
      "id": "Ya Gani",
      "ar": "يَا غَنِيُّ",
      "tr": "Zengin olan ve ihtiyacı olmayan.",
      "en": "The Rich One.",
      "fr": "Le Riche.",
    },
    {
      "id": "Ya Muğni",
      "ar": "يَا مُغْنِي",
      "tr": "Dilediğini zengin eden.",
      "en": "The Enricher.",
      "fr": "Celui qui enrichit.",
    },
    {
      "id": "Ya Mani",
      "ar": "يَا مَانِعُ",
      "tr": "Dilemediği şeye engel olan.",
      "en": "The Preventer of Harm.",
      "fr": "Le Défenseur.",
    },
    {
      "id": "Ya Darr",
      "ar": "يَا ضَارُّ",
      "tr": "Elem ve zarar veren şeyleri yaratan.",
      "en": "The Creator of The Harmful.",
      "fr": "Celui qui contrarie.",
    },
    {
      "id": "Ya Nafi",
      "ar": "يَا نَافِعُ",
      "tr": "Fayda veren şeyleri yaratan.",
      "en": "The Creator of Good.",
      "fr": "L'Utile.",
    },
    {
      "id": "Ya Nur",
      "ar": "يَا نُورُ",
      "tr": "Alemleri nurlandıran.",
      "en": "The Light.",
      "fr": "La Lumière.",
    },
    {
      "id": "Ya Hadi",
      "ar": "يَا هَادِي",
      "tr": "Hidayet veren.",
      "en": "The Guide.",
      "fr": "Le Guide.",
    },
    {
      "id": "Ya Bedi",
      "ar": "يَا بَدِيعُ",
      "tr": "Örneksiz ve misalsiz yaratan.",
      "en": "The Originator.",
      "fr": "L'Incomparable.",
    },
    {
      "id": "Ya Baki",
      "ar": "يَا بَاقِي",
      "tr": "Varlığının sonu olmayan.",
      "en": "The Everlasting One.",
      "fr": "L'Éternel.",
    },
    {
      "id": "Ya Varis",
      "ar": "يَا وَارِثُ",
      "tr": "Her şeyin asıl sahibi.",
      "en": "The Inheritor of All.",
      "fr": "L'Héritier.",
    },
    {
      "id": "Ya Reşid",
      "ar": "يَا رَشِيدُ",
      "tr": "Doğru yola ileten.",
      "en": "The Righteous Teacher.",
      "fr": "Celui qui agit avec droiture.",
    },
    {
      "id": "Ya Sabur",
      "ar": "يَا صَبُورُ",
      "tr": "Cezalandırmada acele etmeyen.",
      "en": "The Patient One.",
      "fr": "Le Patient.",
    },
  ];

  // ARAPÇAYI BULAN FONKSİYON (GÜNCELLENDİ: Hem Temel hem Esma'da arar)
  String getArabicForDhikr(String dhikrName) {
    var found = predefinedDhikrsList.firstWhere(
      (element) => element["id"] == dhikrName,
      orElse: () => {"ar": ""},
    );
    if (found["ar"] == "") {
      found = esmaulHusnaList.firstWhere(
        (element) => element["id"] == dhikrName,
        orElse: () => {"ar": ""},
      );
    }
    return found["ar"] ?? "";
  }

  final List<int> targetOptions = [33, 99, 100, 1000];
  final AudioPlayer _audioPlayer = AudioPlayer();

  ZikirViewModel() {
    _loadData();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  // --- HAFIZA İŞLEMLERİ ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _selectedDhikr = prefs.getString('selected_dhikr') ?? "Sübhanallah";
    _count = prefs.getInt('dhikr_count_$_selectedDhikr') ?? 0;
    _target = prefs.getInt('dhikr_target_$_selectedDhikr') ?? 33;

    _isVibrationEnabled = prefs.getBool('zikir_vibration') ?? true;
    _isSoundEnabled = prefs.getBool('zikir_sound') ?? false;
    _isKeepAwakeEnabled = prefs.getBool('zikir_awake') ?? false;
    _viewMode = prefs.getInt('zikir_view_mode') ?? 0;

    _customDhikrs = prefs.getStringList('custom_dhikrs_list') ?? [];

    // İstatistikleri Yükle (JSON formatında saklıyoruz)
    String? statsJson = prefs.getString('dhikr_daily_stats');
    if (statsJson != null) {
      _dailyStats = Map<String, int>.from(jsonDecode(statsJson));
    }

    _applyWakeLock();
    notifyListeners();
  }

  Future<void> _saveCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dhikr_count_$_selectedDhikr', _count);
  }

  // GÜNLÜK İSTATİSTİK KAYDEDİCİ
  Future<void> _recordDailyStat() async {
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // YYYY-MM-DD

    _dailyStats[today] = (_dailyStats[today] ?? 0) + 1;
    await prefs.setString('dhikr_daily_stats', jsonEncode(_dailyStats));
  }

  // --- ÖZEL ZİKİR YÖNETİMİ ---
  Future<bool> addCustomDhikr(String dhikrName) async {
    if (_customDhikrs.length >= 20) return false; // Sınır kontrolü
    if (_customDhikrs.contains(dhikrName)) return false;

    _customDhikrs.add(dhikrName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_dhikrs_list', _customDhikrs);
    notifyListeners();
    return true;
  }

  Future<void> removeCustomDhikr(String dhikrName) async {
    _customDhikrs.remove(dhikrName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_dhikrs_list', _customDhikrs);

    // Eğer silinen zikir seçili olan zikirse, başa dön
    if (_selectedDhikr == dhikrName) {
      changeDhikr("Sübhanallah");
    }
    notifyListeners();
  }

  // --- SAYICI İŞLEMLERİ ---
  Future<void> increment() async {
    _count++;
    await _saveCount();
    await _recordDailyStat(); // Her tıklamada grafiğe +1 ekle

    if (_count > 0 && _count % _target == 0) {
      if (_isVibrationEnabled) {
        HapticFeedback.vibrate();
        Future.delayed(
          const Duration(milliseconds: 150),
          () => HapticFeedback.vibrate(),
        );
      }
      if (_isSoundEnabled) {
        _audioPlayer.play(AssetSource('sounds/click.mp3'));
      }
    } else {
      if (_isVibrationEnabled) HapticFeedback.vibrate();
      if (_isSoundEnabled) {
        _audioPlayer.play(AssetSource('sounds/click.mp3'));
      }
    }
    notifyListeners();
  }

  Future<void> reset() async {
    _count = 0;
    await _saveCount();
    if (_isVibrationEnabled) {
      HapticFeedback.vibrate();
      Future.delayed(
        const Duration(milliseconds: 100),
        () => HapticFeedback.vibrate(),
      );
    }

    notifyListeners();
  }

  Future<void> changeDhikr(String newDhikr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_dhikr', newDhikr);

    _selectedDhikr = newDhikr;
    _count = prefs.getInt('dhikr_count_$_selectedDhikr') ?? 0;
    _target = prefs.getInt('dhikr_target_$_selectedDhikr') ?? 33;

    if (_isVibrationEnabled) HapticFeedback.selectionClick();
    notifyListeners();
  }

  Future<void> setTarget(int newTarget) async {
    final prefs = await SharedPreferences.getInstance();
    _target = newTarget;
    await prefs.setInt('dhikr_target_$_selectedDhikr', _target);

    if (_isVibrationEnabled) HapticFeedback.selectionClick();
    notifyListeners();
  }

  // --- AYARLAR ---
  Future<void> toggleVibration(bool value) async {
    _isVibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('zikir_vibration', value);
    notifyListeners();
  }

  Future<void> toggleSound(bool value) async {
    _isSoundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('zikir_sound', value);
    notifyListeners();
  }

  Future<void> toggleKeepAwake(bool value) async {
    _isKeepAwakeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('zikir_awake', value);
    _applyWakeLock();
    notifyListeners();
  }

  Future<void> setViewMode(int mode) async {
    _viewMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikir_view_mode', mode);
    notifyListeners();
  }

  void _applyWakeLock() {
    if (_isKeepAwakeEnabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> setCount(int newCount) async {
    _count = newCount;
    await _saveCount();
    notifyListeners();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _audioPlayer.dispose();
    super.dispose();
  }
}
