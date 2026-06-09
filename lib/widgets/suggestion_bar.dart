import 'package:flutter/material.dart';
import '../models/pictogram_model.dart';
import 'pictogram_item.dart';

class SuggestionBar extends StatelessWidget {
  final List<Pictogram> suggestions;
  final Function(Pictogram) onSuggestionTapped;

  const SuggestionBar({
    super.key, 
    required this.suggestions, 
    required this.onSuggestionTapped
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Sugestões:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(8),
              ),
              // Se não houver sugestões, mostra a mensagem. Se houver, mostra a lista.
              child: suggestions.isEmpty
                ? const Center(
                    child: Text(
                      'Sugestões.',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final pictogram = suggestions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: SizedBox(
                          width: 90, // Tamanho fixo para cada sugestão
                          child: PictogramItem(
                            pictogram: pictogram,
                            onTap: () => onSuggestionTapped(pictogram),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

