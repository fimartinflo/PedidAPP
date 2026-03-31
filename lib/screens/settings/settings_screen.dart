import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../categories/categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'General'),
          SwitchListTile(
            title: const Text('Notificaciones'),
            subtitle: const Text('Alertas de stock bajo y recordatorios'),
            value: _notificationsEnabled,
            onChanged: (value) async {
              final notifService = NotificationService();
              await notifService.setNotificationsEnabled(value);
              setState(() => _notificationsEnabled = value);
            },
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: const Text('Modo oscuro'),
            subtitle: const Text('Tema oscuro para la aplicacion'),
            value: _darkMode,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('dark_mode', value);
              setState(() => _darkMode = value);
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),
          const _SectionHeader(title: 'Datos'),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Gestionar Categorias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CategoriesScreen()),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: 'Acerca de'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text(AppConstants.appName),
            subtitle: Text('Version ${AppConstants.appVersion}'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Descripcion'),
            subtitle: const Text(AppConstants.appDescription),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
