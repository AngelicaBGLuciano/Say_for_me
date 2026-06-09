import 'package:flutter/material.dart';
import '../../models/pictogram_model.dart';
import '../../repositories/pictogram_repository.dart';
import '../../widgets/pictogram_item.dart';

class SelectPictogramsScreen extends StatefulWidget {
  final List<String> existingWords;

  const SelectPictogramsScreen({super.key, required this.existingWords});

  @override
  State<SelectPictogramsScreen> createState() => _SelectPictogramsScreenState();
}

class _SelectPictogramsScreenState extends State<SelectPictogramsScreen> {
  final PictogramRepository _pictogramRepository = PictogramRepository();
  List<Pictogram> _allPictograms = [];
  List<Pictogram> _filteredPictograms = [];
  bool _isLoading = true;
  
  final Set<String> _selectedKeywords = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPictograms();
    _searchController.addListener(_filterPictograms);
  }

  Future<void> _loadPictograms() async {
    setState(() => _isLoading = true);
    final allPicts = await _pictogramRepository.getAllPictogramsFromDb();
    // Filtra para mostrar apenas pictogramas que ainda não estão na categoria
    _allPictograms = allPicts.where((p) => !widget.existingWords.contains(p.keyword)).toList();
    _filteredPictograms = _allPictograms;
    setState(() => _isLoading = false);
  }

  void _filterPictograms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPictograms = _allPictograms.where((pictogram) {
        return pictogram.keyword.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleSelection(String keyword) {
    setState(() {
      if (_selectedKeywords.contains(keyword)) {
        _selectedKeywords.remove(keyword);
      } else {
        _selectedKeywords.add(keyword);
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Pictogramas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_selectedKeywords.toList());
            },
            tooltip: 'Confirmar Seleção',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar no vocabulário',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredPictograms.length,
                    itemBuilder: (context, index) {
                      final pictogram = _filteredPictograms[index];
                      final isSelected = _selectedKeywords.contains(pictogram.keyword);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          PictogramItem(
                            pictogram: pictogram,
                            onTap: () => _toggleSelection(pictogram.keyword),
                          ),
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Icon(Icons.check_circle, color: Colors.white, size: 40),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
