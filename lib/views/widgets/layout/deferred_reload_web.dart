import 'package:web/web.dart' as web;

const _storagePrefix = 'aurora_deferred_reload_';

bool tryAutoReloadOnce(String libraryKey) {
  try {
    final key = '$_storagePrefix$libraryKey';
    if (web.window.sessionStorage.getItem(key) == '1') {
      return false;
    }
    web.window.sessionStorage.setItem(key, '1');
    web.window.location.reload();
    return true;
  } catch (_) {
    return false;
  }
}

void reloadAppWithCacheBust(String libraryKey) {
  try {
    web.window.sessionStorage.removeItem('$_storagePrefix$libraryKey');
  } catch (_) {}
  web.window.location.reload();
}
