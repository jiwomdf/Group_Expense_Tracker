import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Bindings to the Tesseract.js build served from `web/tesseract/`.
///
/// Self-hosted rather than pulled from a CDN, so the web app keeps working
/// offline and does not depend on a third party staying up. The asset paths
/// below must match what is in that folder.
class TesseractJs {
  const TesseractJs._();

  /// Served from the same origin as the app, relative to `web/`.
  static const _workerPath = 'tesseract/worker.min.js';
  static const _corePath = 'tesseract/tesseract-core-simd.wasm.js';

  /// Directory holding `eng.traineddata.gz`. Tesseract appends the file name.
  static const _langPath = 'tesseract/';

  static const language = 'eng';

  /// True once `tesseract.min.js` has been evaluated by the browser.
  static bool get isLoaded => globalContext.has('Tesseract');

  /// Runs OCR over an image reference — a `blob:` URL, data URL, or path.
  static Future<JSObject> recognize(String image) async {
    final result =
        await _recognize(image.toJS, language.toJS, _options()).toDart;
    return result;
  }

  /// Points Tesseract at the local copies. Without these it silently reaches
  /// for its CDN defaults, which is exactly what self-hosting is avoiding.
  static JSObject _options() {
    final options = JSObject();
    options.setProperty('workerPath'.toJS, _workerPath.toJS);
    options.setProperty('corePath'.toJS, _corePath.toJS);
    options.setProperty('langPath'.toJS, _langPath.toJS);
    // The shipped traineddata is gzipped, which is also Tesseract's default.
    options.setProperty('gzip'.toJS, true.toJS);
    return options;
  }
}

@JS('Tesseract.recognize')
external JSPromise<JSObject> _recognize(
    JSString image, JSString language, JSObject options);
