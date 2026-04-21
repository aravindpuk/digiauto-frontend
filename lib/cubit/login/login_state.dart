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
    final newMobile = mobile ?? this.mobile;
    final newPin = pin ?? this.pin;

    return LoginState(
      mobile: newMobile,
      pin: newPin,
      isValid:
          newMobile.isNotEmpty && newMobile.length > 6 && newPin.length == 4,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LoginInitial extends LoginState {}

class LoginSuccess extends LoginState {
  final String message;
  final int? garageId;
  LoginSuccess(this.message, this.garageId);
}

class LoginFailure extends LoginState {
  final String message;
  LoginFailure(this.message);
}

class Authenticated extends LoginState {}
