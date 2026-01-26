import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hadith_model.dart';

class JsonService {
  Future<List<Map<String, dynamic>>> getEsmaulHusna(String languageCode) async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/esmaul_husna_$languageCode.json',
      );
      return List<Map<String, dynamic>>.from(json.decode(response));
    } catch (e) {
      final String response = await rootBundle.loadString(
        'assets/data/esmaul_husna_tr.json',
      );
      return List<Map<String, dynamic>>.from(json.decode(response));
    }
  }

  Future<List<Map<String, dynamic>>> getReligiousDays() async {
    final String response = await rootBundle.loadString(
      'assets/data/religious_days.json',
    );
    return List<Map<String, dynamic>>.from(json.decode(response));
  }

  Future<List<String>> getFridayMessages(String languageCode) async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/friday_messages_$languageCode.json',
      );
      return List<String>.from(json.decode(response));
    } catch (e) {
      final String response = await rootBundle.loadString(
        'assets/data/friday_messages_tr.json',
      );
      return List<String>.from(json.decode(response));
    }
  }

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
