import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/features/settings/domain/entities/company_profile.dart';
import 'package:vrs_transport_manager/features/settings/domain/usecases/company_profile_usecases.dart';
import 'company_profile_event.dart';
import 'company_profile_state.dart';

class CompanyProfileBloc
    extends Bloc<CompanyProfileEvent, CompanyProfileState> {
  final GetCompanyProfileUseCase _getProfile;
  final SaveCompanyProfileUseCase _saveProfile;

  CompanyProfileBloc({
    required GetCompanyProfileUseCase getProfile,
    required SaveCompanyProfileUseCase saveProfile,
  })  : _getProfile = getProfile,
        _saveProfile = saveProfile,
        super(const CompanyProfileInitial()) {
    on<CompanyProfileLoad>(_onLoad);
    on<CompanyProfileSave>(_onSave);
  }

  Future<void> _onLoad(
    CompanyProfileLoad event,
    Emitter<CompanyProfileState> emit,
  ) async {
    emit(const CompanyProfileLoading());
    final result = await _getProfile();
    result.fold(
      (failure) => emit(CompanyProfileError(failure.message)),
      (profile) =>
          emit(CompanyProfileLoaded(profile ?? CompanyProfile.empty)),
    );
  }

  Future<void> _onSave(
    CompanyProfileSave event,
    Emitter<CompanyProfileState> emit,
  ) async {
    emit(const CompanyProfileLoading());
    final result = await _saveProfile(event.profile);
    result.fold(
      (failure) => emit(CompanyProfileError(failure.message)),
      (_) => emit(CompanyProfileSaved(event.profile)),
    );
  }
}
