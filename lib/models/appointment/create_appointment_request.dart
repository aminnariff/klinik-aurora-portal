class CreateAppointmentRequest {
  String? userId;
  String? serviceBranchId;
  String? appointmentDateTime;
  String? appointmentNote;
  String? customerDueDate;
  String? doctorId;
  int? appointmentRating;
  String? appointmentFeedback;
  int? appointmentStatus;

  CreateAppointmentRequest({
    this.userId,
    this.serviceBranchId,
    this.appointmentDateTime,
    this.appointmentNote,
    this.customerDueDate,
    this.doctorId,
    this.appointmentRating,
    this.appointmentFeedback,
    this.appointmentStatus,
  });

  CreateAppointmentRequest.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    serviceBranchId = json['serviceBranchId'];
    appointmentDateTime = json['appointmentDateTime'];
    appointmentNote = json['appointmentNote'];
    customerDueDate = json['customerDueDate'];
    doctorId = json['doctorId'];
    appointmentRating = json['appointmentRating'];
    appointmentFeedback = json['appointmentFeedback'];
    appointmentStatus = json['appointmentStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['serviceBranchId'] = serviceBranchId;
    data['appointmentDateTime'] = appointmentDateTime;
    data['appointmentNote'] = appointmentNote;
    data['customerDueDate'] = customerDueDate;
    data['doctorId'] = doctorId;
    data['appointmentRating'] = appointmentRating;
    data['appointmentFeedback'] = appointmentFeedback;
    data['appointmentStatus'] = appointmentStatus;
    return data;
  }
}
