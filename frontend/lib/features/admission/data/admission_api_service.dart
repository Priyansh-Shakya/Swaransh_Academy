import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/admission/data/provider.dart';
import 'package:swaransh_academy/features/admission/domain/admission_form_record.dart';

class AdmissionApiService {
  AdmissionApiService(this._apiService, this._dio);

  final ApiService<AdmissionFormRecord> _apiService;
  final Dio _dio;

  /// POST /admissionForm
  /// Accepts the serialized AdmissionFormState (via .toJson()).
  Future<AdmissionFormRecord> postAdmissionForm(
      Map<String, dynamic> data) async {
    return _apiService.create(endpoint: '/admissionForm', data: data);
  }

  /// GET /admissionFormList — admin only, optional status filter.
  Future<List<AdmissionFormRecord>> getAllAdmissionForms({String? status}) {
    return _apiService.getAll(
      endpoint: '/admissionFormList',
      queryParams: status != null ? {'status': status} : null,
    );
  }

  /// GET /admissionForm/me — forms belonging to the current JWT user.
  Future<List<AdmissionFormRecord>> getUserAdmissionForms() {
    return _apiService.getAll(endpoint: '/admissionForm/me');
  }

  /// POST /admissionForm/{id}/approved — admin only.
  Future<void> approveForm(int formId) async {
    await _dio.post('/admissionForm/$formId/approved');
  }

  /// POST /admissionForm/{id}/declined — admin only.
  Future<void> declineForm(int formId) async {
    await _dio.post('/admissionForm/$formId/declined');
  }
}

final admissionApiServiceProvider = Provider<AdmissionApiService>((ref) {
  final apiService = ref.watch(admissionFormRecordApiServiceProvider);
  final dio = ref.watch(dioProvider);
  return AdmissionApiService(apiService, dio);
});
