import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/shared/widget/settings_section.dart';
import 'package:safy/shared/widget/settings_tile.dart';
import 'package:safy/core/services/background_danger_detection_service.dart';

class SettingsList extends StatefulWidget {
  const SettingsList({super.key});

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  bool _isLoggingOut = false;
  bool _isBackgroundServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkBackgroundServiceStatus();
  }

  void _checkBackgroundServiceStatus() {
    setState(() {
      _isBackgroundServiceRunning = BackgroundDangerDetectionService.isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sección Account
        SettingsSection(
          title: 'Account',
          children: [
            SettingsTile(
              title: 'Edit Profil',
              icon: Icons.account_circle,
              onTap: () {
                context.go(AppRoutesConstant.editProfile);
              },
            ),
            SettingsTile(
              title: 'Notificaciones',
              icon: Icons.notifications,
              onTap: () {
                // Navigate to Notifications
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 🚨 NUEVA SECCIÓN: Servicio de Detección de Peligro
        SettingsSection(
          title: 'Seguridad',
          children: [
            SettingsTile(
              title:
                  _isBackgroundServiceRunning
                      ? 'Detección Activa - Monitoreando zonas'
                      : 'Detección Inactiva - Activar monitoreo',
              icon: Icons.security,
              iconColor:
                  _isBackgroundServiceRunning ? Colors.green : Colors.grey,
              onTap: () {
                _toggleBackgroundService();
              },
            ),
            SettingsTile(
              title: 'Configurar Radio de Detección',
              icon: Icons.radar,
              onTap: () {
                _showDetectionRadiusDialog(context);
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Sección Support & About
        SettingsSection(
          title: 'Support & About',
          children: [
            SettingsTile(
              title: 'Help and support',
              icon: Icons.help_outline,
              onTap: () {
                // Navigate to Help
              },
            ),
            SettingsTile(
              title: 'Terms and Policies',
              icon: Icons.description,
              onTap: () {
                // Navigate to Terms
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Sección Actions
        SettingsSection(
          title: 'Actions',
          children: [
            SettingsTile(
              title: 'Log out',
              icon: Icons.logout,
              textColor: Colors.red,
              iconColor: Colors.red,
              // 🔧 CORRECCIÓN: No pasar null, manejar dentro de la función
              onTap: () {
                if (!_isLoggingOut) {
                  _showLogoutDialog(context);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cerrar Sesión'),
              content:
                  _isLoggingOut
                      ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cerrando sesión...'),
                        ],
                      )
                      : const Text(
                        '¿Estás seguro de que quieres cerrar sesión?',
                      ),
              actions:
                  _isLoggingOut
                      ? []
                      : [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () async {
                            setDialogState(() {
                              _isLoggingOut = true;
                            });

                            try {
                              await SessionManager.instance.clearSession();
                              if (mounted) {
                                Navigator.of(dialogContext).pop();
                                context.go(AppRoutesConstant.login);
                              }
                            } catch (e) {
                              setDialogState(() {
                                _isLoggingOut = false;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al cerrar sesión: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Cerrar Sesión'),
                        ),
                      ],
            );
          },
        );
      },
    );
  }

  // 🚨 NUEVO: Método para alternar el servicio de detección de peligro
  void _toggleBackgroundService() async {
    try {
      if (_isBackgroundServiceRunning) {
        await BackgroundDangerDetectionService.stopMonitoring();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio de detección detenido'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await BackgroundDangerDetectionService.startMonitoring();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio de detección iniciado'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _checkBackgroundServiceStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 🚨 NUEVO: Método para mostrar diálogo de configuración de radio
  void _showDetectionRadiusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Configurar Radio de Detección'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('El radio de detección se ajusta automáticamente según:'),
              SizedBox(height: 8),
              Text('• Severidad del peligro'),
              Text('• Cantidad de reportes'),
              Text('• Distancia al cluster'),
              SizedBox(height: 16),
              Text('Radio base: 100m'),
              Text('Máximo: 200m'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
}
