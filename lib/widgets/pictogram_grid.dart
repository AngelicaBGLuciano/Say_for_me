import 'package:flutter/material.dart';
import '../models/pictogram_model.dart';  
import 'pictogram_item.dart';


class PictogramGrid extends StatelessWidget {
  final bool isLoading;
  final List<Pictogram> boardPictograms;
  final Function(Pictogram) onPictogramSelected;

  const PictogramGrid({
    super.key,
    required this.isLoading,
    required this.boardPictograms,
    required this.onPictogramSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: boardPictograms.length,
      itemBuilder: (context, index) {
        final pictogram = boardPictograms[index];
        return PictogramItem(
          pictogram: pictogram,
          onTap: () => onPictogramSelected(pictogram),
        );
      },
    );
  }
}