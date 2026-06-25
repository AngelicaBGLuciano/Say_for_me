import 'package:flutter/material.dart';

import '../../models/board_config.dart';
import '../../models/category_model.dart';
import '../../models/pictogram_model.dart';
import '../../repositories/pictogram_repository.dart';
import '../add_word_screen.dart';

class EditCategoryScreen extends StatefulWidget {
  final BoardConfig boardConfig;
  final int categoryIndex;

  const EditCategoryScreen({
    super.key,
    required this.boardConfig,
    required this.categoryIndex,
  });

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final PictogramRepository _pictogramRepository = PictogramRepository();

  late BoardConfig _boardConfig;
  late TextEditingController _nameController;
  late List<String> _words;
  late String _originalCategoryName;

  List<Pictogram> _allPictograms = [];
  bool _isLoading = true;

  final List<String> categoryTypes = [
    'pessoas',
    'verbos',
    'substantivos',
    'descritivo',
    'social',
    'diversos',
  ];

  Category get _currentCategory => _boardConfig.allCategories[widget.categoryIndex];

  @override
  void initState() {
    super.initState();

    _boardConfig = widget.boardConfig;
    _originalCategoryName = _currentCategory.name;
    _words = List<String>.from(_currentCategory.words);
    _nameController = TextEditingController(text: _currentCategory.name);

    _loadPictograms();
  }

  Future<void> _loadPictograms() async {
    final pictograms = await _pictogramRepository.getAllPictogramsFromDb();

    if (mounted) {
      setState(() {
        _allPictograms = pictograms;
        _isLoading = false;
      });
    }
  }

  Pictogram? _findPictogram(String word) {
    try {
      return _allPictograms.firstWhere(
        (p) => p.keyword.toLowerCase().trim() == word.toLowerCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  void _saveCurrentCategoryIntoConfig() {
    final newName = _nameController.text.trim();

    if (newName.isNotEmpty && newName != _originalCategoryName) {
      final oldIdentifier = 'cat:$_originalCategoryName';
      final newIdentifier = 'cat:$newName';

      final rootIndex = _boardConfig.rootItemIdentifiers.indexOf(oldIdentifier);

      if (rootIndex != -1) {
        _boardConfig.rootItemIdentifiers[rootIndex] = newIdentifier;
      }

      _originalCategoryName = newName;
    }

    _boardConfig.allCategories[widget.categoryIndex] = Category(
      name: newName,
      words: _words,
    );
  }

  void _navigateBack() {
    _saveCurrentCategoryIntoConfig();
    Navigator.of(context).pop(_boardConfig);
  }

  Future<void> _addWord() async {
    final newPictogram = await Navigator.push<Pictogram>(
      context,
      MaterialPageRoute(builder: (context) => const AddWordScreen()),
    );

    if (newPictogram == null || !mounted) return;

    if (_words.contains(newPictogram.keyword)) return;

    final chosenType = await _showTypePickerDialog();

    if (chosenType == null || !mounted) return;

    newPictogram.type = chosenType;

    await _pictogramRepository.saveChosenPictogram(newPictogram);

    setState(() {
      _words.add(newPictogram.keyword);
    });

    await _loadPictograms();
  }

  Future<void> _editPictogram(Pictogram pictogram) async {
    final nameController = TextEditingController(text: pictogram.keyword);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar card'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nome do card'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final text = nameController.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newName == null || newName == pictogram.keyword) return;

    final oldKeyword = pictogram.keyword;
    final updatedKeyword = newName.toLowerCase().trim();

    final updated = Pictogram(
      id: pictogram.id,
      keyword: updatedKeyword,
      tags: pictogram.tags,
      type: pictogram.type,
      usageCount: pictogram.usageCount,
      localImagePath: pictogram.localImagePath,
    );

    await _pictogramRepository.updatePictogram(updated);

    for (final category in _boardConfig.allCategories) {
      for (int i = 0; i < category.words.length; i++) {
        if (category.words[i].toLowerCase().trim() ==
            oldKeyword.toLowerCase().trim()) {
          category.words[i] = updatedKeyword;
        }
      }
    }

    for (int i = 0; i < _words.length; i++) {
      if (_words[i].toLowerCase().trim() == oldKeyword.toLowerCase().trim()) {
        _words[i] = updatedKeyword;
      }
    }

    for (int i = 0; i < _boardConfig.rootItemIdentifiers.length; i++) {
      if (_boardConfig.rootItemIdentifiers[i].toLowerCase().trim() ==
          oldKeyword.toLowerCase().trim()) {
        _boardConfig.rootItemIdentifiers[i] = updatedKeyword;
      }
    }

    await _loadPictograms();
    setState(() {});
  }

  Future<void> _movePictogram(Pictogram pictogram) async {
    final targetCategory = await _showCategoryPickerDialog();

    if (targetCategory == null) return;

    for (final category in _boardConfig.allCategories) {
      category.words.removeWhere(
        (word) =>
            word.toLowerCase().trim() ==
            pictogram.keyword.toLowerCase().trim(),
      );
    }

    final target = _boardConfig.allCategories.firstWhere(
      (category) => category.name == targetCategory.name,
    );

    target.words.add(pictogram.keyword);

    setState(() {
      _words.removeWhere(
        (word) =>
            word.toLowerCase().trim() ==
            pictogram.keyword.toLowerCase().trim(),
      );
    });
  }

  Future<void> _deletePictogram(Pictogram pictogram) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar card'),
        content: Text('Deseja apagar "${pictogram.keyword}" do vocabulário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (final category in _boardConfig.allCategories) {
      category.words.removeWhere(
        (word) =>
            word.toLowerCase().trim() ==
            pictogram.keyword.toLowerCase().trim(),
      );
    }

    _boardConfig.rootItemIdentifiers.removeWhere(
      (id) =>
          id.toLowerCase().trim() ==
          pictogram.keyword.toLowerCase().trim(),
    );

    await _pictogramRepository.deletePictogram(pictogram.keyword);

    setState(() {
      _words.removeWhere(
        (word) =>
            word.toLowerCase().trim() ==
            pictogram.keyword.toLowerCase().trim(),
      );
    });

    await _loadPictograms();
  }

  void _removeWordOnlyFromThisFolder(int index) {
    setState(() {
      _words.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;

      final item = _words.removeAt(oldIndex);
      _words.insert(newIndex, item);
    });
  }

  Widget _buildWordTile(String word, int index) {
    final pictogram = _findPictogram(word);

    return Card(
      key: ValueKey('$word-$index'),
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(word),
        subtitle: pictogram == null ? null : Text('Tipo: ${pictogram.type}'),
        trailing: pictogram == null
            ? IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => _removeWordOnlyFromThisFolder(index),
              )
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editPictogram(pictogram);
                  } else if (value == 'move') {
                    _movePictogram(pictogram);
                  } else if (value == 'remove') {
                    _removeWordOnlyFromThisFolder(index);
                  } else if (value == 'delete') {
                    _deletePictogram(pictogram);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar card'),
                  ),
                  PopupMenuItem(
                    value: 'move',
                    child: Text('Mover para outra pasta'),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remover desta pasta'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Apagar do vocabulário'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<Category?> _showCategoryPickerDialog() async {
    final availableCategories = _boardConfig.allCategories.where((category) {
      return category.name != _nameController.text.trim();
    }).toList();

    return showDialog<Category>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mover para pasta'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableCategories.length,
            itemBuilder: (context, index) {
              final category = availableCategories[index];

              return ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(category.name),
                onTap: () => Navigator.pop(context, category),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<String?> _showTypePickerDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Tipo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categoryTypes.length,
            itemBuilder: (context, index) {
              final type = categoryTypes[index];

              return ListTile(
                title: Text(type),
                onTap: () => Navigator.of(context).pop(type),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _navigateBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Editar: ${_currentCategory.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da pasta',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ReorderableListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onReorder: _onReorder,
                      children: List.generate(_words.length, (index) {
                        return _buildWordTile(_words[index], index);
                      }),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addWord,
          tooltip: 'Adicionar card',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}