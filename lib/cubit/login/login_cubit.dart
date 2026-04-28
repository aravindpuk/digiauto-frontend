import 'package:digiauto/utils/auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService authService;
  LoginCubit(this.authService) : super(LoginInitial());

  void mobileChanged(String value) => emit(state.copyWith(mobile: value));
  void pinChanged(String value)    => emit(state.copyWith(pin: value));

  Future<void> login() async {
    if (!state.isValid) return;
    try {
      emit(state.copyWith(isLoading: true));
      final result = await authService.login(
        mobile: state.mobile,
        pin: state.pin,
      );

      if (result['status'] == 200) {
        final body = result['body'] as Map<String, dynamic>;
        await saveToken(body['token'] as String);

        int? garageId = _parseInt(body['garage_id']);
        int? branchId = _parseInt(body['branch_id']);

        if (garageId != null) await saveGarageId(garageId);
        if (branchId != null) await saveBranchId(branchId);

        emit(LoginSuccess(body['message'] as String, garageId, branchId));
      } else {
        emit(state.copyWith(isLoading: false));
        emit(LoginFailure(
            result['body']['message'] as String? ?? 'Invalid credentials'));
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false));
      emit(LoginFailure('Something went wrong. Please try again.'));
    }
  }

  Future<void> isUserLoggedIn() async {
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) emit(Authenticated());
    } catch (_) {}
  }

  int? _parseInt(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));
}