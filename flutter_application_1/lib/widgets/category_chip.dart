import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const CategoryChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(text),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: Theme.of(context).colorScheme.primary,
    checkmarkColor: Colors.white,
    labelStyle: TextStyle(
      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
