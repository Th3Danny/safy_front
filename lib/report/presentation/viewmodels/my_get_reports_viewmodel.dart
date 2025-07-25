import 'package:flutter/foundation.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/exceptions/report_exceptions.dart';
import 'package:safy/report/domain/usecases/get_reports_use_case.dart';
// ❌ QUITAR: import 'package:geolocator/geolocator.dart';

class GetReportsViewModel extends ChangeNotifier {
  final GetReportsUseCase _getReportsUseCase;

  GetReportsViewModel(this._getReportsUseCase);

  List<ReportInfoEntity> _reports = [];
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  List<ReportInfoEntity> get reports => _reports;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;

  // ✅ CORREGIDO: SIN coordenadas para MIS reportes
  Future<void> loadReports({
    required String userId,
    int? page,
    int? pageSize,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // ✅ SIN coordenadas = obtener MIS reportes
      _reports = await _getReportsUseCase.execute(
        userId: userId,
        page: page,
        pageSize: pageSize,
        // ✅ NO pasar latitude/longitude para obtener MIS reportes
      );
            
      print('[GetReportsViewModel] MIS reportes cargados: ${_reports.length}');
    } on ReportExceptions catch (e) {
      _setError(e.message);
      print('[GetReportsViewModel] Error de dominio: ${e.message}');
    } catch (e) {
      _setError('Ocurrió un error inesperado al cargar mis reportes.');
      print('[GetReportsViewModel] Error inesperado: $e');
    } finally {
      _setLoading(false);
    }
  }

  void clear() {
    _reports = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}