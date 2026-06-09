import 'package:flutter/material.dart';
import '../../services/suggestion_service.dart';

class SuggestionSettingsScreen extends StatefulWidget {
  const SuggestionSettingsScreen({super.key});

  @override
  State<SuggestionSettingsScreen> createState() =>
      _SuggestionSettingsScreenState();
}

class _SuggestionSettingsScreenState extends State<SuggestionSettingsScreen> {
  final SuggestionService _suggestionService = SuggestionService();

  SuggestionMode _selectedMode = SuggestionMode.none;
  bool _isLoading = true;
  bool _isTraining = false;

  // Frases de treino
  final List<List<String>> _trainingSentences = [
    ['eu', 'querer', 'água'],
    ['eu', 'querer', 'água'],
    ['eu', 'querer', 'água'],
    ['eu', 'querer', 'coca-cola'],
    ['eu', 'querer', 'coca-cola'],
    ['eu', 'querer', 'comer'],
    ['eu', 'querer', 'comer'],
    ['eu', 'querer', 'comer'],
    ['eu', 'querer', 'jogar'],
    ['eu', 'querer', 'jogar'],
    ['eu', 'usar', 'tablet'],
    ['eu', 'usar', 'tablet'],
    ['eu', 'usar', 'tablet'],
    ['eu', 'usar','telefone'],
    ['eu', 'usar','telefone'],
    ['eu', 'ler', 'livro'],
    ['mulher', 'beber', 'água'],
    ['mulher', 'beber', 'água'],
    ['mulher', 'querer', 'comer'],
    ['mulher', 'querer', 'comer'],
    ['mulher','querer','jogar'],
    ['homem', 'beber', 'água'],
    ['homem', 'querer', 'comer'],
    ['homem','querer','jogar'],
    ['homem','usar','tablet'],
    ['homem','usar','telefone'],
    ['eu', 'gostar','água'],
    ['eu', 'gostar','água'],
    ['eu', 'gostar','coca-cola'],
    ['eu', 'gostar','jogar'],
    ['eu', 'gostar','tablet'],
    ['eu', 'sentir','feliz'],
    ['eu', 'sentir','feliz'],
    ['eu', 'sentir','medo'],
    ['eu', 'sentir','medo'],
    ['eu', 'sentir','cansado'],
    ['eu', 'ir', 'escola'],
    ['eu', 'ir', 'escola'],
    ['eu','ir','sanitário'],
    ['eu', 'ir', 'jardim'],
    ['eu', 'ir', 'mercado'],
    ['não', 'querer', 'comer'],
    ['não', 'querer', 'jogar'],
    ['não', 'querer', 'água'],
    ['não', 'querer', 'água'],
    ['não', 'querer', 'escola'],
    ['querer','beber','água'],
    ['querer','beber','água'],
    ['querer','comer','arroz'],
    ['querer','comer','arroz'],
    ['querer','comer','massa'],
    ['querer','comer','massa'],
    ['querer','jogar','bola'],
    ['querer','jogar','bola'],
    ['querer','usar','tablet'],
    ['querer','usar','tablet'],
    ['querer','usar','telefone'],
    ['querer','usar','telefone'],
    ['querer','ler','livro'],
    ['querer','ler','livro'],
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedMode();
  }

  Future<void> _loadSelectedMode() async {
    await _suggestionService.loadModel();

    if (mounted) {
      setState(() {
        _selectedMode = _suggestionService.mode;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeMode(SuggestionMode? mode) async {
    if (mode == null) return;

    await _suggestionService.setMode(mode);

    if (mounted) {
      setState(() {
        _selectedMode = mode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modo alterado para: ${_getModeTitle(mode)}'),
        ),
      );
    }
  }

  Future<void> _trainAI() async {
    setState(() => _isTraining = true);

    await _suggestionService.trainWithSentences(_trainingSentences);

    if (mounted) {
      setState(() => _isTraining = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IA treinada com sucesso.'),
        ),
      );
    }
  }

  Future<void> _clearTraining() async {
    setState(() => _isTraining = true);

    await _suggestionService.clearTraining();

    if (mounted) {
      setState(() => _isTraining = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treinamento apagado.'),
        ),
      );
    }
  }

  String _getModeTitle(SuggestionMode mode) {
    switch (mode) {
      case SuggestionMode.none:
        return 'Sem sugestão';
      case SuggestionMode.markov1:
        return 'Markov ordem 1';
      case SuggestionMode.markov2:
        return 'Markov ordem 2';
      case SuggestionMode.knn:
        return 'KNN';
    }
  }

  String _getModeDescription(SuggestionMode mode) {
    switch (mode) {
      case SuggestionMode.none:
        return 'A barra de sugestões ficará vazia.';
      case SuggestionMode.markov1:
        return 'Sugere com base apenas na última palavra escolhida.';
      case SuggestionMode.markov2:
        return 'Sugere com base nas duas últimas palavras escolhidas.';
      case SuggestionMode.knn:
        return 'Compara a frase atual com frases usadas anteriormente.';
    }
  }

  IconData _getModeIcon(SuggestionMode mode) {
    switch (mode) {
      case SuggestionMode.none:
        return Icons.block_rounded;
      case SuggestionMode.markov1:
        return Icons.looks_one_rounded;
      case SuggestionMode.markov2:
        return Icons.looks_two_rounded;
      case SuggestionMode.knn:
        return Icons.hub_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar IA'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton.icon(
                  onPressed: _isTraining ? null : _trainAI,
                  icon: const Icon(Icons.school_rounded),
                  label: Text(
                    _isTraining ? 'Treinando...' : 'Treinar IA',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isTraining ? null : _clearTraining,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Apagar treinamento'),
                ),
                const SizedBox(height: 16),

                ...SuggestionMode.values.map((mode) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: RadioListTile<SuggestionMode>(
                      value: mode,
                      groupValue: _selectedMode,
                      onChanged: _changeMode,
                      secondary: Icon(
                        _getModeIcon(mode),
                        color: _selectedMode == mode
                            ? Colors.deepPurple
                            : Colors.grey.shade700,
                      ),
                      title: Text(
                        _getModeTitle(mode),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(_getModeDescription(mode)),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}