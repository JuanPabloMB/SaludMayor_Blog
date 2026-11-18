import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'publications_page.dart';

/// Pantalla de compatibilidad con la antigua ruta BlogPage.
///
/// Utiliza la implementación actual de publicaciones.
class BlogPage extends StatelessWidget {
  const BlogPage({super.key, required this.api, this.isAdmin = false});

  final ApiClient api;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SaludMayor Blog')),
      body: PublicationsPage(api: api, isAdmin: isAdmin),
    );
  }
}
