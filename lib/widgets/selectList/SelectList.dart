import 'package:flutter/material.dart';

class SelectList extends StatefulWidget {
  final List<Map> list;
  final Function(List<Map> parameter) onSelectionChanged;
  final List<Map> initialValue;
  const SelectList({Key? key, required this.list, required this.onSelectionChanged, required this.initialValue}) : super(key: key);

  @override
  _SelectListState createState() => _SelectListState();
}

class _SelectListState extends State<SelectList> {
  bool isSelectionMode = false;
  Map<int, bool> selectedFlag = {};
  
  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < widget.initialValue.length; i++) {
      for (int j = 0; j < widget.list.length; j++) {
        if (widget.initialValue[i]['text'] == widget.list[j]['text']) {
          setState(() {
            selectedFlag[j] = true;
            isSelectionMode = true;
          });
        }
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.builder(
          shrinkWrap: true, // Allows the ListView to adapt to its contents
          physics:
              NeverScrollableScrollPhysics(), // Disables scrolling to prevent conflicts
          itemBuilder: (builder, index) {
            Map data = widget.list[index];
            selectedFlag[index] = selectedFlag[index] ?? false;
            bool isSelected = selectedFlag[index] ?? false;
            return ListTile(
              onLongPress: () => onLongPress(isSelected, index),
              onTap: () => onTap(isSelected, index),
              title: Text("${data['text']}"),
              leading: _buildSelectIcon(isSelected, data),
            );
          },
          itemCount: widget.list.length,
        ),
      ],
    );
  }

  void onTap(bool isSelected, int index) {
    if (isSelectionMode) {
      setState(() {
        selectedFlag[index] = !isSelected;
        isSelectionMode = selectedFlag.containsValue(true);
        _changeSelection();
      });
    } else {}
  }
  void _changeSelection() {
    List<Map> selectedItems = [];
    selectedFlag.forEach((key, value) {
      if (value) {
        selectedItems.add(widget.list[key]);
      }
    });
    widget.onSelectionChanged(selectedItems);
  }
  void onLongPress(bool isSelected, int index) {
    setState(() {
      selectedFlag[index] = !isSelected;
      isSelectionMode = selectedFlag.containsValue(true);
      _changeSelection();
    });
  }

  Widget _buildSelectIcon(bool isSelected, Map data) {
    if (isSelectionMode) {
      return Icon(
        isSelected ? Icons.check_box : Icons.check_box_outline_blank
      );
    } else {
      return CircleAvatar(
        child: Text('${data['text'][0]}'),
      );
    }
  }
}
