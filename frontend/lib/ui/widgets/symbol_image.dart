import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../data/db.dart';
import '../../services/image_store.dart';

/// Merender gambar sebuah [Symbol] apa pun sumbernya:
/// - `assets/...` — bundel app (Mulberry SVG atau raster)
/// - `data:...` — data URI base64 (foto custom di web)
/// - `http(s)://...` — URL server (gambar hasil sync)
/// - lainnya — path relatif di direktori dokumen app (foto custom)
class SymbolImage extends StatelessWidget {
  const SymbolImage({super.key, required this.symbol, this.fit = BoxFit.contain});

  final Symbol symbol;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = symbol.imageUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    if (url.startsWith('assets/')) {
      return url.endsWith('.svg')
          ? SvgPicture.asset(url, fit: fit)
          : Image.asset(url, fit: fit);
    }
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma == -1) return const SizedBox.shrink();
      return Image.memory(
        base64Decode(url.substring(comma + 1)),
        fit: fit,
        gaplessPlayback: true,
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(url, fit: fit);
    }
    return Image.file(context.read<ImageStore>().resolve(url), fit: fit);
  }
}
