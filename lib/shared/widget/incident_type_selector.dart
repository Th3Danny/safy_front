import 'package:flutter/material.dart';

class IncidentTypeSelector extends StatelessWidget {
  final String? selectedIncident;
  final List<Map<String, dynamic>> incidentTypes;
  final ValueChanged<String> onIncidentSelected;

  const IncidentTypeSelector({
    super.key,
    required this.selectedIncident,
    required this.incidentTypes,
    required this.onIncidentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incidente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...incidentTypes.map((incident) => _IncidentOption(
          incident: incident,
          isSelected: selectedIncident == incident['name'],
          onTap: () => onIncidentSelected(incident['name']),
        )),
      ],
    );
  }
}

class _IncidentOption extends StatelessWidget {
  final Map<String, dynamic> incident;
  final bool isSelected;
  final VoidCallback onTap;

  const _IncidentOption({
    required this.incident,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Icon(
                incident['icon'],
                color: incident['color'],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                incident['name'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}