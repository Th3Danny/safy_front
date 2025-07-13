import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onLocationSelected;

  const LocationField({
    super.key,
    required this.controller,
    required this.onLocationSelected,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  bool _isLoading = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Servicio de ubicación desactivado';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permiso denegado';
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Permiso de ubicación denegado permanentemente';
      }

      Position position = await Geolocator.getCurrentPosition();
      final location = '${position.latitude}, ${position.longitude}';

      widget.controller.text = location;
      widget.onLocationSelected(location);
    } catch (e) {
      print('❌ Error al obtener ubicación: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al obtener ubicación: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationText = widget.controller.text.isEmpty
        ? 'Haz clic en + para obtener ubicación'
        : widget.controller.text;

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
            IconButton(
              icon: _isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.add, color: Color(0xFF2196F3), size: 20),
              onPressed: _isLoading ? null : _getCurrentLocation,
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
            locationText,
            style: TextStyle(
              fontSize: 14,
              color: widget.controller.text.isEmpty ? Colors.grey : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

