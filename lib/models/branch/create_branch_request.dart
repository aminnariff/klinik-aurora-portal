import 'package:klinik_aurora_portal/models/document/file_attribute.dart';

class CreateBranchRequest {
  final String branchName;
  final String branchCode;
  final String phoneNumber;
  final String address;
  final String postcode;
  final String city;
  final String state;
  final int is24Hours;
  final String branchOpeningHours;
  final String branchClosingHours;
  final String branchLaunchDate;
  FileAttribute branchImage;

  CreateBranchRequest({
    required this.branchName,
    required this.branchCode,
    required this.phoneNumber,
    required this.address,
    required this.postcode,
    required this.city,
    required this.state,
    required this.is24Hours,
    required this.branchOpeningHours,
    required this.branchClosingHours,
    required this.branchLaunchDate,
    required this.branchImage,
  });
}
