import 'dart:convert';
import 'package:flutter/services.dart'; // Dosya okumak için
import '../models/hadith_model.dart';

class JsonService {
  // Esmaül Hüsna Çek
  Future<List<Map<String, dynamic>>> getEsmaulHusna() async {
    final String response = await rootBundle.loadString(
      'assets/data/esmaul_husna.json',
    );
    return List<Map<String, dynamic>>.from(json.decode(response));
  }

  // Dini Günler Çek
  Future<List<Map<String, dynamic>>> getReligiousDays() async {
    final String response = await rootBundle.loadString(
      'assets/data/religious_days.json',
    );
    return List<Map<String, dynamic>>.from(json.decode(response));
  }

  // Cuma Mesajları Çek
  Future<List<String>> getFridayMessages() async {
    final String response = await rootBundle.loadString(
      'assets/data/friday_messages.json',
    );
    return List<String>.from(json.decode(response));
  }

  // Hadisleri Çek
  Future<List<HadithModel>> getHadiths() async {
    final String response = await rootBundle.loadString(
      'assets/data/hadiths.json',
    );
    final List<dynamic> data = json.decode(response);
    return data
        .map((e) => HadithModel(content: e['content'], source: e['source']))
        .toList();
  }
}
