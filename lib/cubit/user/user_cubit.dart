import 'package:digiauto/cubit/user/user_state.dart';
import 'package:digiauto/services/auth_service.dart';
import 'package:digiauto/utils/auth.dart';
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
        if (role != 'customer') {
          final login = await authService.login(
            mobile: state.mobile,
            pin: state.pin,
          );
          if (login['status'] != 200) {
            throw Exception(
              login['body']['message'] as String? ??
                  'Account created. Please log in to continue setup.',
            );
          }
          final body = login['body'] as Map<String, dynamic>;
          await saveToken(body['token'] as String);
          await saveUserRole(role);
        }
        emit(
          UserSuccess(
            response['body']['message'] as String? ?? 'Registered',
            role,
          ),
        );
      } else {
        final failedState = state.copyWith(isLoading: false);
        emit(
          UserFailure(
            response['body']['message'] as String? ?? 'Registration failed.',
            failedState,
          ),
        );
      }
    } catch (e) {
      final failedState = state.copyWith(isLoading: false);
      emit(UserFailure(e.toString(), failedState));
    }
  }
}
