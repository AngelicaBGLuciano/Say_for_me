import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pictogram_model.dart';

class SentenceBar extends StatelessWidget {
  final List<Pictogram> selectedPictograms;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const SentenceBar({
    super.key,
    required this.selectedPictograms,
    required this.onPlay,
    required this.onDelete,
  });

  Widget _buildImage(Pictogram pictogram) {
    // prioridade: imagem local
    if (pictogram.localImagePath != null &&
        pictogram.localImagePath!.isNotEmpty) {
      return Image.file(
        File(pictogram.localImagePath!),
        width: 60,
        height: 60,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.red),
      );
    }

    // fallback: internet
    return CachedNetworkImage(
      imageUrl: pictogram.imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.contain,
      placeholder: (context, url) =>
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: selectedPictograms.isEmpty
                ? const Center(
                    child: Text(
                      ' ',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedPictograms.length,
                    itemBuilder: (context, index) {
                      final pict = selectedPictograms[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: _buildImage(pict), // 🔥 aqui
                      );
                    },
                  ),
          ),
          const VerticalDivider(width: 16, thickness: 1),
          IconButton(
            icon: const Icon(Icons.play_circle_fill,
                color: Colors.green, size: 40),
            tooltip: 'Ler a frase',
            onPressed: onPlay,
          ),
          IconButton(
            icon: const Icon(Icons.backspace,
                color: Colors.red, size: 40),
            tooltip: 'Apagar último',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}