import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:safy/report/data/datasources/report_data_source.dart';
import 'package:safy/report/data/repositories/report_repository_impl.dart';
import 'package:safy/report/domain/repositories/report_repository.dart';
import 'package:safy/report/domain/usecases/get_report.dart';
import 'package:safy/report/domain/usecases/get_reports_use_case.dart';
import 'package:safy/report/domain/usecases/post_report.dart';
import 'package:safy/report/presentation/viewmodels/create_report_viewmodel.dart';
import 'package:safy/report/presentation/viewmodels/get_report_viewmodel.dart';
import 'package:safy/report/presentation/viewmodels/my_get_reports_viewmodel.dart';

final sl = GetIt.instance;

Future<void> setupReportDependencies() async {
  // 📡 Data Source
  sl.registerLazySingleton<ReportApiClient>(
    () => ReportApiClient(sl<Dio>(instanceName: 'authenticated')),
  );

  // 🧠 Repositorio
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(sl<ReportApiClient>()),
  );

  // ✅ Use Cases
  sl.registerLazySingleton<PostReport>(
    () => PostReport(sl<ReportRepository>()),
  );

  sl.registerLazySingleton<GetReportUseCase>(
    () => GetReportUseCase(sl<ReportRepository>()),
  );

  // 🚀 ✅ AGREGAR ESTA LÍNEA QUE FALTA:
  sl.registerFactory<CreateReportViewModel>(
    () => CreateReportViewModel(sl<PostReport>()),
  );

  // 🚨 AÑADE ESTA LÍNEA:
  sl.registerFactory<GetReportsViewModel>(
    () => GetReportsViewModel(sl<GetReportsUseCase>()),
  );
  sl.registerFactory<GetReportViewModel>(
    () => GetReportViewModel(sl<GetReportUseCase>()),
  );

  print('[ReportDI] ✅ Dependencias de Reporte registradas');
}
