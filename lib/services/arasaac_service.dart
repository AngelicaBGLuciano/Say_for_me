import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pictogram_model.dart';

class ArasaacService {
  static const String baseUrl = 'https://api.arasaac.org/v1/pictograms/pt/search/';

  Future<List<Pictogram>> fetchPictograms(List<String> words) async {
    final futures = words.map((word) => searchOnePictogram(word)).toList();
    final results = await Future.wait(futures);
    return results.where((pictogram) => pictogram != null).cast<Pictogram>().toList();
  }

  // Busca um único pictograma (usado para o carregamento inicial da prancha)
  Future<Pictogram?> searchOnePictogram(String word) async {
    final String fullUrl = '$baseUrl${Uri.encodeComponent(word)}';
    try {
      final uri = Uri.parse(fullUrl);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          return Pictogram.fromJson(results[0]);
        }
      }
    } catch (e) {
      print('Exceção ao buscar pictograma para "$word": $e');
    }
    return null;
  }

  // Busca todos os pictogramas para um termo de pesquisa
  Future<List<Pictogram>> searchAllPictograms(String word) async {
    final String fullUrl = '$baseUrl${Uri.encodeComponent(word)}';
    try {
      final uri = Uri.parse(fullUrl);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          return results.map((json) => Pictogram.fromJson(json)).toList();
        }
      } else {
        print('Erro na API para "$word": ${response.statusCode}');
      }
    } catch (e) {
      print('Exceção ao buscar múltiplos pictogramas para "$word": $e');
    }
    return []; // Retorna uma lista vazia em caso de falha
  }
}