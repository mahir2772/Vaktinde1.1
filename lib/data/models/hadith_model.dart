class HadithModel {
  final String? content; // Hadisin metni
  final String? source; // Kaynak (Buhari vb.)

  HadithModel({this.content, this.source});

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    return HadithModel(
      content:
          json['hadeeth'] ??
          json['text'] ??
          json['content'] ??
          "Hadis metni bulunamadı.",
      source: json['attribution'] ?? json['source'] ?? "Kaynak Bilinmiyor",
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content, 'source': source};
  }
}
