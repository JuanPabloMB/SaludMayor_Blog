import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/json_model.dart';
import '../models/user_model.dart';
import '../services/admin_dashboard_service.dart';
import '../theme/app_colors.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.api,
    required this.user,
    required this.onSelect,
  });
  final ApiClient api;
  final UserModel user;
  final ValueChanged<int> onSelect;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<Map<String, dynamic>> _resumen;

  @override
  void initState() {
    super.initState();
    _resumen = AdminDashboardService(widget.api).resumen();
  }

  void _actualizar() {
    setState(() {
      _resumen = AdminDashboardService(widget.api).resumen();
    });
  }

  Widget _metrica(String titulo, int valor, IconData icono) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: AppColors.primary),
            const SizedBox(height: 8),
            Text('$valor', style: Theme.of(context).textTheme.headlineMedium),
            Text(titulo),
          ],
        ),
      ),
    );
  }

  Widget _contenido(Map<String, dynamic> datos) {
    int total(String clave) => datos[clave] as int;
    final categorias = jsonList(datos['distribucion'], (item) => item);
    final recientes = jsonList(datos['recientes'], (item) => item);
    final publicaciones = total('publicaciones');
    final metricas = [
      _metrica(
        'Usuarios registrados',
        total('usuarios_activos') + total('usuarios_inactivos'),
        Icons.people_outline,
      ),
      _metrica(
        'Usuarios activos',
        total('usuarios_activos'),
        Icons.person_outline,
      ),
      _metrica(
        'Usuarios inactivos',
        total('usuarios_inactivos'),
        Icons.person_off_outlined,
      ),
      _metrica('Publicaciones', publicaciones, Icons.article_outlined),
      _metrica(
        'Categorías activas',
        total('categorias_activas'),
        Icons.category_outlined,
      ),
      _metrica(
        'Categorías inactivas',
        total('categorias_inactivas'),
        Icons.folder_outlined,
      ),
      _metrica(
        'Comentarios visibles',
        total('comentarios'),
        Icons.comment_outlined,
      ),
      _metrica('Valoraciones', total('valoraciones'), Icons.star_outline),
      _metrica(
        'Reacciones visibles',
        total('reacciones'),
        Icons.favorite_border,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final escala = MediaQuery.textScalerOf(context).scale(16) / 16;
            final anchoDisponible = constraints.maxWidth / escala;
            final columnas = anchoDisponible >= 850
                ? 3
                : anchoDisponible >= 420
                ? 2
                : 1;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metrica in metricas)
                  SizedBox(
                    width:
                        (constraints.maxWidth - 8 * (columnas - 1)) / columnas,
                    child: metrica,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Publicaciones por categoría',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (categorias.isEmpty) const Text('No hay categorías registradas.'),
        for (final categoria in categorias)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${categoria['nombre']}${categoria['estado'] == true ? '' : ' (inactiva)'}: ${categoria['total']}',
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: publicaciones == 0
                      ? 0.0
                      : ((categoria['total'] as int) / publicaciones)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                  color: AppColors.primary,
                  backgroundColor: AppColors.success,
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Publicaciones recientes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (recientes.isEmpty) const Text('No hay publicaciones registradas.'),
        for (final post in recientes)
          Card(
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(post['titulo'] as String),
              subtitle: Text(
                '${post['categoria']} · ${MaterialLocalizations.of(context).formatCompactDate(apiDate(post['fecha_publicacion'] as String).toLocal())}',
              ),
            ),
          ),
        TextButton(
          onPressed: () => widget.onSelect(1),
          child: const Text('Ver publicaciones'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Panel administrativo',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text('Bienvenido, ${widget.user.nombreCompleto}.'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (indice, nombre, icono)
                          in <(int, String, IconData)>[
                            (1, 'Publicaciones', Icons.article_outlined),
                            (2, 'Usuarios', Icons.people_outline),
                            (3, 'Categorías', Icons.category_outlined),
                            (4, 'Configuración', Icons.settings_outlined),
                            (5, 'Mensajes', Icons.chat_bubble_outline),
                            (6, 'Mi perfil', Icons.person_outline),
                          ])
                        OutlinedButton.icon(
                          onPressed: () => widget.onSelect(indice),
                          icon: Icon(icono),
                          label: Text(nombre),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _resumen,
                    builder: (context, snapshot) {
                      final cargando =
                          snapshot.connectionState != ConnectionState.done;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: cargando ? null : _actualizar,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar estadísticas'),
                          ),
                          const SizedBox(height: 12),
                          if (cargando)
                            const Center(child: CircularProgressIndicator())
                          else if (snapshot.hasError || !snapshot.hasData)
                            const Text(
                              'No se pudieron consultar las estadísticas. Comprueba la conexión e inténtalo nuevamente.',
                              style: TextStyle(color: AppColors.errorText),
                            )
                          else
                            _contenido(snapshot.data!),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
