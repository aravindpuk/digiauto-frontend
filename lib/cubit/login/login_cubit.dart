import 'package:digiauto/utils/auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService authService;

  LoginCubit(this.authService) : super(LoginInitial());

  void mobileChanged(String value) {
    state.copyWith(mobile: value);
  }

  void pinChanged(String value) {
    state.copyWith(pin: value);
    print(state.pin.length);
    if (state.pin.length == 4) {
      print(state.isValid);
    }
  }

  Future<void> login() async {
    try {
      emit(state.copyWith(isLoading: true));
      final result = await authService.login(
        mobile: state.mobile,
        pin: state.pin,
      );
      // print(result);

      if (result['status'] == 200) {
        await saveToken(result['body']['token']);
        emit(
          LoginSuccess(result['body']['message'], result['body']['garage_id']),
        );
      } else {
        emit(state.copyWith(isLoading: false));
        emit(LoginFailure(result['body']['message'] ?? 'Invalid credentials'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      emit(LoginFailure('Something went wrong'));
    }
  }

  Future<void> isUserLogedIn() async {
    try {
      final token = await getToken();
      // print(token);
      if (token!.isNotEmpty) {
        emit(Authenticated());
      }
    } catch (e) {
      print(e);
    }
  }
}
