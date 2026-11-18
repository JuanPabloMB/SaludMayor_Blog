import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/primary_button.dart';
import 'publications_page.dart';

class RoleHomePage extends StatefulWidget {
  const RoleHomePage({
    super.key,
    required this.user,
    required this.auth,
    required this.onExit,
  });

  final UserModel user;
  final AuthService auth;
  final VoidCallback onExit;

  @override
  State<RoleHomePage> createState() => _RoleHomePageState();
}

class _RoleHomePageState extends State<RoleHomePage> {
  int _selectedIndex = 0;
  bool _closing = false;

  bool get _isAdmin => widget.user.esAdministrador;

  List<_NavigationItem> get _items => _isAdmin
      ? const [
          _NavigationItem('Inicio', Icons.home_outlined, Icons.home),
          _NavigationItem(
            'Publicaciones',
            Icons.article_outlined,
            Icons.article,
          ),
          _NavigationItem('Usuarios', Icons.people_outline, Icons.people),
          _NavigationItem(
            'Categorías',
            Icons.category_outlined,
            Icons.category,
          ),
          _NavigationItem(
            'Configuración',
            Icons.settings_outlined,
            Icons.settings,
          ),
        ]
      : const [
          _NavigationItem('Inicio', Icons.home_outlined, Icons.home),
          _NavigationItem(
            'Publicaciones',
            Icons.article_outlined,
            Icons.article,
          ),
          _NavigationItem('Mi perfil', Icons.person_outline, Icons.person),
          _NavigationItem(
            'Mensajes',
            Icons.chat_bubble_outline,
            Icons.chat_bubble,
          ),
        ];

  Future<void> _logout() async {
    if (_closing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar tu sesión de SaludMayor Blog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _closing = true);
    try {
      await widget.auth.logout();
      if (mounted) widget.onExit();
    } catch (_) {
      if (!mounted) return;
      setState(() => _closing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo cerrar la sesión. Comprueba tu conexión e inténtalo nuevamente.',
          ),
        ),
      );
    }
  }

  void _select(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() => _selectedIndex = index);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    final item = _items[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SaludMayor Blog'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                _isAdmin ? 'Administrador' : 'Usuario',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _closing ? null : _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: _NavigationMenu(
                  user: widget.user,
                  items: _items,
                  selectedIndex: _selectedIndex,
                  onSelected: _select,
                ),
              ),
            ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 270,
              child: _NavigationMenu(
                user: widget.user,
                items: _items,
                selectedIndex: _selectedIndex,
                onSelected: _select,
              ),
            ),
          Expanded(
            child: _PageContent(
              user: widget.user,
              auth: widget.auth,
              item: item,
              isAdmin: _isAdmin,
              closing: _closing,
              onSelect: _select,
              onLogout: _logout,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavigationMenu extends StatelessWidget {
  const _NavigationMenu({
    required this.user,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final UserModel user;
  final List<_NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: const Color(0xFFF5F3E8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF24563E),
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.volunteer_activism,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(height: 12),
                const Text(
                  'SaludMayor Blog',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.nombreCompleto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFE5EBDD)),
                ),
                Text(
                  user.esAdministrador ? 'Administrador' : 'Usuario',
                  style: const TextStyle(
                    color: Color(0xFFE5EBDD),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: ListTile(
                selected: selectedIndex == i,
                selectedTileColor: const Color(0xFFDCE9D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  selectedIndex == i ? items[i].selectedIcon : items[i].icon,
                  color: colors.primary,
                ),
                title: Text(items[i].label),
                onTap: () => onSelected(i),
              ),
            ),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Acceso ${user.esAdministrador ? 'administrativo' : 'personal'}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.user,
    required this.auth,
    required this.item,
    required this.isAdmin,
    required this.closing,
    required this.onSelect,
    required this.onLogout,
  });

  final UserModel user;
  final AuthService auth;
  final _NavigationItem item;
  final bool isAdmin;
  final bool closing;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    if (item.label == 'Publicaciones') {
      return PublicationsPage(api: auth.api, isAdmin: isAdmin);
    }
    return ColoredBox(
      color: const Color(0xFFF8F7F0),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.selectedIcon,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text('Bienvenido, ${user.nombreCompleto}.'),
                    const SizedBox(height: 8),
                    Text(
                      isAdmin
                          ? 'Has iniciado sesión con permisos de administrador. Desde este menú podrás acceder a las herramientas administrativas.'
                          : 'Desde este espacio podrás consultar las publicaciones y acceder a las funciones de tu cuenta.',
                    ),
                    const SizedBox(height: 24),
                    const _FeatureNotice(),
                    const SizedBox(height: 20),
                    if (isAdmin && item.label == 'Inicio')
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _QuickAction(
                            label: 'Publicaciones',
                            icon: Icons.article_outlined,
                            onTap: () => onSelect(1),
                          ),
                          _QuickAction(
                            label: 'Usuarios',
                            icon: Icons.people_outline,
                            onTap: () => onSelect(2),
                          ),
                          _QuickAction(
                            label: 'Categorías',
                            icon: Icons.category_outlined,
                            onTap: () => onSelect(3),
                          ),
                        ],
                      ),
                    if (!isAdmin && item.label == 'Inicio')
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _QuickAction(
                            label: 'Publicaciones',
                            icon: Icons.article_outlined,
                            onTap: () => onSelect(1),
                          ),
                          _QuickAction(
                            label: 'Mi perfil',
                            icon: Icons.person_outline,
                            onTap: () => onSelect(2),
                          ),
                          _QuickAction(
                            label: 'Mensajes',
                            icon: Icons.chat_bubble_outline,
                            onTap: () => onSelect(3),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 190,
                      child: PrimaryButton(
                        text: closing ? 'Cerrando sesión...' : 'Cerrar sesión',
                        onPressed: closing ? null : onLogout,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureNotice extends StatelessWidget {
  const _FeatureNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFE4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB7C9B5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF24563E)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'La navegación por roles ya está preparada. Las pantallas de cada módulo se conectarán en las siguientes fases.',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(label),
  );
}
