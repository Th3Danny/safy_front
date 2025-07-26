import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/shared/widget/custom_text_field.dart';
import 'package:safy/shared/widget/incident_type_selector.dart';
import 'package:safy/report/presentation/viewmodels/create_report_viewmodel.dart';
import 'package:safy/report/domain/value_objects/incident_type.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';

final sl = GetIt.instance;

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _reporterNameController = TextEditingController();
  final _reporterEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedIncident;
  bool _isLoadingLocation = false;
  bool _isAnonymous = false;
  int _severity = 1;
  double? _latitude;
  double? _longitude;

  final List<Map<String, dynamic>> _incidentTypes = [
    {
      'name': 'Acoso callejero',
      'icon': Icons.report_problem,
      'color': Colors.orange,
    },
    {'name': 'Asaltos / Robos', 'icon': Icons.security, 'color': Colors.red},
    {
      'name': 'Secuestro',
      'icon': Icons.warning_amber,
      'color': Colors.red[700],
    },
    {
      'name': 'Pandillas o peleas',
      'icon': Icons.groups,
      'color': Colors.purple,
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _reporterNameController.dispose();
    _reporterEmailController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreateReportViewModel>(
      create: (_) => sl<CreateReportViewModel>(),
      child: Consumer<CreateReportViewModel>(
        builder: (context, viewModel, child) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Campo Título
                CustomTextField(
                  controller: _titleController,
                  label: 'Título del Incidente',
                  hint: 'Ej: Asalto en la Av. Central',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título del incidente es requerido';
                    }
                    if (value.trim().length < 3) {
                      return 'El título debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Switch para reportes anónimos
                _buildAnonymousSwitch(),

                const SizedBox(height: 24),

                // Campos de reportero (solo si no es anónimo)
                if (!_isAnonymous) ...[
                  CustomTextField(
                    controller: _reporterNameController,
                    label: 'Tu Nombre',
                    hint: 'Nombre del reportero',
                    validator:
                        !_isAnonymous
                            ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es requerido';
                              }
                              return null;
                            }
                            : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _reporterEmailController,
                    label: 'Email (opcional)',
                    hint: 'tu@email.com',
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Email no válido';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Campo de ubicación
                _buildLocationField(),

                const SizedBox(height: 24),

                // Selector de tipo de incidente
                IncidentTypeSelector(
                  selectedIncident: _selectedIncident,
                  incidentTypes: _incidentTypes,
                  onIncidentSelected: (incident) {
                    setState(() {
                      _selectedIncident = incident;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Selector de severidad
                _buildSeveritySelector(),

                const SizedBox(height: 24),

                // Campo Descripción
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Descripción',
                  hint: 'Describe el incidente en detalle',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es requerida';
                    }
                    if (value.trim().length < 10) {
                      return 'La descripción debe tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Mostrar error si existe
                if (viewModel.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botón Enviar
                CustomButton(
                  text: viewModel.isLoading ? 'Enviando...' : 'Enviar Reporte',
                  onPressed:
                      viewModel.isLoading
                          ? null
                          : () {
                            if (_formKey.currentState!.validate()) {
                              if (_selectedIncident == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Por favor selecciona un tipo de incidente',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (_latitude == null || _longitude == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('La ubicación es requerida'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              _handleSubmitReport(viewModel);
                            }
                          },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnonymousSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_off, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reporte Anónimo',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Tu identidad se mantendrá privada',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (value) {
              setState(() {
                _isAnonymous = value;
                if (value) {
                  _reporterNameController.clear();
                  _reporterEmailController.clear();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Ubicación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    _isLoadingLocation
                        ? Colors.grey.shade200
                        : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _isLoadingLocation
                          ? Colors.grey.shade300
                          : Colors.blue.shade200,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _isLoadingLocation ? null : _getCurrentLocation,
                  child:
                      _isLoadingLocation
                          ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(
                            Icons.my_location,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Mostrar coordenadas si existen
        if (_latitude != null && _longitude != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coordenadas: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_addressController.text.isNotEmpty)
                  Text(
                    'Dirección: ${_addressController.text}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Toca el ícono para obtener ubicación actual',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),

        const SizedBox(height: 12),

        // Campo opcional de dirección
        CustomTextField(
          controller: _addressController,
          label: 'Dirección (opcional)',
          hint: 'Ej: Calle 5 de Mayo #123, Centro',
        ),
      ],
    );
  }

  Widget _buildSeveritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Nivel de Severidad',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = _severity == level;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _severity = level),
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.orange.shade100
                            : Colors.grey.shade100,
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.orange.shade400
                              : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    level.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected
                              ? Colors.orange.shade700
                              : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getSeverityText(_severity),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _getSeverityText(int severity) {
    switch (severity) {
      case 1:
        return 'Bajo - Situación menor';
      case 2:
        return 'Medio-Bajo - Requiere atención';
      case 3:
        return 'Medio - Situación preocupante';
      case 4:
        return 'Alto - Situación grave';
      case 5:
        return 'Crítico - Emergencia';
      default:
        return 'Desconocido';
    }
  }

  Future<void> _getCurrentLocation() async {
  if (_isLoadingLocation) return;

  setState(() => _isLoadingLocation = true);

  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Los servicios de ubicación están deshabilitados';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permisos de ubicación denegados';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Permisos de ubicación denegados permanentemente';
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    if (mounted) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        // Opcional: Si tienes una forma de obtener la dirección inversa (geocoding)
        // podrías asignarla aquí también a _addressController.text
      });

      // ¡IMPORTANTE! Actualiza el ViewModel con la ubicación
      Provider.of<CreateReportViewModel>(context, listen: false).updateLocation(
        position.latitude,
        position.longitude,
        _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación obtenida exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }
}

  void _handleSubmitReport(CreateReportViewModel viewModel) async {
    print('[ReportForm] 🚀 Iniciando creación de reporte...');

    try {
      await viewModel.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        reporterName:
            _isAnonymous ? 'Anónimo' : _reporterNameController.text.trim(),
        reporterEmail:
            _isAnonymous
                ? null
                : (_reporterEmailController.text.trim().isEmpty
                    ? null
                    : _reporterEmailController.text.trim()),
        latitude: _latitude!,
        longitude: _longitude!,
        address:
            _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
        //dateTime: DateTime.now(),
        incidentType: _mapIncidentStringToEnum(_selectedIncident!),
        severity: _severity,
        isAnonymous: _isAnonymous,
      );

      if (mounted) {
        print('[ReportForm] 🔍 Verificando resultado...');
        print('[ReportForm] Error message: ${viewModel.errorMessage}');
        print('[ReportForm] Is loading: ${viewModel.isLoading}');

        if (viewModel.errorMessage == null) {
          // ✅ ÉXITO
          print('[ReportForm] ✅ ¡Reporte creado exitosamente!');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('¡Reporte creado exitosamente!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );

          // Esperar un poco para que se vea el mensaje
          await Future.delayed(const Duration(milliseconds: 500));

          // Limpiar formulario
          viewModel.clearForm();
          _titleController.clear();
          _descriptionController.clear();
          _reporterNameController.clear();
          _reporterEmailController.clear();
          _addressController.clear();
          setState(() {
            _latitude = null;
            _longitude = null;
            _selectedIncident = null;
            _severity = 1;
            _isAnonymous = false;
          });

          // Navegar al home
          if (mounted) {
            context.go('/home');
          }
        } else {
          // ❌ ERROR
          print('[ReportForm] ❌ Error: ${viewModel.errorMessage}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('[ReportForm] 💥 Exception capturada: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  IncidentType _mapIncidentStringToEnum(String value) {
    switch (value) {
      case 'Acoso Callejero': // 👈 Cambié a 'Acoso Callejero' (con mayúscula)
        return IncidentType.streetHarassment;
      case 'Asaltos / Robos':
        return IncidentType
            .robberyAssault; // 👈 Cambié de 'thefts' a 'robberyAssault'
      case 'Secuestro':
        return IncidentType.kidnapping;
      case 'Pandillas o peleas':
        return IncidentType
            .gangViolence; // 👈 Cambié de 'gangsterism' a 'gangViolence'
      default:
        return IncidentType.streetHarassment;
    }
  }
}
