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

  factory PrayerTimesModel.fromJson(List<dynamic> jsonList) {
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
