import 'package:klinik_aurora_portal/models/document/file_attribute.dart';

class CreateBranchRequest {
  final String branchName;
  final String branchCode;
  final String phoneNumber;
  final String address;
  final String postcode;
  final String city;
  final String state;
  FileAttribute branchImage;

  CreateBranchRequest({
    required this.branchName,
    required this.branchCode,
    required this.phoneNumber,
    required this.address,
    required this.postcode,
    required this.city,
    required this.state,
    required this.branchImage,
  });
}
