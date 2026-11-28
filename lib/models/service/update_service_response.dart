class UpdateServiceResponse {
  String? message;
  bool? requiresConfirmation;
  List<Map<String, dynamic>>? overlaps;

  UpdateServiceResponse({this.message, this.requiresConfirmation, this.overlaps});

  UpdateServiceResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    requiresConfirmation = json['requiresConfirmation'] == true;
    if (json['overlaps'] is List) {
      overlaps = (json['overlaps'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (requiresConfirmation != null) data['requiresConfirmation'] = requiresConfirmation;
    if (overlaps != null) data['overlaps'] = overlaps;
    return data;
  }
}
