import 'dart:typed_data';

import 'package:flutter/material.dart';

class BlogIdentity extends InheritedWidget {
  const BlogIdentity({
    super.key,
    required super.child,
    required this.name,
    required this.logo,
    required this.refresh,
  });
  final String name;
  final Uint8List? logo;
  final Future<void> Function() refresh;
  static BlogIdentity? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BlogIdentity>();
  static String nameOf(BuildContext context) =>
      of(context)?.name ?? 'SaludMayor Blog';
  @override
  bool updateShouldNotify(BlogIdentity oldWidget) =>
      name != oldWidget.name || logo != oldWidget.logo;
}

class BlogLogo extends StatelessWidget {
  const BlogLogo({super.key, this.size = 48, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final bytes = BlogIdentity.of(context)?.logo;
    final fallback = Icon(
      Icons.volunteer_activism,
      size: size,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
    return bytes == null
        ? fallback
        : Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.contain,
            semanticLabel: 'Logotipo del blog',
            errorBuilder: (context, error, stack) => fallback,
          );
  }
}
