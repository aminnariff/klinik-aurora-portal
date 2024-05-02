import 'package:klinik_aurora_portal/models/document/file_attribute.dart';

class UpdateBranchRequest {
  final String branchId;
  final String? branchCode;
  final String? branchName;
  final String? phoneNumber;
  final String? address;
  final String? postcode;
  final String? city;
  final String? state;
  final int? is24Hours;
  final String branchOpeningHours;
  final String branchClosingHours;
  final String branchLaunchDate;
  FileAttribute? branchImage;

  UpdateBranchRequest({
    required this.branchId,
    this.branchCode,
    this.branchName,
    this.phoneNumber,
    this.address,
    this.postcode,
    this.city,
    this.state,
    this.is24Hours,
    required this.branchOpeningHours,
    required this.branchClosingHours,
    required this.branchLaunchDate,
    this.branchImage,
  });
}
