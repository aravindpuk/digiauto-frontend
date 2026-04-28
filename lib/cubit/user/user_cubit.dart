import 'package:digiauto/cubit/user/user_state.dart';
import 'package:digiauto/services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserCubit extends Cubit<UserState> {
  final AuthService authService;
  UserCubit(this.authService) : super(UserState());

  void nameChanged(String value) {
    emit(state.copyWith(name: value));
  }

  void mobileChanged(String value) {
    emit(state.copyWith(mobile: value));
  }

  void pinChanged(String value) {
    emit(state.copyWith(pin: value));
  }

  Future<void> registerUser({required String role}) async {
    try {
      // Simulate API call
      emit(state.copyWith(isLoading: true));
      final response = await authService.register(
        name: state.name,
        mobile: state.mobile,
        pin: state.pin,
        role: role,
      );

      if (response['status'] == 201) {
        emit(UserSuccess(response['body']['message']));
      } else {
        emit(state.copyWith(isLoading: false));
        emit(UserFailure(response['body']['message']));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      emit(UserFailure(e.toString()));
    }
  }
}
