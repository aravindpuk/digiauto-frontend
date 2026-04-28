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
    bool? isLoading,
  }) {
    final newGarage = garage ?? this.garage;
    final newMobile = mobile ?? this.mobile;
    final newLat = latitude ?? this.latitude;
    final newLng = longitude ?? this.longitude;

    return GarageState(
      garage: newGarage,
      mobile: newMobile,
      email: email ?? this.email,
      latitude: newLat,
      longitude: newLng,
      isLoading: isLoading ?? this.isLoading,
      // recomputed every time
      isValid:
          newGarage.trim().length > 3 &&
          newMobile.trim().length >= 6 &&
          newLat != null &&
          newLng != null,
    );
  }
}

class GarageInitialState extends GarageState {}

class GarageSuccessState extends GarageState {
  final String message;
  GarageSuccessState(this.message) : super();
}

class GarageFailureState extends GarageState {
  final String message;
  GarageFailureState(this.message) : super();
}
