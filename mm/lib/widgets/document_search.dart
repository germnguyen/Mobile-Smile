import 'package:flutter/material.dart';

class DocumentSearch extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const DocumentSearch({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<DocumentSearch> createState() =>
      _DocumentSearchState();
}

class _DocumentSearchState
    extends State<DocumentSearch> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(
      _onControllerChanged,
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(
      _onControllerChanged,
    );

    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _clear() {
    widget.controller.clear();

    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      textInputAction:
          TextInputAction.search,
      decoration: InputDecoration(
        hintText:
            'Tìm kiếm tài liệu...',
        prefixIcon: const Icon(
          Icons.search,
        ),
        suffixIcon:
            widget.controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: _clear,
                    icon: const Icon(
                      Icons.clear,
                    ),
                  ),
      ),
    );
  }
}