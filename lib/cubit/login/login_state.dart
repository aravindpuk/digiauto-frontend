class LoginState {
  final String mobile;
  final String pin;
  final bool isValid;
  final bool isLoading;

  LoginState({
    this.mobile = '',
    this.pin = '',
    this.isValid = false,
    this.isLoading = false,
  });

  LoginState copyWith({String? mobile, String? pin, bool? isLoading}) {
    final m = mobile ?? this.mobile;
    final p = pin    ?? this.pin;
    return LoginState(
      mobile:    m,
      pin:       p,
      isLoading: isLoading ?? this.isLoading,
      isValid:   m.trim().length >= 6 && p.length == 4,
    );
  }
}

class LoginInitial extends LoginState {}

class LoginSuccess extends LoginState {
  final String message;
  final int? garageId;
  final int? branchId;
  LoginSuccess(this.message, this.garageId, this.branchId) : super();
}

class LoginFailure extends LoginState {
  final String message;
  LoginFailure(this.message) : super();
}

class Authenticated extends LoginState {}