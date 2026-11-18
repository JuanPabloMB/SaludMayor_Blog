import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'core/api_client.dart';
import 'core/api_exception.dart';
import 'services/connection_service.dart';

void main() => runApp(const LoginApp());

/// Pantalla temporal hasta integrar la autenticación real.
class LoginApp extends StatelessWidget {
  const LoginApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SaludMayor Blog',
    theme: AppTheme.light,
    home: Scaffold(
      appBar: AppBar(title: const Text('SaludMayor Blog')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Salud, bienestar y cuidados',
                  style: AppTheme.light.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Información para el cuidado del adulto mayor.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const ConnectionPanel(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Diagnóstico temporal, sin habilitar las rutas privadas antiguas.
class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({super.key});
  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  final _api = ApiClient();
  bool _loading = false;
  String _status = 'Conexión pendiente de comprobar';

  Future<void> _check() async {
    setState(() => _loading = true);
    String result;
    try {
      result = 'Conexión exitosa: ${await ConnectionService(_api).check()}';
    } on ApiException catch (error) {
      result = error.message;
    } catch (_) {
      result = 'No fue posible comprobar la conexión.';
    }
    if (!mounted) return;
    setState(() {
      _status = result;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ElevatedButton(
        onPressed: _loading ? null : _check,
        child: Text(_loading ? 'Comprobando...' : 'Comprobar conexión'),
      ),
      const SizedBox(height: 12),
      Semantics(
        liveRegion: true,
        child: Text(_status, textAlign: TextAlign.center),
      ),
    ],
  );
}
