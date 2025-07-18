import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';
import 'package:safy/core/session/session_manager.dart';
import 'package:safy/shared/widget/settings_section.dart';
import 'package:safy/shared/widget/settings_tile.dart';

class SettingsList extends StatefulWidget {
  const SettingsList({super.key});

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  bool _isLoggingOut = false;

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
                print('Navigate to Notifications');
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
                print('Navigate to Help');
              },
            ),
            SettingsTile(
              title: 'Terms and Policies',
              icon: Icons.description,
              onTap: () {
                print('Navigate to Terms');
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
              content: _isLoggingOut
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cerrando sesión...'),
                      ],
                    )
                  : const Text('¿Estás seguro que quieres cerrar sesión?'),
              actions: _isLoggingOut
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
                          //  CORRECCIÓN: Actualizar ambos estados
                          setState(() {
                            _isLoggingOut = true;
                          });
                          setDialogState(() {
                            _isLoggingOut = true;
                          });
                          
                          await _performSimpleLogout(dialogContext);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _performSimpleLogout(BuildContext dialogContext) async {
    try {
      print('[SettingsList]  Iniciando logout simple...');
      
      // Limpiar sesión directamente
      await SessionManager.instance.clearSession();
      
      print('[SettingsList]  Logout simple exitoso');
      
      // Pequeña pausa para que se vea el loading
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Cerrar diálogo
      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
      
      // Navegar al login
      if (mounted) {
        context.go(AppRoutesConstant.login);
      }
      
    } catch (e) {
      print('[SettingsList]  Error en logout simple: $e');
      
      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
      
      if (mounted) {
        _showErrorDialog('Error al cerrar sesión. Intenta nuevamente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
