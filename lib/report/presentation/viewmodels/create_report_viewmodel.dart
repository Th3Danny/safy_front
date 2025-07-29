import 'package:flutter/foundation.dart';
import 'package:safy/report/domain/usecases/post_report.dart';
import 'package:safy/report/domain/exceptions/report_exceptions.dart';
import 'package:safy/report/domain/value_objects/incident_type.dart';

class CreateReportViewModel extends ChangeNotifier {
  final PostReport _postReportUseCase;

  CreateReportViewModel(this._postReportUseCase);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Estado del formulario
  String _title = '';
  String _description = '';
  String _reporterName = '';
  String? _reporterEmail;
  String? _address;
  double _latitude = 0.0;
  double _longitude = 0.0;
  //DateTime _dateTime = DateTime.now();
  IncidentType _incidentType = IncidentType.streetHarassment;
  int _severity = 1;
  bool _isAnonymous = false;

  // Getters para los campos del formulario
  String get title => _title;
  String get description => _description;
  String get reporterName => _reporterName;
  String? get reporterEmail => _reporterEmail;
  String? get address => _address;
  double get latitude => _latitude;
  double get longitude => _longitude;
  //DateTime get dateTime => _dateTime;
  IncidentType get incidentType => _incidentType;
  int get severity => _severity;
  bool get isAnonymous => _isAnonymous;

  Future<void> createReport({
    required String title,
    required String description,
    required String reporterName,
    String? reporterEmail,
    required double latitude,
    required double longitude,
    String? address,
    //required DateTime dateTime,
    required IncidentType incidentType,
    required int severity,
    required bool isAnonymous,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _postReportUseCase.execute(
        title: title,
        description: description,
        reporterName: reporterName,
        reporterEmail: reporterEmail,
        latitude: latitude,
        longitude: longitude,
        address: address,
        //dateTime: dateTime,
        incident_type: incidentType.name,
        severity: severity,
        isAnonymous: isAnonymous,
      );
      _errorMessage = null; // 👈 Asegurar que no hay error
    } on ReportValidationException catch (e) {
      _errorMessage =
          'Errores de validación: ${e.fieldErrors.values.expand((x) => x).join(', ')}';
    } on ReportExceptions catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error inesperado: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para actualizar el estado del formulario
  void updateTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void updateDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void updateReporterName(String value) {
    _reporterName = value;
    notifyListeners();
  }

  void updateReporterEmail(String? value) {
    _reporterEmail = value;
    notifyListeners();
  }

  void updateLocation(double lat, double lng, String? addr) {
    _latitude = lat;
    _longitude = lng;
    _address = addr;
    notifyListeners();
  }

  // void updateDateTime(DateTime value) {
  //   _dateTime = value;
  //   notifyListeners();
  // }

  void updateIncidentType(IncidentType value) {
    _incidentType = value;
    notifyListeners();
  }

  void updateSeverity(int value) {
    _severity = value;
    notifyListeners();
  }

  void updateIsAnonymous(bool value) {
    _isAnonymous = value;
    notifyListeners();
  }

  void clearForm() {
    _title = '';
    _description = '';
    _reporterName = '';
    _reporterEmail = null;
    _address = null;
    _latitude = 0.0;
    _longitude = 0.0;
    _incidentType = IncidentType.streetHarassment;
    _severity = 1;
    _isAnonymous = false;
    //_dateTime = DateTime.now();
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
