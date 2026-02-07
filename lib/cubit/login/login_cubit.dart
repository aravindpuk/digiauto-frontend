import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService authService;

  LoginCubit(this.authService) : super(LoginInitial());

  void onInputChanged(mobile, pin) {
    if (mobile.length >= 6 && mobile.length <= 10 && pin.length == 4) {
      emit(LoginInitial(loginBtnStatus: true));
    } else {
      emit(LoginInitial(loginBtnStatus: false));
    }
  }

  Future<void> login(String mobile, String pin) async {
    emit(LoginLoading());

    try {
      final result = await authService.login(mobile: mobile, pin: pin);

      if (result['statusCode'] == 200) {
        emit(LoginSuccess(result['body']['token']));
      } else {
        emit(LoginFailure(result['body']['message'] ?? 'Invalid credentials'));
      }
    } catch (e) {
      emit(LoginFailure('Something went wrong'));
    }
  }
}
