import 'package:digiauto/cubit/jobcard/jobcard_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class JobCardCubit extends Cubit<JobCardState> {
  JobCardCubit() : super(JobCardState(step: JobStep.initial));

  void next(JobStep step) => emit(state.copyWith(step: step));

  void setVehicle(String val) =>
      emit(state.copyWith(vehicleNo: val, step: JobStep.name));

  void setName(String val) =>
      emit(state.copyWith(name: val, step: JobStep.mobile));

  void setMobile(String val) =>
      emit(state.copyWith(mobile: val, step: JobStep.place));

  void setPlace(String val) =>
      emit(state.copyWith(place: val, step: JobStep.make));

  void setMake(String val) =>
      emit(state.copyWith(make: val, step: JobStep.model));

  void setModel(String val) =>
      emit(state.copyWith(model: val, step: JobStep.year));

  void setYear(String val) =>
      emit(state.copyWith(year: val, step: JobStep.chassis));

  void setChassis(String val) =>
      emit(state.copyWith(chassis: val, step: JobStep.engine));

  void skipChassis() => emit(state.copyWith(step: JobStep.engine));

  void setEngine(String val) =>
      emit(state.copyWith(engine: val, step: JobStep.km));

  void skipEngine() => emit(state.copyWith(step: JobStep.km));

  void setKm(String val) =>
      emit(state.copyWith(km: val, step: JobStep.services));

  void addService(String s) {
    final list = List<String>.from(state.services)..add(s);
    emit(state.copyWith(services: list));
  }

  void removeService(String s) {
    final list = List<String>.from(state.services)..remove(s);
    emit(state.copyWith(services: list));
  }

  void goToReview() => emit(state.copyWith(step: JobStep.review));

  void submit() async {
    emit(state.copyWith(step: JobStep.success));
  }
}
