enum JobStep {
  initial,
  vehicleNo,
  name,
  mobile,
  place,
  make,
  model,
  year,
  chassis,
  engine,
  km,
  services,
  review,
  success,
}

/// ---------------- STATE ----------------
class JobCardState {
  final JobStep step;

  final String vehicleNo;
  final String name;
  final String mobile;
  final String place;
  final String make;
  final String model;
  final String year;
  final String chassis;
  final String engine;
  final String km;

  final List<String> services;

  JobCardState({
    required this.step,
    this.vehicleNo = '',
    this.name = '',
    this.mobile = '',
    this.place = '',
    this.make = '',
    this.model = '',
    this.year = '',
    this.chassis = '',
    this.engine = '',
    this.km = '',
    this.services = const [],
  });

  JobCardState copyWith({
    JobStep? step,
    String? vehicleNo,
    String? name,
    String? mobile,
    String? place,
    String? make,
    String? model,
    String? year,
    String? chassis,
    String? engine,
    String? km,
    List<String>? services,
  }) {
    return JobCardState(
      step: step ?? this.step,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      place: place ?? this.place,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      chassis: chassis ?? this.chassis,
      engine: engine ?? this.engine,
      km: km ?? this.km,
      services: services ?? this.services,
    );
  }
}
