import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/pictogram_model.dart';
import '../repositories/pictogram_repository.dart';

class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PictogramRepository _pictogramRepository = PictogramRepository();
  final ImagePicker _picker = ImagePicker();

  List<Pictogram> _foundPictograms = [];
  bool _isLoading = false;
  bool _hasSearched = false;


  // BUSCA API
  Future<void> _searchWord() async {
    if (_searchController.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _foundPictograms = [];
    });

    final results = await _pictogramRepository.searchApiForNewPictograms(
      _searchController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _foundPictograms = results;
        _isLoading = false;
      });
    }
  }

  // Galeria
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final keyword = await _askForWordName();
    if (keyword == null || keyword.isEmpty) return;

    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final savedImage =
        await File(image.path).copy('${directory.path}/$fileName');

    final pictogram = Pictogram(
      id: DateTime.now().millisecondsSinceEpoch, // id único
      keyword: keyword,
      tags: [],
      localImagePath: savedImage.path, // imagem local
    );

    if (mounted) {
      Navigator.pop(context, pictogram);
    }
  }

  Future<String?> _askForWordName() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nome da palavra'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'Ex: bola, cachorro...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // Escolher pictograma
  void _onPictogramChosen(Pictogram pictogram) {
    if (mounted) {
      Navigator.pop(context, pictogram);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Nova Palavra'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // 📸 BOTÃO GALERIA
          ElevatedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.photo),
            label: const Text('Escolher da galeria'),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Digite a palavra para buscar',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchWord,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchWord(),
            ),
          ),

          Expanded(child: _buildResultWidget()),
        ],
      ),
    );
  }

  Widget _buildResultWidget() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return const Center(
          child: Text('Digite um termo e pressione buscar.'));
    }
    if (_foundPictograms.isEmpty) {
      return const Center(
          child: Text('Nenhum pictograma encontrado.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _foundPictograms.length,
      itemBuilder: (context, index) {
        final pictogram = _foundPictograms[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _onPictogramChosen(pictogram),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: pictogram.imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: pictogram.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                const Center(
                                    child:
                                        CircularProgressIndicator()),
                            errorWidget:
                                (context, url, error) =>
                                    const Icon(Icons.error),
                          )
                        : Image.file(
                            File(pictogram.imageUrl),
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    pictogram.keyword,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}