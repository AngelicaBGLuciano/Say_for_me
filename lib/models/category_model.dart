import 'dart:convert';
import 'board_item.dart';

class Category implements BoardItem {
  String name;
  List<String> words;

  Category({required this.name, required this.words});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'words': words,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      name: map['name'],
      words: List<String>.from(map['words']),
    );
  }

  String toJson() => json.encode(toMap());
  factory Category.fromJson(String source) => Category.fromMap(json.decode(source));
}

