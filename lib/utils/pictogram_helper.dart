import 'package:flutter/material.dart';

class PictogramHelper {
  
  static final Map<String, Color> _pictogramTypeColorMap = {
    'social': const Color(0xFFFFC1CC),       // rosa pastel
    'pessoas': const Color(0xFFFFF1B6),     // amarelo pastel
    'verbos': const Color(0xFFC8E6C9),      // verde pastel
    'descritivo': const Color(0xFFBBDEFB),  // azul pastel
    'substantivos': const Color(0xFFFFD8B1),// laranja pastel
    'diversos': const Color(0xFFE0E0E0),    // cinza suave
  };
  // Mapeamento de TAGS da API para os tipos internos.
  static final Map<String, String> _tagToTypeMap = {
    'social': 'social',
    'sentimento': 'social',
    'cumprimento': 'social',
    'pessoa': 'pessoas',
    'pronome': 'pessoas',
    'família': 'pessoas',
    'verbo': 'verbos',
    'adjetivo': 'descritivo',
    'advérbio': 'descritivo',
    'cor': 'descritivo',
    'tamanho': 'descritivo',
    'comida': 'substantivos',
    'animal': 'substantivos',
    'lugar': 'substantivos',
    'brinquedo': 'substantivos',
    'objeto': 'substantivos',
    'roupa': 'substantivos',
    'corpo': 'substantivos',
    'natureza': 'substantivos',
    'substantivo': 'substantivos',
  };

  // Função que retorna a cor correta com base no tipo do pictograma.
  static Color getColorForType(String type) {
    return _pictogramTypeColorMap[type] ?? Colors.grey.shade200;
  }

  static String getTypeFromTags(List<String> tags) {
    for (var entry in _tagToTypeMap.entries) {
      if (tags.contains(entry.key)) {
        return entry.value; 
      }
    }
    return 'substantivos'; // Fallback seguro
  }
}
