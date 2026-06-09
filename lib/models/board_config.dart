import 'dart:convert';
import 'category_model.dart';

// Modelo para armazenar toda a configuração da prancha
class BoardConfig {
  List<Category> allCategories;
  List<String> rootItemIdentifiers; // Guarda nomes de categorias ou keywords de pictogramas

  BoardConfig({
    required this.allCategories,
    required this.rootItemIdentifiers,
  });

  Map<String, dynamic> toMap() {
    return {
      'allCategories': allCategories.map((c) => c.toMap()).toList(),
      'rootItemIdentifiers': rootItemIdentifiers,
    };
  }

  factory BoardConfig.fromMap(Map<String, dynamic> map) {
    return BoardConfig(
      allCategories: List<Category>.from(map['allCategories']?.map((x) => Category.fromMap(x))),
      rootItemIdentifiers: List<String>.from(map['rootItemIdentifiers']),
    );
  }

  String toJson() => json.encode(toMap());

  factory BoardConfig.fromJson(String source) => BoardConfig.fromMap(json.decode(source));
}