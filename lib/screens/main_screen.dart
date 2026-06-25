import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/category_model.dart';
import '../models/pictogram_model.dart';
import '../models/board_item.dart';
import '../repositories/pictogram_repository.dart';
import '../services/preferences_service.dart';
import '../services/suggestion_service.dart';
import '../widgets/board_grid.dart';
import '../widgets/sentence_bar.dart';
import '../widgets/suggestion_bar.dart';
import 'settings/manage_categories_screen.dart';
import 'settings/suggestion_settings_screen.dart';
import '../services/test_logger_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final PreferencesService _preferencesService = PreferencesService();
  final PictogramRepository _pictogramRepository = PictogramRepository();
  final SuggestionService _suggestionService = SuggestionService();
  final TestLoggerService _testLogger = TestLoggerService();
  
  final List<Pictogram> _selectedPictograms = [];
  List<Pictogram> _suggestions = [];
  List<BoardItem> _displayItems = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  Set<String> _activeIdentifiers = {};

  Category? _currentCategory;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadSuggestionModel();
    _loadBoard();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("pt-BR");
  }

  Future<void> _loadBoard() async {
    setState(() => _isLoading = true);

    final boardConfig = await _preferencesService.getBoardConfig();
    _pictogramRepository.updateFullConfig(boardConfig);

    _activeIdentifiers = boardConfig.rootItemIdentifiers.toSet();

    if (_currentCategory == null) {
      _displayItems = await _pictogramRepository.getRootBoardItems();

      if (_isEditMode) {
        final allItems = await _pictogramRepository.getAllBoardItems();

        final currentIds = _displayItems.map(_getItemIdentifier).toSet();

        final inactiveItems = allItems.where((item) {
          final id = _getItemIdentifier(item);
          return id.isNotEmpty && !currentIds.contains(id);
        }).toList();

        _displayItems = [..._displayItems, ...inactiveItems];
      }
    } else {
      final categoryPicts = await _pictogramRepository.getPictogramsForBoard(
        _currentCategory!.words,
      );

      _displayItems = [BackItem(), ...categoryPicts];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadSuggestionModel() async {
    await _suggestionService.loadModel();
    await _updateSuggestions();
  }

  String _getItemIdentifier(BoardItem item) {
    if (item is Pictogram) return item.keyword;
    if (item is Category) return 'cat:${item.name}';
    return '';
  }

  void _onItemTap(BoardItem item) {
    if (_isEditMode) {
      String identifier = '';
      if (item is Pictogram) identifier = item.keyword;
      if (item is Category) identifier = 'cat:${item.name}';
      
      if(identifier.isNotEmpty) {
        setState(() {
          if (_activeIdentifiers.contains(identifier)) {
            _activeIdentifiers.remove(identifier);
          } else {
            _activeIdentifiers.add(identifier);
          }
        });
      }
    } else {
      if (item is Pictogram) _onPictogramSelected(item);
      if (item is Category) _onCategorySelected(item);
      if (item is BackItem) _onBackSelected();
    }
  }

  void _onItemsChanged(List<BoardItem> newItems) {
    setState(() {
      _displayItems = newItems;
    });
  }

  Future<void> _toggleEditMode(bool value) async {
    if (!value) {
      final boardConfig = await _preferencesService.getBoardConfig();

      boardConfig.rootItemIdentifiers = _displayItems
          .map(_getItemIdentifier)
          .where((id) => id.isNotEmpty && _activeIdentifiers.contains(id))
          .toList();

      await _preferencesService.saveBoardConfig(boardConfig);
    }

    setState(() {
      _isEditMode = value;
    });

    await _loadBoard();
  }
  
  Future<void> _onPictogramSelected(Pictogram pictogram) async {
    _testLogger.countTap();

    if (_suggestions.isNotEmpty &&
        _suggestions.first.keyword == pictogram.keyword) {
      _testLogger.countFirstSuggestionHit();
    }

    await _suggestionService.addTransition(
      currentSentence: _selectedPictograms.map((p) => p.keyword).toList(),
      newWord: pictogram.keyword,
    );

    _speak(pictogram.keyword);
    _pictogramRepository.recordPictogramUsage(pictogram);

    setState(() {
      _selectedPictograms.add(pictogram);
    });

    _updateSuggestions();
  }
  
  Future<void> _updateSuggestions() async {
    if (_selectedPictograms.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final sentenceWords =
        _selectedPictograms.map((p) => p.keyword).toList();

    final suggestedKeywords =
        _suggestionService.getSuggestions(sentenceWords);

    final suggestedPictograms =
        await _pictogramRepository.getPictogramsForBoard(suggestedKeywords);

    setState(() {
      _suggestions = suggestedPictograms;
    });
  }

  void _onCategorySelected(Category category) {
    if(_isEditMode) return;

    _testLogger.countFolderOpened();

    setState(() {
      _currentCategory = category;
      _loadBoard();
    });
  }

  void _onBackSelected() {
    setState(() {
      _currentCategory = null;
      _loadBoard();
    });
  }
  
  void _navigateToManageCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageCategoriesScreen(),
      ),
    ).then((_) => _loadBoard());
  }

  void _navigateToSuggestionSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SuggestionSettingsScreen(),
      ),
    ).then((_) async {
      await _suggestionService.loadModel();
      await _updateSuggestions();
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }
  void _playSentence() {
    if (_selectedPictograms.isNotEmpty) {
      final words = _selectedPictograms.map((p) => p.keyword).toList();
      final phrase = words.join(' ');

      _speak(phrase);
      _suggestionService.saveSentence(words);

      _testLogger.savePhraseLog(
        phrase: phrase,
        suggestionMode: _suggestionService.mode.name,
      );
    }
  }
  
  void _deleteLastPictogram() {
    if (_selectedPictograms.isNotEmpty) {
      setState(() {
        _selectedPictograms.removeLast();

        if (_selectedPictograms.isEmpty) {
          _suggestions = [];
        }
      });

      if (_selectedPictograms.isNotEmpty) {
        _updateSuggestions();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modo Edição' : (_currentCategory?.name ?? 'Say for Me')),
        actions: [
          // ➕ Gerenciar pictogramas
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Gerenciar pictogramas',
            onPressed: _navigateToManageCategories,
          ),

          // Configurar IA
          IconButton(
            icon: const Icon(Icons.psychology_alt_rounded),
            tooltip: 'Configurar IA',
            onPressed: _navigateToSuggestionSettings,
          ),

          const SizedBox(width: 6),

          // Modo edição
          Row(
            children: [
              Icon(
                Icons.edit_rounded,
                color: _isEditMode
                    ? Colors.orange
                    : Colors.grey.shade600,
                size: 20,
              ),

              Switch(
                value: _isEditMode,
                onChanged: _toggleEditMode,

                activeColor: Colors.orange,
                activeTrackColor: Colors.orange.shade200,

                inactiveThumbColor: Colors.grey.shade700,
                inactiveTrackColor: Colors.grey.shade400,
              ),
            ],
          ),

          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          SentenceBar(
            selectedPictograms: _selectedPictograms,
            onPlay: _playSentence,
            onDelete: _deleteLastPictogram,
          ),
          const Divider(height: 1, thickness: 1),
          SuggestionBar(
            suggestions: _suggestions,
            onSuggestionTapped: (suggestion) {
              _onPictogramSelected(suggestion);
            },
          ),
          const Divider(height: 1, thickness: 1),
          BoardGrid(
            isLoading: _isLoading,
            items: _displayItems,
            isEditMode: _isEditMode,
            activeIdentifiers: _activeIdentifiers,
            onItemTap: _onItemTap,
            onItemsChanged: _onItemsChanged,
            onScrollDetected: () => _testLogger.countScroll(),
          ),
        ],
      ),
    );
  }
  
}

