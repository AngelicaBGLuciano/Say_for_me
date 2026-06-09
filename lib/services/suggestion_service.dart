import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

enum SuggestionMode {
  none,
  markov1,
  markov2,
  knn,
}

class SuggestionService {
  static final SuggestionService _instance = SuggestionService._internal();

  factory SuggestionService() {
    return _instance;
  }

  SuggestionService._internal();

  static const String _markov1Key = 'markovModelOrder1';
  static const String _markov2Key = 'markovModelOrder2';
  static const String _historyKey = 'sentenceHistory';
  static const String _modeKey = 'suggestionMode';

  Map<String, Map<String, int>> _markov1 = {};
  Map<String, Map<String, int>> _markov2 = {};
  List<List<String>> _history = [];

  SuggestionMode _mode = SuggestionMode.none;

  SuggestionMode get mode => _mode;

  Future<void> loadModel() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString(_modeKey);
    _mode = _modeFromString(savedMode);

    final jsonMarkov1 = prefs.getString(_markov1Key);
    if (jsonMarkov1 != null) {
      final decoded = json.decode(jsonMarkov1) as Map<String, dynamic>;
      _markov1 = decoded.map(
        (key, value) => MapEntry(key, Map<String, int>.from(value)),
      );
    }

    final jsonMarkov2 = prefs.getString(_markov2Key);
    if (jsonMarkov2 != null) {
      final decoded = json.decode(jsonMarkov2) as Map<String, dynamic>;
      _markov2 = decoded.map(
        (key, value) => MapEntry(key, Map<String, int>.from(value)),
      );
    }

    final jsonHistory = prefs.getString(_historyKey);
    if (jsonHistory != null) {
      final decoded = json.decode(jsonHistory) as List<dynamic>;
      _history = decoded.map((s) => List<String>.from(s)).toList();
    }
  }

  Future<void> setMode(SuggestionMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> _saveModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_markov1Key, json.encode(_markov1));
    await prefs.setString(_markov2Key, json.encode(_markov2));
    await prefs.setString(_historyKey, json.encode(_history));
  }

  Future<void> addTransition({
    required List<String> currentSentence,
    required String newWord,
  }) async {
    if (currentSentence.isNotEmpty) {
      _addToMap(_markov1, currentSentence.last, newWord);
    }

    if (currentSentence.length >= 2) {
      final key =
          '${currentSentence[currentSentence.length - 2]} ${currentSentence.last}';
      _addToMap(_markov2, key, newWord);
    }

    await _saveModel();
  }

  Future<void> saveSentence(List<String> sentence) async {
    if (sentence.length < 2) return;

    _history.add(sentence);

    if (_history.length > 300) {
      _history.removeAt(0);
    }

    await _saveModel();
  }

  Future<void> trainWithSentences(List<List<String>> sentences) async {
    for (final sentence in sentences) {
      if (sentence.length < 2) continue;

      for (int i = 0; i < sentence.length; i++) {
        final currentSentence = sentence.sublist(0, i);
        final newWord = sentence[i];

        await addTransition(
          currentSentence: currentSentence,
          newWord: newWord,
        );
      }

      await saveSentence(sentence);
    }

    await _saveModel();
  }

  Future<void> clearTraining() async {
    _markov1 = {};
    _markov2 = {};
    _history = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_markov1Key);
    await prefs.remove(_markov2Key);
    await prefs.remove(_historyKey);
  }

  void _addToMap(
    Map<String, Map<String, int>> map,
    String from,
    String to,
  ) {
    if (!map.containsKey(from)) {
      map[from] = {};
    }

    map[from]![to] = (map[from]![to] ?? 0) + 1;
  }

  List<String> getSuggestions(
    List<String> currentSentence, {
    int count = 10,
  }) {
    if (_mode == SuggestionMode.none || currentSentence.isEmpty) {
      return [];
    }

    switch (_mode) {
      case SuggestionMode.none:
        return [];
      case SuggestionMode.markov1:
        return _getMarkov1Suggestions(currentSentence.last, count);
      case SuggestionMode.markov2:
        return _getMarkov2Suggestions(currentSentence, count);
      case SuggestionMode.knn:
        return _getKnnSuggestions(currentSentence, count);
    }
  }

  List<String> _getMarkov1Suggestions(String lastWord, int count) {
    return _getTopWords(_markov1[lastWord], count);
  }

  List<String> _getMarkov2Suggestions(List<String> sentence, int count) {
    if (sentence.length < 2) {
      return _getMarkov1Suggestions(sentence.last, count);
    }

    final key = '${sentence[sentence.length - 2]} ${sentence.last}';
    final result = _getTopWords(_markov2[key], count);

    if (result.isNotEmpty) {
      return result;
    }

    return _getMarkov1Suggestions(sentence.last, count);
  }

  List<String> _getTopWords(Map<String, int>? map, int count) {
    if (map == null || map.isEmpty) return [];

    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(count).map((entry) => entry.key).toList();
  }

  List<String> _getKnnSuggestions(
    List<String> currentSentence,
    int count, {
    int k = 5,
  }) {
    final List<_KnnNeighbor> neighbors = [];

    for (final sentence in _history) {
      for (int i = 0; i < sentence.length - 1; i++) {
        final context = sentence.sublist(0, i + 1);
        final nextWord = sentence[i + 1];

        final similarity = _calculateSimilarity(currentSentence, context);

        if (similarity > 0) {
          neighbors.add(
            _KnnNeighbor(
              nextWord: nextWord,
              similarity: similarity,
            ),
          );
        }
      }
    }

    neighbors.sort((a, b) => b.similarity.compareTo(a.similarity));

    final nearestNeighbors = neighbors.take(k).toList();

    final Map<String, double> votes = {};

    for (final neighbor in nearestNeighbors) {
      votes[neighbor.nextWord] =
          (votes[neighbor.nextWord] ?? 0) + neighbor.similarity;
    }

    final sortedVotes = votes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedVotes.take(count).map((entry) => entry.key).toList();
  }

  double _calculateSimilarity(List<String> a, List<String> b) {
    final minLength = min(a.length, b.length);
    if (minLength == 0) return 0;

    int matches = 0;

    for (int i = 1; i <= minLength; i++) {
      if (a[a.length - i] == b[b.length - i]) {
        matches++;
      } else {
        break;
      }
    }

    return matches / minLength;
  }

  SuggestionMode _modeFromString(String? value) {
    switch (value) {
      case 'markov1':
        return SuggestionMode.markov1;
      case 'markov2':
        return SuggestionMode.markov2;
      case 'knn':
        return SuggestionMode.knn;
      case 'none':
      default:
        return SuggestionMode.none;
    }
  }
}

class _KnnNeighbor {
  final String nextWord;
  final double similarity;

  _KnnNeighbor({
    required this.nextWord,
    required this.similarity,
  });
}