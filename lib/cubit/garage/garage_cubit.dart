import 'package:digiauto/cubit/garage/garage_state.dart';
import 'package:digiauto/services/garage_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GarageCubit extends Cubit<GarageState> {
  final GarageService service;
  GarageCubit(this.service) : super(GarageInitialState());

  void garageUpdate(String value) => emit(state.copyWith(garage: value));
  void mobileUpdate(String value) => emit(state.copyWith(mobile: value));
  void emailUpdate(String value)  => emit(state.copyWith(email: value));

  void locationUpdate({required double lat, required double lng}) =>
      emit(state.copyWith(latitude: lat, longitude: lng));

  Future<void> registerGarage() async {
    if (!state.isValid) return;
    try {
      emit(state.copyWith(isLoading: true));

      final result = await service.register(
        garage:    state.garage,
        mobile:    state.mobile,
        email:     state.email,
        latitude:  state.latitude!,
        longitude: state.longitude!,
      );

      if (result['status'] == 201) {
        emit(GarageSuccessState(
            result['body']['message'] as String? ?? 'Garage registered!'));
      } else {
        emit(state.copyWith(isLoading: false));
        emit(GarageFailureState(
            result['body']['message'] as String? ?? 'Registration failed.'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      emit(GarageFailureState('Something went wrong. Please try again.'));
    }
  }
}