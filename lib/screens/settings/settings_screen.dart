import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
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
  ShoppingReminder _reminder = const ShoppingReminder();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notifService = NotificationService();
    final reminder = await notifService.getShoppingReminder();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _reminder = reminder;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

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
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleDarkMode(value),
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),
          const _SectionHeader(title: 'Recordatorio de Compras'),
          SwitchListTile(
            title: const Text('Recordatorio semanal'),
            subtitle: Text(_reminder.enabled
                ? '${_reminder.dayName} a las ${_reminder.timeString}'
                : 'Recibir un aviso semanal para hacer compras'),
            value: _reminder.enabled,
            onChanged: _notificationsEnabled
                ? (value) => _updateReminder(
                    ShoppingReminder(
                      enabled: value,
                      dayOfWeek: _reminder.dayOfWeek,
                      hour: _reminder.hour,
                      minute: _reminder.minute,
                    ),
                  )
                : null,
            secondary: const Icon(Icons.alarm),
          ),
          if (_reminder.enabled) ...[
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('Dia de la semana'),
              trailing: DropdownButton<int>(
                value: _reminder.dayOfWeek,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Lunes')),
                  DropdownMenuItem(value: 2, child: Text('Martes')),
                  DropdownMenuItem(value: 3, child: Text('Miercoles')),
                  DropdownMenuItem(value: 4, child: Text('Jueves')),
                  DropdownMenuItem(value: 5, child: Text('Viernes')),
                  DropdownMenuItem(value: 6, child: Text('Sabado')),
                  DropdownMenuItem(value: 7, child: Text('Domingo')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateReminder(ShoppingReminder(
                      enabled: true,
                      dayOfWeek: value,
                      hour: _reminder.hour,
                      minute: _reminder.minute,
                    ));
                  }
                },
              ),
            ),
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('Hora'),
              trailing: TextButton(
                onPressed: () => _pickTime(context),
                child: Text(
                  _reminder.timeString,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
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

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder.timeOfDay,
    );
    if (picked != null) {
      _updateReminder(ShoppingReminder(
        enabled: true,
        dayOfWeek: _reminder.dayOfWeek,
        hour: picked.hour,
        minute: picked.minute,
      ));
    }
  }

  Future<void> _updateReminder(ShoppingReminder reminder) async {
    final notifService = NotificationService();
    await notifService.saveShoppingReminder(reminder);
    setState(() => _reminder = reminder);
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
