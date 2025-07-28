import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';
import 'dart:async'; // Added for Timer

class PlaceSearchWidget extends StatefulWidget {
  const PlaceSearchWidget({super.key});

  @override
  State<PlaceSearchWidget> createState() => _PlaceSearchWidgetState();
}

class _PlaceSearchWidgetState extends State<PlaceSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _showResults = false;
  Timer? _debounceTimer; // Added for debounce

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel(); // Cancel debounce timer on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        return Column(
          children: [
            // Campo de búsqueda mejorado
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar lugar, dirección...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              mapViewModel.clearSearch();
                              setState(() {
                                _showResults = false;
                              });
                            },
                            icon: const Icon(Icons.clear, color: Colors.grey),
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _showResults = value.isNotEmpty;
                  });

                  // 🆕 DEBOUNCE PARA EVITAR MUCHAS PETICIONES
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    if (value.length >= 3) {
                      print('🔍 [PlaceSearchWidget] Buscando: $value');
                      mapViewModel.searchPlaces(
                        value.trim(),
                        mapViewModel.currentLocation,
                      );
                    } else if (value.isEmpty) {
                      mapViewModel.clearSearch();
                    }
                  });
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    print('🔍 [PlaceSearchWidget] Búsqueda enviada: $value');
                    mapViewModel.searchPlaces(
                      value.trim(),
                      mapViewModel.currentLocation,
                    );
                  }
                },
              ),
            ),

            // Resultados de búsqueda mejorados
            if (_showResults && mapViewModel.searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: mapViewModel.searchResults.length,
                  separatorBuilder:
                      (context, index) =>
                          Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final place = mapViewModel.searchResults[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getPlaceIcon(place.type),
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        place.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle:
                          place.address != null
                              ? Text(
                                place.address!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                              : Text(
                                '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      onTap: () {
                        print(
                          '🎯 [PlaceSearchWidget] Lugar seleccionado: ${place.displayName}',
                        );

                        // 🎯 NUEVO: Establecer automáticamente la posición actual como punto de inicio
                        mapViewModel.setCurrentLocationAsStart();

                        // Seleccionar lugar y calcular ruta automáticamente
                        mapViewModel.selectPlace(
                          place,
                          mapViewModel.currentLocation,
                        );

                        _searchController.text = place.displayName;
                        setState(() {
                          _showResults = false;
                        });

                        // Mostrar SnackBar de confirmación mejorado
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Ruta calculada',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Desde tu ubicación a: ${place.displayName}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            // Indicador de carga mejorado
            if (mapViewModel.isSearching)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[400]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Buscando lugares...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),

            // Mensaje cuando no hay resultados
            if (_showResults &&
                !mapViewModel.isSearching &&
                mapViewModel.searchResults.isEmpty &&
                _searchController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No se encontraron lugares para "${_searchController.text}"',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // 🆕 MÉTODO PARA OBTENER ICONO SEGÚN TIPO DE LUGAR
  IconData _getPlaceIcon(String? placeType) {
    switch (placeType) {
      case 'poi':
        return Icons.place;
      case 'address':
        return Icons.home;
      case 'neighborhood':
        return Icons.location_city;
      case 'place':
        return Icons.location_on;
      default:
        return Icons.place;
    }
  }
}
