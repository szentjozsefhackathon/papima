import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

class DynamicImage extends StatefulWidget {
  final String src; // Képforrás
  final double maxWidth; // Maximális szélesség
  final double maxHeight; // Maximális magasság

  const DynamicImage({
    Key? key,
    required this.src,
    required this.maxWidth,
    required this.maxHeight,
  }) : super(key: key);

  @override
  _DynamicImageState createState() => _DynamicImageState();
}

class _DynamicImageState extends State<DynamicImage> {
  late web.HTMLImageElement _imageElement; // HTML ImageElement a kép megjelenítéséhez
  late String _viewType; // Egyedi nézettípus az azonosításhoz

  @override
  void initState() {
    super.initState();
    _viewType = 'html-image-view-${UniqueKey()}'; // Egyedi azonosító generálása

    // Regisztráljuk a platformnézet gyárat
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _imageElement, // A HTML elem visszaadása
      );
    }

    // HTML ImageElement inicializálása
    _imageElement = web.HTMLImageElement()
      ..src = widget.src // Beállítjuk a képforrást
      ..style.objectFit = 'scale-down'
      ..style.maxWidth = '${widget.maxWidth}px' // Maximális szélesség stílus
      ..style.maxHeight = '${widget.maxHeight}px'; // Maximális magasság stílus
  }

  @override
  void didUpdateWidget(DynamicImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Ellenőrizzük, hogy változott-e a képforrás vagy a méretek
    if (widget.src != oldWidget.src ||
        widget.maxWidth != oldWidget.maxWidth ||
        widget.maxHeight != oldWidget.maxHeight) {
      setState(() {
        _imageElement.src = widget.src; // Új képforrás beállítása
        _imageElement.style.maxWidth = '${widget.maxWidth}px'; // Új max szélesség
        _imageElement.style.maxHeight = '${widget.maxHeight}px'; // Új max magasság 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.maxWidth, // A nézet szélessége
          height: widget.maxHeight, // A nézet magassága
          child: HtmlElementView(viewType: _viewType), // HTML nézet
        ),
      ],
    );
  }
}
