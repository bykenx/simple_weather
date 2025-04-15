import 'package:url_launcher/url_launcher.dart' as url_launcher;

class UrlUtils {
  static Future<void> launchUrl(String url, {bool isExternal = false}) async {
    final uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(
        uri,
        mode:
            isExternal
                ? url_launcher.LaunchMode.externalApplication
                : url_launcher.LaunchMode.inAppWebView,
      );
    } else {
      throw '无法打开链接: $url';
    }
  }

  static Future<void> launchUrlInApp(String url) async {
    await launchUrl(url, isExternal: false);
  }

  static Future<void> launchUrlInBrowser(String url) async {
    await launchUrl(url, isExternal: true);
  }
}
