import 'package:digiauto/cubit/garage/garage_state.dart';
import 'package:digiauto/services/garage_service.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class GarageCubit extends Cubit<GarageState> {
  final GarageService service;
  GarageCubit(this.service) : super(GarageInitialState());

  void garageUpdate(String value) {
    state.copyWith(garage: value);
  }

  void mobileUpdate(String value) {
    state.copyWith(mobile: value);
  }

  void emailUpdate(String value) {
    state.copyWith(email: value);
  }

  void locationUpdate({required lat, required long}) {
    state.copyWith(latitude: lat, longitude: long);
  }

  Future<void> registerGarage() async {
    final result = await service.register(
      garage: state.garage,
      mobile: state.mobile,
      email: state.email,
      latitude: state.latitude!,
      longitude: state.longitude!,
    );
    if (result['status'] == 201) {
      emit(GarageSuccessState(result['body']['message']));
    } else {
      emit(GarageFailureState(result['body']['message']));
    }
  }
}
