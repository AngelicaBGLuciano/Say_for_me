//import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board_config.dart';
import '../models/category_model.dart';

class PreferencesService {
  static const String _boardConfigKey = 'boardConfig';

  Future<void> saveBoardConfig(BoardConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_boardConfigKey, config.toJson());
  }

  Future<BoardConfig> getBoardConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_boardConfigKey);
    if (configJson == null) {
      return _getDefaultConfig();
    }
    return BoardConfig.fromJson(configJson);
  }

  BoardConfig _getDefaultConfig() {
    final defaultCategories = [
      Category(name: 'Alimentos', words: ['macarrão', 'bolacha', 'fruta', 'água', 'coca-cola', 'leite', 'arroz', 'pão', 'café']),
      Category(name: 'Lugares', words: ['sanitários', 'escola', 'casa', 'jardim', 'mercado']),
      Category(name: 'Objetos', words: ['tablet', 'brinquedo', 'livro', 'telefone', 'mochila', 'computador']),
      Category(name: 'Tempos', words: ['amanhã',  'hoje', 'ontem', 'agora', 'depois']),
    ];
    
    final defaultRootItems = [
      'cat:Alimentos',
      'cat:Lugares',
      'cat:Objetos',
      'cat:Tempos',

      'eu', 'meu', 'você', 'ele', 'ela', 'mulher', 'homem', 'criança',
      'querer', 'comer', 'beber', 'ir', 'jogar',
      'sentir', 'dar', 'dormir', 'gostar',
      'usar', 'ler', 'vir', 'pegar','estudar', 'necessitar',
      'rápido', 'feliz', 'cansado', 'chateado', 'medo',
      'massa', 'bolacha', 'fruta', 'água', 
      'leite', 'escola', 'casa',
      'tablet', 'brinquedo', 'livro',
      'coca-cola', 'telefone', 'arroz','bola',
      'pão', 'mochila', 'computador', 'café',
      'sanitários', 'jardim', 'mercado',
      'não', 'sim', 'por favor', 'obrigado', 'olá', 'tchau', 'bom dia', 'boa tarde', 'boa noite',
      'amanhã', 'hoje', 'ontem', 'agora', 'depois',
      'muito', 'pouco', 'grande', 'pequeno', 'bom', 'ruim'
    ];

    return BoardConfig(
      allCategories: defaultCategories,
      rootItemIdentifiers: defaultRootItems,
    );
  }
}

