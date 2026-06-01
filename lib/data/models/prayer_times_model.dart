class PrayerTimesModel {
  final String? imsak;
  final String? gunes;
  final String? ogle;
  final String? ikindi;
  final String? aksam;
  final String? yatsi;

  PrayerTimesModel({
    this.imsak,
    this.gunes,
    this.ogle,
    this.ikindi,
    this.aksam,
    this.yatsi,
  });

  Map<String, dynamic> toJson() {
    return {
      'imsak': imsak,
      'gunes': gunes,
      'ogle': ogle,
      'ikindi': ikindi,
      'aksam': aksam,
      'yatsi': yatsi,
    };
  }

  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    return PrayerTimesModel(
      imsak: json['imsak'],
      gunes: json['gunes'],
      ogle: json['ogle'],
      ikindi: json['ikindi'],
      aksam: json['aksam'],
      yatsi: json['yatsi'],
    );
  }

  factory PrayerTimesModel.fromList(List<dynamic> jsonList) {
    String getTime(String vakitIsmi) {
      try {
        var item = jsonList.firstWhere(
          (element) =>
              element['vakit'].toString().toLowerCase() ==
              vakitIsmi.toLowerCase(),
          orElse: () => {'saat': '--:--'},
        );
        return item['saat'];
      } catch (e) {
        return '--:--';
      }
    }

    return PrayerTimesModel(
      imsak: getTime('İmsak'),
      gunes: getTime('Güneş'),
      ogle: getTime('Öğle'),
      ikindi: getTime('Ikindi'),
      aksam: getTime('Akşam'),
      yatsi: getTime('Yatsı'),
    );
  }
}
