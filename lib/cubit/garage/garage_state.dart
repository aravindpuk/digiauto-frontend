class GarageState {
  final String garage;
  final String mobile;
  final String email;
  final double? latitude;
  final double? longitude;
  final bool isValid;
  final bool isLoading;
  GarageState({
    this.garage = '',
    this.mobile = '',
    this.email = '',
    this.latitude,
    this.longitude,
    this.isValid = false,
    this.isLoading = false,
  });

  GarageState copyWith({
    String? garage,
    String? mobile,
    String? email,
    double? latitude,
    double? longitude,
    bool? isValid,
    bool? isLoading,
  }) {
    final updatedGarage = garage ?? this.garage;
    final updatedMobile = mobile ?? this.mobile;
    final updatedEmail = email ?? this.email;
    final updatedLat = latitude ?? this.latitude;
    final updatedLong = longitude ?? this.longitude;

    return GarageState(
      garage: updatedGarage,
      mobile: updatedMobile,
      email: updatedEmail,
      latitude: updatedLat,
      longitude: updatedLong,

      isValid:
          updatedGarage.length > 3 &&
          updatedMobile.length > 6 &&
          updatedLat != null &&
          updatedLong != null,

      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GarageInitialState extends GarageState {}

class GarageSuccessState extends GarageState {
  final String message;
  GarageSuccessState(this.message);
}

class GarageFailureState extends GarageState {
  final String message;
  GarageFailureState(this.message);
}
