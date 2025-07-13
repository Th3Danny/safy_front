import 'package:flutter/foundation.dart';
import 'package:safy/report/domain/entities/report.dart';
import 'package:safy/report/domain/exceptions/report_exceptions.dart';
import 'package:safy/report/domain/usecases/get_report.dart';


class GetReportViewModel extends ChangeNotifier {
  final GetReportUseCase _getReportUseCase;

  GetReportViewModel(this._getReportUseCase);

  ReportInfoEntity? _report;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  ReportInfoEntity? get report => _report;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> loadReport(String reportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _getReportUseCase.execute(reportId);
    } on ReportExceptions catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _report = null;
    _errorMessage = null;
    notifyListeners();
  }
}
