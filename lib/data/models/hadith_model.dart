class HadithModel {
  final String? content; // Hadisin metni
  final String? source; // Kaynak (Örn: Tirmizi)

  HadithModel({this.content, this.source});

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    return HadithModel(
      // API "hadith" ve "source" olarak veri dönüyor
      content: json['hadith'] ?? "Hadis metni bulunamadı.",
      source: json['source'] ?? "Kaynak Bilinmiyor",
    );
  }
}
