class JobData {
  String? jobId;
  String? service;
  String? spare;
  String? quantity;

  JobData({this.jobId, this.service, this.spare, this.quantity});

  JobData copyWith({
    String? jobId,
    String? service,
    String? spare,
    String? quantity,
  }) {
    return JobData(
      jobId: jobId ?? this.jobId,
      service: service ?? this.service,
      spare: spare ?? this.spare,
      quantity: quantity ?? this.quantity,
    );
  }
}
