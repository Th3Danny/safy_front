import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

class PlaceSearchWidget extends StatefulWidget {
  const PlaceSearchWidget({super.key});

  @override
  State<PlaceSearchWidget> createState() => _PlaceSearchWidgetState();
}

class _PlaceSearchWidgetState extends State<PlaceSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _showResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        return Column(
          children: [
            // Campo de búsqueda
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar lugar...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            mapViewModel.clearSearch();
                            setState(() {
                              _showResults = false;
                            });
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _showResults = value.isNotEmpty;
                  });
                  if (value.length > 2) {
                    mapViewModel.searchPlaces(value);
                  } else {
                    mapViewModel.clearSearch();
                  }
                },
              ),
            ),
            
            // Resultados de búsqueda
            if (_showResults && mapViewModel.searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mapViewModel.searchResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = mapViewModel.searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.place),
                      title: Text(
                        place.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: place.address != null 
                          ? Text(
                              place.address!,
                              style: TextStyle(color: Colors.grey[600]),
                            )
                          : Text(
                              '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                      onTap: () {
                        // Seleccionar lugar y calcular ruta automáticamente
                        mapViewModel.selectPlace(place);
                        _searchController.text = place.displayName;
                        setState(() {
                          _showResults = false;
                        });
                        
                        // Mostrar SnackBar de confirmación
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.navigation, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Calculando ruta a: ${place.displayName}'),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            
            // Indicador de carga
            if (mapViewModel.isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              
            // Mostrar error si existe
            if (mapViewModel.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mapViewModel.errorMessage!,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                    IconButton(
                      onPressed: () => mapViewModel.clearError(),
                      icon: Icon(Icons.close, color: Colors.red[600]),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}