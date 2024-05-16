class CreateRewardHistoryResponse {
  String? message;
  String? id;

  CreateRewardHistoryResponse({this.message, this.id});

  CreateRewardHistoryResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['id'] = id;
    return data;
  }
}
