import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/admission/domain/admission_form_record.dart';

final admissionFormRecordApiServiceProvider =
    Provider<ApiService<AdmissionFormRecord>>((ref) {
      final dio = ref.watch(dioProvider);
      return ApiService<AdmissionFormRecord>(
        dio: dio,
        fromJson: AdmissionFormRecord.fromJson,
      );
    });
