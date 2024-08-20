import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';

const String jwtToken = "jwtToken";
const String token = "token";
const String singpassId = "singpassId";
const String productCode = "productCode";
const String postalCode = "postalCode";
const String unitNo = "unitNo";
const String orderReference = "orderReference";
const String registerUrl = "https://simba.sg/broadband";
const String simbaBroadbandUrl = "https://simba.sg/";
const int pageSize = 15;
const String simbaUrl = "https://simba.sg/";
const String supportEmail = "support@simba.sg";
const String authResponse = "authResponse";
const String jwtResponse = "jwtResponse";
const String rememberMe = "rememberMe";
const String username = "username";
const String password = "password";
List<String> supportedExtensions = ['jpg', 'jpeg', 'pdf', 'png'];
List<DropdownAttribute> withdrawReason = [
  DropdownAttribute('1', 'Change of Mind'),
  DropdownAttribute('2', 'Better offer elsewhere'),
  DropdownAttribute('3', 'No longer needed'),
  DropdownAttribute('others', 'Others'),
];
List<DropdownAttribute> rewardHistoryStatus = [
  DropdownAttribute('0', 'Completed'),
  DropdownAttribute('1', 'In-Progress'),
];
List<DropdownAttribute> states = [
  DropdownAttribute('Selangor', 'Selangor'),
  DropdownAttribute('Johor', 'Johor'),
  DropdownAttribute('Kedah', 'Kedah'),
  DropdownAttribute('Kelantan', 'Kelantan'),
  DropdownAttribute('Kuala Lumpur', 'Kuala Lumpur'),
  DropdownAttribute('Labuan', 'Labuan'),
  DropdownAttribute('Melaka', 'Melaka'),
  DropdownAttribute('Negeri Sembilan', 'Negeri Sembilan'),
  DropdownAttribute('Pahang', 'Pahang'),
  DropdownAttribute('Perak', 'Perak'),
  DropdownAttribute('Perlis', 'Perlis'),
  DropdownAttribute('Pulau Pinang', 'Pulau Pinang'),
  DropdownAttribute('Putrajaya', 'Putrajaya'),
  DropdownAttribute('Sabah', 'Sabah'),
  DropdownAttribute('Sarawak', 'Sarawak'),
  DropdownAttribute('Terengganu', 'Terengganu'),
];

double fileSizeLimit = 10.0;


    // "permissionId": "1bda631e-ef17-11ee-bd1b-cc801b09db2f",
    // "permissionName": "User Management",
    // "permissionId": "4ac042fa-ef2d-11ee-bd1b-cc801b09db2f",
    // "permissionName": "Admin Management",
    // "permissionId": "68c537d4-ef31-11ee-bd1b-cc801b09db2f",
    // "permissionName": "Branch",
    // "permissionId": "a231db36-058d-11ef-943b-626efeb17d5e",
    // "permissionName": "Point Management",
    // "permissionId": "d98236e8-f490-11ee-befc-aabaa50b463f",
    // "permissionName": "Voucher",
    // "permissionId": "dc4e7a5a-0e15-11ef-82b0-94653af51fb9",
    // "permissionName": "Reward Management",
    // "permissionId": "e7f8bc9e-ef43-11ee-bd1b-cc801b09db2f",
    // "permissionName": "Promotion",
    // "permissionId": "f90f9f18-057b-11ef-943b-626efeb17d5e",
    // "permissionName": "Doctor",
    // "permissionId": "6e0fe1f8-2f1f-11ef-8db9-6677d190faa2",
    // "permissionName": "Rewards",