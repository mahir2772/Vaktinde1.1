class HadithModel {
  final String?
  content; // Hadisin metni (yoksa null; arayüz çevirili mesaj gösterir)
  final String? source; // Kaynak (Buhari vb.)

  HadithModel({this.content, this.source});

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    String? text(Object? value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return HadithModel(
      content:
          text(json['hadeeth']) ?? text(json['text']) ?? text(json['content']),
      source: text(json['attribution']) ?? text(json['source']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content, 'source': source};
  }
}
