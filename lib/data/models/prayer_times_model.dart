class PrayerTimesModel {
  final String? imsak;
  final String? gunes;
  final String? ogle;
  final String? ikindi;
  final String? aksam;
  final String? yatsi;

  /// Vakitlerin hesaplandığı IANA saat dilimi (örn. 'Europe/Istanbul').
  /// null ise cihazın yerel saat dilimi kabul edilir.
  final String? timeZone;

  PrayerTimesModel({
    this.imsak,
    this.gunes,
    this.ogle,
    this.ikindi,
    this.aksam,
    this.yatsi,
    this.timeZone,
  });

  Map<String, dynamic> toJson() {
    return {
      'imsak': imsak,
      'gunes': gunes,
      'ogle': ogle,
      'ikindi': ikindi,
      'aksam': aksam,
      'yatsi': yatsi,
      if (timeZone != null) 'timeZone': timeZone,
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
      timeZone: json['timeZone'] as String?,
    );
  }
}
