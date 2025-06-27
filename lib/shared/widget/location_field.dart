import 'package:flutter/material.dart';

class LocationField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onLocationSelected;

  const LocationField({
    super.key,
    required this.controller,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(
                Icons.add,
                color: Color(0xFF2196F3),
                size: 20,
              ),
              onPressed: () {
                // TODO: Abrir selector de ubicación
                controller.text = 'Tuxtla Gutiérrez';
                onLocationSelected('Tuxtla Gutiérrez');
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            controller.text.isEmpty ? 'Tuxtla Gutiérrez' : controller.text,
            style: TextStyle(
              fontSize: 14,
              color: controller.text.isEmpty ? Colors.grey[500] : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}