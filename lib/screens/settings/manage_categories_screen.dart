import 'package:flutter/material.dart';
import '../../models/board_config.dart';
import '../../models/category_model.dart';
import '../../models/pictogram_model.dart';
import '../../repositories/pictogram_repository.dart';
import '../../services/preferences_service.dart';
import '../add_word_screen.dart';
import 'edit_category_screen.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  final PictogramRepository _pictogramRepository = PictogramRepository();
  BoardConfig? _boardConfig;
  bool _isLoading = true;

  List<Pictogram> _uncategorizedPictograms = [];

  final List<String> categoryTypes = ['pessoas', 'verbos', 'substantivos', 'descritivo', 'social', 'diversos'];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    _boardConfig = await _preferencesService.getBoardConfig();
    _pictogramRepository.updateFullConfig(_boardConfig!);

    final allPictograms = await _pictogramRepository.getAllPictogramsFromDb();

    final wordsInCategories = _boardConfig!.allCategories
        .expand((category) => category.words)
        .map((word) => word.toLowerCase().trim())
        .toSet();

    _uncategorizedPictograms = allPictograms.where((pictogram) {
      return !wordsInCategories.contains(
        pictogram.keyword.toLowerCase().trim(),
      );
    }).toList();

    setState(() => _isLoading = false);
  }

  Future<void> _saveConfig() async {
    if (_boardConfig == null) return;
    await _preferencesService.saveBoardConfig(_boardConfig!);
  }

  void _addCategory() async {
    final newCategoryName = await _showAddCategoryDialog();
    if (newCategoryName != null && newCategoryName.isNotEmpty) {
      if (_boardConfig!.allCategories.any((c) => c.name.toLowerCase() == newCategoryName.toLowerCase())) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uma categoria com este nome já existe.')));
        return;
      }
      setState(() {
        _boardConfig!.allCategories.add(Category(name: newCategoryName, words: []));
      });
      _saveConfig();
    }
  }


  void _addWord() async {
    final newPictogram = await Navigator.push<Pictogram>(
      context,
      MaterialPageRoute(builder: (context) => const AddWordScreen()),
    );

    if (newPictogram != null && mounted) {
      final String? chosenType = await _showTypePickerDialog();
      if (chosenType != null && mounted) {
        newPictogram.type = chosenType;

       
        await _pictogramRepository.saveChosenPictogram(newPictogram);


        final chosenCategory = await _showCategoryPickerDialog();
        
        if (chosenCategory != null) {
          setState(() {
            final categoryInConfig = _boardConfig!.allCategories.firstWhere((c) => c.name == chosenCategory.name);
            if (!categoryInConfig.words.contains(newPictogram.keyword)) {
              categoryInConfig.words.add(newPictogram.keyword);
            }
          });
          _saveConfig(); // Salva a configuração da prancha apenas se uma categoria foi alterada.
        }
        
        // Se chosenCategory for nulo, nada mais acontece, mas a palavra já está salva. 
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('\'${newPictogram.keyword}\' foi salvo no vocabulário.'))
            );
        }
      }
    }
  }

  void _editCategory(int index) async {
    final updatedConfig = await Navigator.push<BoardConfig>(
      context,
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(
          boardConfig: _boardConfig!,
          categoryIndex: index,
        ),
      ),
    );

    if (updatedConfig != null) {
      setState(() {
        _boardConfig = updatedConfig;
      });

      await _saveConfig();
      await _loadConfig();
    }
  }

  void _removeCategory(int index) {
    final categoryToRemove = _boardConfig!.allCategories[index];
    setState(() {
      _boardConfig!.allCategories.removeAt(index);
      _boardConfig!.rootItemIdentifiers.removeWhere((id) => id == 'cat:${categoryToRemove.name}');
    });
    _saveConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerir Categorias e Palavras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            onPressed: _addWord,
            tooltip: 'Adicionar Palavra',
          ),
        ],
      ),
      body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : ListView(
          padding: const EdgeInsets.all(8),
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Categorias',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ..._boardConfig!.allCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(category.name),
                  leading: const Icon(Icons.folder_open),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeCategory(index),
                  ),
                  onTap: () => _editCategory(index),
                ),
              );
            }),

            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Cards sem pasta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (_uncategorizedPictograms.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Nenhum card sem pasta.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._uncategorizedPictograms.map(_buildPictogramListTile),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        tooltip: 'Adicionar Categoria',
        child: const Icon(Icons.create_new_folder_outlined),
      ),
    );
  }


  Future<Category?> _showCategoryPickerDialog() async {
    return showDialog<Category>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecionar Categoria (Opcional)'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _boardConfig!.allCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.do_not_disturb_on_outlined),
                    title: const Text('Nenhuma (Apenas salvar no vocabulário)'),
                    onTap: () {
                      Navigator.of(context).pop(); // Retorna nulo
                    },
                  );
                }
                final category = _boardConfig!.allCategories[index - 1];
                return ListTile(
                  title: Text(category.name),
                  onTap: () {
                    Navigator.of(context).pop(category);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(), // Retorna nulo
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showTypePickerDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
  }

  Future<String?> _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
          title: const Text('Nova Categoria'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Nome da categoria"),
            autofocus: true,
          ),
          actions: [
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('Adicionar'), 
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(nameController.text.trim());
                }
              }
            ),
          ],
        ),
    );
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

    final updated = Pictogram(
      id: pictogram.id,
      keyword: newName.toLowerCase().trim(),
      tags: pictogram.tags,
      type: pictogram.type,
      usageCount: pictogram.usageCount,
      localImagePath: pictogram.localImagePath,
    );

    await _pictogramRepository.updatePictogram(updated);

    for (final category in _boardConfig!.allCategories) {
      final index = category.words.indexWhere(
        (word) => word.toLowerCase().trim() == oldKeyword.toLowerCase().trim(),
      );

      if (index != -1) {
        category.words[index] = updated.keyword;
      }
    }

    final rootIndex = _boardConfig!.rootItemIdentifiers.indexWhere(
      (id) => id.toLowerCase().trim() == oldKeyword.toLowerCase().trim(),
    );

    if (rootIndex != -1) {
      _boardConfig!.rootItemIdentifiers[rootIndex] = updated.keyword;
    }

    await _saveConfig();
    await _loadConfig();
  }
  Future<void> _movePictogramToCategory(Pictogram pictogram) async {
    final chosenCategory = await _showCategoryPickerDialog();

    if (chosenCategory == null) return;

    for (final category in _boardConfig!.allCategories) {
      category.words.removeWhere(
        (word) => word.toLowerCase().trim() ==
            pictogram.keyword.toLowerCase().trim(),
      );
    }

    final targetCategory = _boardConfig!.allCategories.firstWhere(
      (category) => category.name == chosenCategory.name,
    );

    targetCategory.words.add(pictogram.keyword);

    await _saveConfig();
    await _loadConfig();
  }

  Future<void> _deletePictogram(Pictogram pictogram) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar card'),
        content: Text(
          'Deseja apagar "${pictogram.keyword}" do vocabulário?',
        ),
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

    for (final category in _boardConfig!.allCategories) {
      category.words.removeWhere(
        (word) => word.toLowerCase().trim() ==
            pictogram.keyword.toLowerCase().trim(),
      );
    }

    _boardConfig!.rootItemIdentifiers.removeWhere(
      (id) => id.toLowerCase().trim() ==
          pictogram.keyword.toLowerCase().trim(),
    );

    await _pictogramRepository.deletePictogram(pictogram.keyword);
    await _saveConfig();
    await _loadConfig();
  }

  Widget _buildPictogramListTile(Pictogram pictogram) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.image_outlined),
        title: Text(pictogram.keyword),
        subtitle: Text('Tipo: ${pictogram.type}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editPictogram(pictogram);
            } else if (value == 'move') {
              _movePictogramToCategory(pictogram);
            } else if (value == 'delete') {
              _deletePictogram(pictogram);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: Text('Editar'),
            ),
            PopupMenuItem(
              value: 'move',
              child: Text('Adicionar/mover de pasta'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Apagar'),
            ),
          ],
        ),
      ),
    );
  }
}