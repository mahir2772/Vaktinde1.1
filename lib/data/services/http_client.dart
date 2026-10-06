import 'package:http/http.dart' as http;

/// Tüm dış API istekleri için zaman aşımlı GET (ağ yavaşsa sonsuz beklemeyi önler).
Future<http.Response> httpGet(Uri url, {Map<String, String>? headers}) =>
    http.get(url, headers: headers).timeout(const Duration(seconds: 10));
