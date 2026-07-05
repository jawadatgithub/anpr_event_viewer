import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/anpr_image_ref.dart';

class AnprImageWidget extends StatelessWidget {
  final AnprImageRef? image;
  final double height;
  final BoxFit fit;

  const AnprImageWidget({
    super.key,
    required this.image,
    this.height = 120,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: _buildImage(context),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (image == null) return const _ImageFallback(icon: Icons.image_not_supported_outlined);

    switch (image!.type) {
      case AnprImageType.url:
        return Image.network(
          image!.value,
          fit: fit,
          headers: const {'User-Agent': 'InSysOut-ANPR-Viewer'},
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (_, __, ___) => const _ImageFallback(icon: Icons.broken_image_outlined),
        );

      case AnprImageType.base64:
        final bytes = _decodeBase64Image(image!.value);
        if (bytes == null || bytes.isEmpty) {
          return const _ImageFallback(icon: Icons.broken_image_outlined);
        }
        return Image.memory(
          bytes,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const _ImageFallback(icon: Icons.broken_image_outlined),
        );

      case AnprImageType.filePath:
        return Image.file(
          File(image!.value),
          fit: fit,
          errorBuilder: (_, __, ___) => const _ImageFallback(icon: Icons.broken_image_outlined),
        );

      case AnprImageType.unknown:
        return const _ImageFallback(icon: Icons.image_not_supported_outlined);
    }
  }

  Uint8List? _decodeBase64Image(String value) {
    try {
      var cleaned = value.trim();

      // Supports: data:image/png;base64,AAAA...
      final commaIndex = cleaned.indexOf(',');
      if (cleaned.toLowerCase().startsWith('data:image/') && commaIndex >= 0) {
        cleaned = cleaned.substring(commaIndex + 1);
      }

      cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }
}

class _ImageFallback extends StatelessWidget {
  final IconData icon;

  const _ImageFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(icon, size: 36, color: Theme.of(context).colorScheme.outline),
    );
  }
}
