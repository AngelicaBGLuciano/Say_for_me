import 'dart:convert';
import 'board_item.dart';
import '../utils/pictogram_helper.dart';

class Pictogram implements BoardItem {
  final int id;
  final String keyword;
  final List<String> tags;
  String type;
  int usageCount;

  final String? localImagePath;

  Pictogram({
    required this.id,
    required this.keyword,
    required this.tags,
    this.type = 'substantivos',
    this.usageCount = 0,
    this.localImagePath,
  });

  String get imageUrl {
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return localImagePath!;
    }
    return 'https://api.arasaac.org/v1/pictograms/$id';
  }

  factory Pictogram.fromJson(Map<String, dynamic> json) {
    var tagsFromJson = json['tags'];
    List<String> tagsList =
        tagsFromJson is List ? List<String>.from(tagsFromJson) : [];

    return Pictogram(
      id: json['_id'],
      keyword: json['keywords'][0]['keyword'],
      tags: tagsList,
      type: PictogramHelper.getTypeFromTags(tagsList),
    );
  }

  factory Pictogram.fromMap(Map<String, dynamic> map) {
    return Pictogram(
      id: map['id'],
      keyword: map['keyword'],
      tags: List<String>.from(jsonDecode(map['tags'])),
      type: map['type'] ?? 'substantivos',
      usageCount: map['usageCount'],
      localImagePath: map['localImagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keyword': keyword,
      'tags': jsonEncode(tags),
      'type': type,
      'usageCount': usageCount,
      'localImagePath': localImagePath,
    };
  }
}