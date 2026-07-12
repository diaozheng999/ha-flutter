import 'package:flutter/material.dart';

/// A mutually-exclusive choice set. Selecting one option deselects the others.
/// Used for HVAC mode and purifier mode. Visuals derive from the shared
/// `ChipThemeData`. When [onSelect] is null the whole selector is disabled.
class ModeSelector<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final ValueChanged<T>? onSelect;
  final String Function(T) labelOf;
  final double spacing;
  final WrapAlignment alignment;

  const ModeSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.labelOf,
    this.spacing = 8,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: alignment,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(labelOf(option)),
            selected: option == selected,
            onSelected:
                onSelect == null ? null : (_) => onSelect!(option),
          ),
      ],
    );
  }
}

/// An independent binary option that toggles without affecting siblings. Used
/// for adaptive lighting and fan oscillation. Visuals derive from the shared
/// `ChipThemeData`. When [onToggle] is null the chip is disabled.
class OptionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final ValueChanged<bool>? onToggle;

  const OptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onToggle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: icon != null ? Icon(icon, size: 18) : null,
      label: Text(label),
      selected: selected,
      onSelected: onToggle,
    );
  }
}
