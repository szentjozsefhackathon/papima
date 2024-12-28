import 'package:flutter/material.dart';


class DailyStreakDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: Text('Napi sorozat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Hány napja használod aktívan a PapIma alkalmazást.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Bezárás'),
        ),
      ],
    );
  }
}