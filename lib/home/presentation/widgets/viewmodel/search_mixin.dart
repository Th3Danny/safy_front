import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:safy/home/domain/entities/place.dart';
import 'package:safy/home/domain/entities/location.dart';
import 'package:safy/home/domain/usecases/search_places_use_case.dart';
import 'package:safy/home/presentation/viewmodels/map_view_model.dart';

/// Mixin para gestión de búsquedas de lugares
mixin SearchMixin on ChangeNotifier {
  // Propiedades para búsqueda
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  List<Place> _searchResults = [];
  List<Place> get searchResults => _searchResults;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Place? _selectedDestination;
  Place? get selectedDestination => _selectedDestination;

  // Dependencias abstractas
  SearchPlacesUseCase? get searchPlacesUseCase;

  // Métodos para búsqueda
  Future<void> searchPlaces(String query, LatLng currentLocation) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    notifyListeners();

    try {
      if (searchPlacesUseCase != null) {
        final currentLoc = Location(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
        );

        _searchResults = await searchPlacesUseCase!.execute(
          query,
          nearLocation: currentLoc,
          limit: 8,
        );
      } else {
        _searchResults = [];
      }
      onSearchSuccess();
    } catch (e) {
      onSearchError('Error buscando lugares: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults.clear();
    _searchQuery = '';
    _selectedDestination = null;
    onSearchCleared();
    notifyListeners();
  }

  void selectPlace(Place place, LatLng currentLocation) {
    _selectedDestination = place;
    final placeLatLng = LatLng(place.latitude, place.longitude);

    // 🆕 NUEVO: Cargar predicciones automáticamente cuando se selecciona un lugar
    if (this is MapViewModel) {
      final mapViewModel = this as MapViewModel;
      print(
        '[SearchMixin] 🔮 Cargando predicciones para lugar seleccionado: ${place.displayName}',
      );
      mapViewModel.loadPredictionsForDestination(placeLatLng);
    }

    onPlaceSelected(place, placeLatLng, currentLocation);
    notifyListeners();
  }

  // Callbacks abstractos
  void onSearchSuccess();
  void onSearchError(String error);
  void onSearchCleared();
  void onPlaceSelected(
    Place place,
    LatLng placeLocation,
    LatLng currentLocation,
  );
}
