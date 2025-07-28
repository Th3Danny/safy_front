// lib/features/report/application/report_di.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

// Data layer
import 'package:safy/report/data/datasources/report_data_source.dart';
import 'package:safy/report/data/repositories/report_repository_impl.dart';

// Domain layer
import 'package:safy/report/domain/repositories/report_repository.dart';
import 'package:safy/report/domain/usecases/get_report_by_id.dart';
import 'package:safy/report/domain/usecases/get_reports_use_case.dart';
import 'package:safy/report/domain/usecases/get_reports_for_map_use_case.dart';
import 'package:safy/report/domain/usecases/get_clusters_use_case.dart';
import 'package:safy/report/domain/usecases/post_report.dart';
import 'package:safy/report/domain/usecases/get_address_from_coordinates_use_case.dart';
import 'package:safy/report/domain/usecases/correct_spelling_use_case.dart';
import 'package:safy/report/domain/usecases/suggest_title_use_case.dart';

// Presentation layer
import 'package:safy/report/presentation/viewmodels/create_report_viewmodel.dart';
import 'package:safy/report/presentation/viewmodels/get_report_viewmodel.dart';
import 'package:safy/report/presentation/viewmodels/my_get_reports_viewmodel.dart';

final sl = GetIt.instance;

Future<void> setupReportDependencies() async {
  print('[ReportDI] 🚀 Configurando dependencias de reportes...');

  try {
    // ========== DATA LAYER ==========
    
    // 📡 Data Source / API Client
    if (!sl.isRegistered<ReportApiClient>()) {
      sl.registerLazySingleton<ReportApiClient>(
        () => ReportApiClient(sl<Dio>(instanceName: 'authenticated')),
      );
      print('[ReportDI] ✅ ReportApiClient registrado');
    }

    // 🧠 Repository Implementation
    if (!sl.isRegistered<ReportRepository>()) {
      sl.registerLazySingleton<ReportRepository>(
        () => ReportRepositoryImpl(sl<ReportApiClient>()),
      );
      print('[ReportDI] ✅ ReportRepository registrado');
    }

    // ========== DOMAIN LAYER - USE CASES ==========
    
    // ✅ Use Cases - Reportes básicos
    if (!sl.isRegistered<PostReport>()) {
      sl.registerLazySingleton<PostReport>(
        () => PostReport(sl<ReportRepository>()),
      );
      print('[ReportDI] ✅ PostReport registrado');
    }

    if (!sl.isRegistered<GetReportUseCase>()) {
      sl.registerLazySingleton<GetReportUseCase>(
        () => GetReportUseCase(sl<ReportRepository>()),
      );
      print('[ReportDI] ✅ GetReportUseCase registrado');
    }

    if (!sl.isRegistered<GetReportsUseCase>()) {
      sl.registerLazySingleton<GetReportsUseCase>(
        () => GetReportsUseCase(sl<ReportRepository>()),
      );
      print('[ReportDI] ✅ GetReportsUseCase registrado');
    }

    // ✅ Use Cases - Para mapa (CRÍTICO PARA EL ERROR)
    if (!sl.isRegistered<GetReportsForMapUseCase>()) {
      sl.registerLazySingleton<GetReportsForMapUseCase>(
        () => GetReportsForMapUseCase(sl<ReportRepository>()),
      );
      print('[ReportDI] ✅ GetReportsForMapUseCase registrado');
    }

    // ✅ Use Cases - Clusters (NUEVO)
    if (!sl.isRegistered<GetClustersUseCase>()) {
      sl.registerLazySingleton<GetClustersUseCase>(
        () => GetClustersUseCase(sl<ReportRepository>()),
      );
      print('[ReportDI] ✅ GetClustersUseCase registrado');
    }

    // ✅ Use Cases - Servicios de ayuda para reportes
    if (!sl.isRegistered<GetAddressFromCoordinatesUseCase>()) {
      sl.registerLazySingleton<GetAddressFromCoordinatesUseCase>(
        () => GetAddressFromCoordinatesUseCase(sl<ReportRepository>()),
      );
      print('[ReportDI] ✅ GetAddressFromCoordinatesUseCase registrado');
    }

    if (!sl.isRegistered<CorrectSpellingUseCase>()) {
      sl.registerLazySingleton<CorrectSpellingUseCase>(
        () => CorrectSpellingUseCase(sl<ReportRepository>()),
      );
      print('[ReportDI] ✅ CorrectSpellingUseCase registrado');
    }

    if (!sl.isRegistered<SuggestTitleUseCase>()) {
      sl.registerLazySingleton<SuggestTitleUseCase>(
        () => SuggestTitleUseCase(sl<ReportRepository>()),
      );
      print('[ReportDI] ✅ SuggestTitleUseCase registrado');
    }

    // ========== PRESENTATION LAYER - VIEW MODELS ==========
    
    // 🚀 ViewModels
    if (!sl.isRegistered<CreateReportViewModel>()) {
      sl.registerFactory<CreateReportViewModel>(
        () => CreateReportViewModel(sl<PostReport>()),
      );
      print('[ReportDI] ✅ CreateReportViewModel registrado');
    }

    if (!sl.isRegistered<GetReportsViewModel>()) {
      sl.registerFactory<GetReportsViewModel>(
        () => GetReportsViewModel(sl<GetReportsUseCase>()),
      );
      print('[ReportDI] ✅ GetReportsViewModel registrado');
    }

    if (!sl.isRegistered<GetReportViewModel>()) {
      sl.registerFactory<GetReportViewModel>(
        () => GetReportViewModel(sl<GetReportUseCase>()),
      );
      print('[ReportDI] ✅ GetReportViewModel registrado');
    }

    print('[ReportDI] ✅ Dependencias de reportes y clusters registradas exitosamente');
    
    // Verificar que todas las dependencias críticas estén disponibles
    _verifyReportDependencies();
    
  } catch (e) {
    print('[ReportDI] ❌ Error configurando dependencias: $e');
    rethrow;
  }
}

void _verifyReportDependencies() {
  print('[ReportDI] 🔍 Verificando dependencias críticas...');
  
  final criticalDependencies = [
    'ReportApiClient',
    'ReportRepository', 
    'GetReportsForMapUseCase',
    'GetClustersUseCase',
    'PostReport',
    'GetReportUseCase',
    'GetReportsUseCase',
  ];
  
  for (final dependency in criticalDependencies) {
    switch (dependency) {
      case 'ReportApiClient':
        assert(sl.isRegistered<ReportApiClient>(), 'ReportApiClient no registrado');
        break;
      case 'ReportRepository':
        assert(sl.isRegistered<ReportRepository>(), 'ReportRepository no registrado');
        break;
      case 'GetReportsForMapUseCase':
        assert(sl.isRegistered<GetReportsForMapUseCase>(), 'GetReportsForMapUseCase no registrado');
        break;
      case 'GetClustersUseCase':
        assert(sl.isRegistered<GetClustersUseCase>(), 'GetClustersUseCase no registrado');
        break;
      case 'PostReport':
        assert(sl.isRegistered<PostReport>(), 'PostReport no registrado');
        break;
      case 'GetReportUseCase':
        assert(sl.isRegistered<GetReportUseCase>(), 'GetReportUseCase no registrado');
        break;
      case 'GetReportsUseCase':
        assert(sl.isRegistered<GetReportsUseCase>(), 'GetReportsUseCase no registrado');
        break;
    }
    print('[ReportDI] ✅ $dependency verificado');
  }
  
  print('[ReportDI] ✅ Todas las dependencias críticas verificadas correctamente');
}