class UserState {
  final String name;
  final String mobile;
  final String pin;
  final bool isValid;
  final bool isLoading;

  UserState({
    this.name = '',
    this.mobile = '',
    this.pin = '',
    this.isValid = false,
    this.isLoading = false,
  });
  UserState copyWith({
    String? name,
    String? mobile,
    String? pin,
    bool? isLoading,
  }) {
    /// these steps are written bcs isValid condition is to check instead writing name!.length safe method is this..
    final newName = name ?? this.name;
    final newMobile = mobile ?? this.mobile;
    final newPin = pin ?? this.pin;

    return UserState(
      name: newName,
      mobile: newMobile,
      pin: newPin,
      isLoading: isLoading ?? this.isLoading,
      isValid:
          newName.length >= 3 && newMobile.length > 6 && newPin.length == 4,
    );
  }
}

class UserInitial extends UserState {}

class UserSuccess extends UserState {
  final String message;
  UserSuccess(this.message);
}

class UserFailure extends UserState {
  final String message;
  UserFailure(this.message);
}
