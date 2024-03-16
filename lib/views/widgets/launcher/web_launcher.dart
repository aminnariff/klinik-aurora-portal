import 'package:url_launcher/url_launcher_string.dart';

launchWebUrl(String url, {String? webOnlyWindowName}) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(
      url,
      mode: LaunchMode.inAppWebView,
      webOnlyWindowName: webOnlyWindowName ?? '_self',
    );
  } else {
    throw 'Could not launch $url';
  }
}
