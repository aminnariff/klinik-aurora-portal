{{flutter_js}}
{{flutter_build_config}}

// Append a build-specific cache-busting query param so browsers never reuse
// a previously cached main.dart.wasm / main.dart.mjs / main.dart.js after a deploy.
(function () {
  var cfg = window._flutter && window._flutter.buildConfig;
  var hash =
    (cfg && cfg.wasmHashes && cfg.wasmHashes["main.dart.wasm"]) ||
    {{flutter_service_worker_version}} ||
    "__BUILD_HASH__";
  if (cfg && Array.isArray(cfg.builds) && hash) {
    var v = "?v=" + String(hash).replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 12);
    cfg.builds.forEach(function (b) {
      if (b.mainWasmPath && b.mainWasmPath.indexOf("?") === -1) {
        b.mainWasmPath += v;
      }
      if (b.jsSupportRuntimePath && b.jsSupportRuntimePath.indexOf("?") === -1) {
        b.jsSupportRuntimePath += v;
      }
      if (b.mainJsPath && b.mainJsPath.indexOf("?") === -1) {
        b.mainJsPath += v;
      }
    });
  }
})();

_flutter.loader.load();
