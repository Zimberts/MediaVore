import 'package:flutter/material.dart';

/// A reusable text input widget that encapsulates the lifecycle of a
/// [TextEditingController], ensuring proper disposal when unmounted.
class PromptField extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;
  final String? label;
  final String? hint;
  final bool autofocus;

  const PromptField({
    super.key,
    required this.initialText,
    required this.onChanged,
    this.label,
    this.hint,
    this.autofocus = true,
  });

  @override
  State<PromptField> createState() => _PromptFieldState();
}

class _PromptFieldState extends State<PromptField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
      ),
    );
  }
}
