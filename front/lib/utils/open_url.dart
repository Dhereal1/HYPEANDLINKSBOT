import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in external browser/tab. No-op if launch fails.
Future<void> openInNewTab(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
}
