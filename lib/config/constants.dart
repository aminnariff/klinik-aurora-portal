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
