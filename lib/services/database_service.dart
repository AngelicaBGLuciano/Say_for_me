import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pictogram_model.dart';
import 'arasaac_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // Mapa com os pictogramas padrão e os seus tipos corretos para o seeding inicial.
  static const Map<String, String> _defaultWordsAndTypes = {
    'eu':'pessoas', 'meu':'pessoas', 'você':'pessoas', 'ele':'pessoas', 'ela':'pessoas', 'mulher':'pessoas', 'homem':'pessoas', 'criança':'pessoas',
    'querer':'verbos', 'comer':'verbos', 'beber':'verbos', 'ir':'verbos', 'jogar':'verbos',
    'sentir':'verbos', 'dar':'verbos', 'dormir':'verbos', 'gostar':'verbos',
    'usar':'verbos', 'ler':'verbos', 'vir':'verbos', 'pegar':'verbos','estudar':'verbos', 'necessitar':'verbos',
    'rápido':'descritivo', 'feliz':'descritivo', 'cansado':'descritivo', 'chateado':'descritivo', 'medo':'descritivo',
    'massa':'substantivos', 'bolacha':'substantivos', 'fruta':'substantivos', 'água':'substantivos', 
    'leite':'substantivos', 'escola':'substantivos', 'casa':'substantivos',
    'tablet':'substantivos', 'brinquedo':'substantivos', 'livro':'substantivos',
    'coca-cola':'substantivos', 'telefone':'substantivos', 'arroz':'substantivos','bola':'substantivos',
    'pão':'substantivos', 'mochila':'substantivos', 'computador':'substantivos', 'café':'substantivos',
    'sanitários':'subtantivos', 'jardim':'substantivos', 'mercado':'substantivos',
    'não':'social', 'sim':'social', 'por favor':'social', 'obrigado':'social', 'olá':'social', 'tchau':'social', 'bom dia':'social', 'boa tarde':'social', 'boa noite':'social',
    'amanhã':'diversos', 'hoje':'diversos', 'ontem':'diversos', 'agora':'diversos', 'depois':'diversos',
    'muito':'descritivo', 'pouco':'descritivo', 'grande':'descritivo', 'pequeno':'descritivo', 'bom':'descritivo', 'ruim':'descritivo'
  };

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'say_for_me.db');


    return await openDatabase(
      path,
      version: 3, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE pictograms ADD COLUMN type TEXT NOT NULL DEFAULT \'substantivos\''
      );
    }

    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE pictograms ADD COLUMN localImagePath TEXT'
      );
    }
  }
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE pictograms (
        id INTEGER PRIMARY KEY,
        keyword TEXT NOT NULL UNIQUE,
        tags TEXT,
        type TEXT NOT NULL DEFAULT 'substantivos',
        usageCount INTEGER NOT NULL DEFAULT 0,
        localImagePath TEXT
      )
    ''');
  }
  
  // Popula o banco de dados na primeira inicialização para evitar o bug de carregamento.
  Future<void> _seedDatabase(Database db) async {
    final arasaacService = ArasaacService();
    for(var entry in _defaultWordsAndTypes.entries) {
      final keyword = entry.key;
      final type = entry.value;
      
      final pictogram = await arasaacService.searchOnePictogram(keyword);
      if (pictogram != null) {
        pictogram.type = type;
        await db.insert('pictograms', pictogram.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  // Busca todos os pictogramas para o "Modo Edição"
  Future<List<Pictogram>> getAllPictograms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pictograms');
    return List.generate(maps.length, (i) {
      return Pictogram.fromMap(maps[i]);
    });
  }

  Future<void> insertPictogram(Pictogram pictogram) async {
    final db = await database;
    await db.insert(
      'pictograms',
      pictogram.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Pictogram?> getPictogramByKeyword(String keyword) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pictograms',
      where: 'keyword = ?',
      whereArgs: [keyword.toLowerCase()],
    );

    if (maps.isNotEmpty) {
      return Pictogram.fromMap(maps.first);
    }
    return null;
  }
  
  Future<void> incrementUsageCount(String keyword) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pictograms SET usageCount = usageCount + 1 WHERE keyword = ?',
      [keyword.toLowerCase()],
    );
  }

  Future<void> updatePictogram(Pictogram pictogram) async {
    final db = await database;

    await db.update(
      'pictograms',
      pictogram.toMap(),
      where: 'id = ?',
      whereArgs: [pictogram.id],
    );
  }

  Future<void> deletePictogram(String keyword) async {
    final db = await database;

    await db.delete(
      'pictograms',
      where: 'keyword = ?',
      whereArgs: [keyword.toLowerCase().trim()],
    );
  }
}

