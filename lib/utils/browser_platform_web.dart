import 'dart:js_util' as js_util;

String getBrowserPlatformLabel() {
  try {
    final navigator = js_util.getProperty(js_util.globalThis, 'navigator');
    final userAgent = js_util.getProperty(navigator, 'userAgent')?.toString() ?? '';
    final isAndroid = userAgent.contains('Android');
    final isChrome = userAgent.contains('Chrome') && !userAgent.contains('Chromium') && !userAgent.contains('Edg');
    final isSafari = userAgent.contains('Safari') && !userAgent.contains('Chrome') && !userAgent.contains('Chromium') && !userAgent.contains('Edg');
    final isIOS = userAgent.contains('iPhone') || userAgent.contains('iPad') || userAgent.contains('iPod');

    if (isAndroid && isChrome) return 'Android Chrome';
    if (isIOS && isSafari) return 'iOS Safari';
    return 'Desktop browser';
  } catch (_) {
    return 'Web browser';
  }
}

String getBrowserHostname() {
  try {
    final location = js_util.getProperty(js_util.globalThis, 'location');
    final hostname = js_util.getProperty(location, 'hostname');
    return hostname?.toString() ?? 'unknown';
  } catch (_) {
    return 'unknown';
  }
}
