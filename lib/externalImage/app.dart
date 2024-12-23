import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

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
  late Image _imageElement;

  @override
  void initState() {
    super.initState();


    _imageElement = Image.network(widget.src,
      width: widget.maxWidth,
      height: widget.maxHeight,
      fit: BoxFit.scaleDown);
  }

  @override
  void didUpdateWidget(DynamicImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Ellenőrizzük, hogy változott-e a képforrás vagy a méretek
    if (widget.src != oldWidget.src ||
        widget.maxWidth != oldWidget.maxWidth ||
        widget.maxHeight != oldWidget.maxHeight) {
      setState(() {
        _imageElement = Image.network(widget.src,
          width: widget.maxWidth,
          height: widget.maxHeight,
          fit: BoxFit.scaleDown);
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
          child: _imageElement, // HTML nézet
        ),
      ],
    );
  }
}
