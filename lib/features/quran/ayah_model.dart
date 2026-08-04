class AyahModel {
  final int number; // Ayet numarası
  final String surahName; // Sure adı
  final int numberInSurah; // Suredeki kaçıncı ayet olduğu
  final String arabicText; // Arapça orijinal metin
  final String translatedText; // Seçilen dildeki meal

  AyahModel({
    required this.number,
    required this.surahName,
    required this.numberInSurah,
    required this.arabicText,
    required this.translatedText,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json, String langCode) {
    // API'den dönen dizide 0. eleman her zaman Arapça, 1. eleman meal olacak şekilde çekeceğiz
    final arabicData = json['data'][0];
    final translationData = json['data'][1];

    return AyahModel(
      number: arabicData['number'],
      surahName: arabicData['surah']['name'],
      numberInSurah: arabicData['numberInSurah'],
      arabicText: arabicData['text'],
      translatedText: translationData['text'],
    );
  }
}
