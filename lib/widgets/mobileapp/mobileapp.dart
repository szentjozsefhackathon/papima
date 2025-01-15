import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MobileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: kIsWeb ?[
        Image.asset("assets/gplay.png", height: 100),
        SvgPicture.asset("assets/appstore.svg", height: 100)
      ] : [],
    );
  }
}
