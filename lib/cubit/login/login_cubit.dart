import 'package:digiauto/utils/auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService authService;
  LoginCubit(this.authService) : super(LoginInitial());

  void mobileChanged(String value) => emit(state.copyWith(mobile: value));
  void pinChanged(String value) => emit(state.copyWith(pin: value));

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
        final role = body['role']?.toString();
        if (role != null) await saveUserRole(role);
        try {
          final messaging = FirebaseMessaging.instance;
          final oldShopId = await getSpareShopId();
          final shopId = _parseInt(body['spare_shop_id']);
          if (oldShopId != null && oldShopId != shopId) {
            await messaging.unsubscribeFromTopic('digi-spare-shop-$oldShopId');
          }
          if (role == 'digi-staff') {
            await messaging.requestPermission();
            await messaging.subscribeToTopic('digi-staff-spare-orders');
          } else {
            await messaging.unsubscribeFromTopic('digi-staff-spare-orders');
          }
          if (role == 'scrap-team' && shopId != null) {
            await messaging.requestPermission();
            await messaging.subscribeToTopic('digi-spare-shop-$shopId');
          }
          if (shopId != null) {
            await saveSpareShopId(shopId);
          } else {
            await clearSpareShopId();
          }
        } catch (_) {
          // Push setup must not prevent a successful account login.
        }

        int? garageId = _parseInt(body['garage_id']);
        int? branchId = _parseInt(body['branch_id']);

        if (garageId != null) await saveGarageId(garageId);
        if (branchId != null) await saveBranchId(branchId);

        emit(LoginSuccess(body['message'] as String, garageId, branchId, role));
      } else {
        final failedState = state.copyWith(isLoading: false);
        emit(
          LoginFailure(
            result['body']['message'] as String? ?? 'Invalid credentials',
            failedState,
          ),
        );
      }
    } catch (_) {
      final failedState = state.copyWith(isLoading: false);
      emit(
        LoginFailure('Something went wrong. Please try again.', failedState),
      );
    }
  }

  Future<void> isUserLoggedIn() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) return;
      final garageId = await getGarageId();
      final branchId = await getBranchId();
      final role = await getUserRole();
      emit(LoginSuccess('', garageId, branchId, role));
    } catch (_) {}
  }

  int? _parseInt(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));
}
