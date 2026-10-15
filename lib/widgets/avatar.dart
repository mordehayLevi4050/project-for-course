import 'package:flutter/material.dart';

/// A circle with the first letter of a name, colored consistently per name.
class NameAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const NameAvatar({super.key, required this.name, this.radius = 22});

  static const _palette = [
    Color(0xFF00B9C6),
    Color(0xFF1DD3B0),
    Color(0xFF00838F),
    Color(0xFF5C6BC0),
    Color(0xFFFF8A65),
    Color(0xFFAB47BC),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final color = _palette[trimmed.hashCode.abs() % _palette.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        trimmed.isEmpty ? '?' : trimmed.characters.first,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
