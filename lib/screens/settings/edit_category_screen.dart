import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/pictogram_model.dart';
import '../add_word_screen.dart';
import '../../repositories/pictogram_repository.dart';

class EditCategoryScreen extends StatefulWidget {
  final Category category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late List<String> _words;
  late TextEditingController _nameController;
  final PictogramRepository _pictogramRepository = PictogramRepository();

  
  final List<String> categoryTypes = ['pessoas', 'verbos', 'substantivos', 'descritivo', 'social', 'diversos'];

  @override
  void initState() {
    super.initState();
    _words = List<String>.from(widget.category.words);
    _nameController = TextEditingController(text: widget.category.name);
  }

  void _removeWord(int index) {
    setState(() {
      _words.removeAt(index);
    });
  }

 
  void _addWord() async {
    // 1. Abre a tela de busca de pictogramas
    final newPictogram = await Navigator.push<Pictogram>(
      context,
      MaterialPageRoute(builder: (context) => const AddWordScreen()),
    );
    
    if (newPictogram != null && !_words.contains(newPictogram.keyword) && mounted) {
      
     
      final String? chosenType = await _showTypePickerDialog();

    
      if (chosenType != null && mounted) {
        newPictogram.type = chosenType;
        
        await _pictogramRepository.saveChosenPictogram(newPictogram);
        
        setState(() {
          _words.add(newPictogram.keyword);
        });
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _words.removeAt(oldIndex);
      _words.insert(newIndex, item);
    });
  }

  void _navigateBack() {
    final updatedCategory = Category(name: _nameController.text.trim(), words: _words);
    Navigator.of(context).pop(updatedCategory);
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
          title: Text('Editar: ${widget.category.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Categoria',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: List.generate(_words.length, (index) {
                  final word = _words[index];
                  return Card(
                    key: ValueKey(word + index.toString()),
                    child: ListTile(
                      title: Text(word),
                      leading: const Icon(Icons.drag_handle),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeWord(index),
                      ),
                    ),
                  );
                }),
                onReorder: _onReorder,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addWord,
          child: const Icon(Icons.add),
          tooltip: 'Adicionar Palavra',
        ),
      ),
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
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           