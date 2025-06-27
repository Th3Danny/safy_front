import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/auth/presentation/pages/login/widgets/custom_button.dart';
import 'package:safy/shared/widget/custom_text_field.dart';

import 'package:safy/shared/widget/incident_type_selector.dart';
import 'package:safy/shared/widget/location_field.dart';


class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedIncident;

  final List<Map<String, dynamic>> _incidentTypes = [
    {'name': 'Acoso callejero', 'icon': Icons.report_problem, 'color': Colors.orange},
    {'name': 'Asaltos / Robos', 'icon': Icons.security, 'color': Colors.red},
    {'name': 'Secuestro', 'icon': Icons.warning_amber, 'color': Colors.red[700]},
    {'name': 'Pandillas o peleas', 'icon': Icons.groups, 'color': Colors.purple},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Campo Nombre
          CustomTextField(
            controller: _nameController,
            label: 'Nombre',
            hint: 'Urgente al Nombre al incidente',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Campo Ubicación
          LocationField(
            controller: _locationController,
            onLocationSelected: (location) {
              // Manejar selección de ubicación
              print('Location selected: $location');
            },
          ),
          
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
          
          // Campo Descripción
          CustomTextField(
            controller: _descriptionController,
            label: 'Descripción',
            hint: 'Describe el incidente',
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Description is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 32),
          
          // Botón Enviar
          CustomButton(
            text: 'Enviar',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_selectedIncident == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select an incident type'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                _handleSubmitReport();
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleSubmitReport() {
    final reportData = {
      'name': _nameController.text,
      'location': _locationController.text,
      'incident': _selectedIncident,
      'description': _descriptionController.text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    print('Report Data: $reportData');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Regresar después de enviar
    context.pop();
  }
}