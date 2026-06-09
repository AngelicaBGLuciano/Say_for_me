import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class TestLoggerService {
  static final TestLoggerService _instance = TestLoggerService._internal();
  factory TestLoggerService() => _instance;
  TestLoggerService._internal();

  int phraseId = 1;
  int taps = 0;
  int scrolls = 0;
  int firstSuggestionHits = 0;
  int foldersOpened = 0;

  void countTap() {
    taps++;
  }

  void countScroll() {
    scrolls++;
  }

  void countFirstSuggestionHit() {
    firstSuggestionHits++;
  }

  void countFolderOpened() {
    foldersOpened++;
  }

  void resetInteractions() {
    taps = 0;
    scrolls = 0;
    foldersOpened = 0;
    firstSuggestionHits = 0;
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> savePhraseLog({
    required String phrase,
    required String suggestionMode,
  }) async {
    final file = await _getCsvFile();

    if (!await file.exists()) {
      await file.writeAsString(
        'id_frase,modo_ia,frase,toques,scrolls,pastas_abertas,total,acertos_primeira_sugestao\n',
      );
    }

    final line = [
      phraseId.toString(),
      suggestionMode,
      _escapeCsv(phrase),
      taps.toString(),
      scrolls.toString(),
      foldersOpened.toString(),
      (taps + scrolls + foldersOpened).toString(),
      firstSuggestionHits.toString(),
    ].join(',');

    await file.writeAsString(
      '$line\n',
      mode: FileMode.append,
    );

    phraseId++;
    resetInteractions();
  }

  Future<File> _getCsvFile() async {
    if (Platform.isAndroid) {
      await Permission.manageExternalStorage.request();

      final downloadsDir = Directory('/storage/emulated/0/Download');

      if (!await downloadsDir.exists()) {
        throw Exception('Pasta Downloads não encontrada');
      }

      return File(
        '${downloadsDir.path}/teste_sugestoes_frases.csv',
      );
    }

    final dir = await getApplicationDocumentsDirectory();

    return File(
      '${dir.path}/teste_sugestoes_frases.csv',
    );
    
  }

}