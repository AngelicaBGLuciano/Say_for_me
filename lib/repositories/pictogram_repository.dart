import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/board_config.dart';
import '../models/board_item.dart';
import '../models/category_model.dart';
import '../models/pictogram_model.dart';
import '../services/arasaac_service.dart';
import '../services/database_service.dart';

class PictogramRepository {
  final ArasaacService _arasaacService = ArasaacService();
  final DatabaseService _databaseService = DatabaseService();
  BoardConfig? _boardConfig;

  void updateFullConfig(BoardConfig config) {
    _boardConfig = config;
  }

  // Baixa a imagem e salva localmente (com cache)
  Future<String?> _downloadAndSaveImage(String url, int id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/pictogram_$id.png';

      // Evita baixar de novo
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao baixar imagem: $e');
    }
    return null;
  }

  // Retorna todos os pictogramas do banco
  Future<List<Pictogram>> getAllPictogramsFromDb() async {
    return await _databaseService.getAllPictograms();
  }

  // Junta categorias + pictogramas (modo edição)
  Future<List<BoardItem>> getAllBoardItems() async {
    if (_boardConfig == null) return [];

    final allPicts = await getAllPictogramsFromDb();
    final allCats = _boardConfig!.allCategories;

    return [...allCats, ...allPicts];
  }

  // Itens da tela principal
  Future<List<BoardItem>> getRootBoardItems() async {
    if (_boardConfig == null) return [];

    final allPictograms = await getAllPictogramsFromDb();

    final Map<String, Pictogram> pictogramMap = {
      for (final pictogram in allPictograms)
        pictogram.keyword.toLowerCase().trim(): pictogram,
    };

    final Map<String, Category> categoryMap = {
      for (final category in _boardConfig!.allCategories)
        category.name.toLowerCase().trim(): category,
    };

    final List<BoardItem> rootItems = [];

    for (String identifier in _boardConfig!.rootItemIdentifiers) {
      if (identifier.startsWith('cat:')) {
        final categoryName = identifier.substring(4).toLowerCase().trim();
        final category = categoryMap[categoryName];

        if (category != null) {
          rootItems.add(category);
        }
      } else {
        final keyword = identifier.toLowerCase().trim();
        final pictogram = pictogramMap[keyword];

        if (pictogram != null) {
          rootItems.add(pictogram);
        }
      }
    }

    return rootItems;
  }

  // Busca um pictograma (com cache local de imagem)
  Future<Pictogram?> getPictogram(String keyword) async {
    final searchKeyword = keyword.toLowerCase().trim();

    // 1. tenta banco
    Pictogram? pictogram =
        await _databaseService.getPictogramByKeyword(searchKeyword);

    // 2. se não tiver, busca na API
    if (pictogram == null) {
      pictogram =
          await _arasaacService.searchOnePictogram(searchKeyword);

      if (pictogram != null) {
        // baixa e salva imagem
        final localPath = await _downloadAndSaveImage(
          pictogram.imageUrl,
          pictogram.id,
        );

        pictogram = Pictogram(
          id: pictogram.id,
          keyword: pictogram.keyword,
          tags: pictogram.tags,
          type: pictogram.type,
          usageCount: pictogram.usageCount,
          localImagePath: localPath,
        );

        await _databaseService.insertPictogram(pictogram);
      }
    }

    return pictogram;
  }

  // Retorna lista de pictogramas para o board
  Future<List<Pictogram>> getPictogramsForBoard(List<String> keywords) async {
    final allPictograms = await getAllPictogramsFromDb();

    final Map<String, Pictogram> pictogramMap = {
      for (final pictogram in allPictograms)
        pictogram.keyword.toLowerCase().trim(): pictogram,
    };

    final List<Pictogram> result = [];

    for (final keyword in keywords) {
      final normalizedKeyword = keyword.toLowerCase().trim();

      final pictogram = pictogramMap[normalizedKeyword];

      if (pictogram != null) {
        result.add(pictogram);
      }
    }

    return result;
  }

  // Busca na API (sem salvar)
  Future<List<Pictogram>> searchApiForNewPictograms(
      String keyword) async {
    return await _arasaacService
        .searchAllPictograms(keyword.toLowerCase().trim());
  }

  // Salva pictograma escolhido 
  Future<void> saveChosenPictogram(Pictogram pictogram) async {
    // Se ainda não tem imagem local, baixa
    if (pictogram.localImagePath == null ||
        pictogram.localImagePath!.isEmpty) {
      final localPath = await _downloadAndSaveImage(
        pictogram.imageUrl,
        pictogram.id,
      );

      pictogram = Pictogram(
        id: pictogram.id,
        keyword: pictogram.keyword,
        tags: pictogram.tags,
        type: pictogram.type,
        usageCount: pictogram.usageCount,
        localImagePath: localPath,
      );
    }

    await _databaseService.insertPictogram(pictogram);
  }

  // Atualiza uso
  Future<void> recordPictogramUsage(Pictogram pictogram) async {
    await _databaseService
        .incrementUsageCount(pictogram.keyword);
  }

  Future<void> updatePictogram(Pictogram pictogram) async {
    await _databaseService.updatePictogram(pictogram);
  }

  Future<void> deletePictogram(String keyword) async {
    await _databaseService.deletePictogram(keyword);
  }
}