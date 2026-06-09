import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pictogram_model.dart';
import '../utils/pictogram_helper.dart';

class PictogramItem extends StatefulWidget {
  final Pictogram pictogram;
  final VoidCallback onTap;

  const PictogramItem({
    super.key,
    required this.pictogram,
    required this.onTap,
  });

  @override
  State<PictogramItem> createState() => _PictogramItemState();
}

class _PictogramItemState extends State<PictogramItem> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.90);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  Widget _buildImage() {
    final pict = widget.pictogram;

    // prioridade: imagem local
    if (pict.localImagePath != null && pict.localImagePath!.isNotEmpty) {
      return Image.file(
        File(pict.localImagePath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.red);
        },
      );
    }

    // fallback: internet
    return CachedNetworkImage(
      imageUrl: pict.imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) =>
          const Icon(Icons.error, color: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Card(
          color: PictogramHelper.getColorForType(widget.pictogram.type),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  margin: const EdgeInsets.all(6.0),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: _buildImage(), // 🔥 aqui está a mágica
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(
                  widget.pictogram.keyword,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}