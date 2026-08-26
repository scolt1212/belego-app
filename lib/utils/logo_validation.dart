import 'dart:typed_data';
import 'dart:ui' as ui;

/// Reine, testbare Prüflogik für ein hochgeladenes Firmenlogo – unabhängig
/// davon, wie die Datei ausgewählt wurde (Galerie, Fotos, Dateiauswahl).
class LogoValidation {
  LogoValidation._();

  static const int maxBytes = 5 * 1024 * 1024;
  static const List<String> allowedExtensions = ['png', 'jpg', 'jpeg'];

  /// Prüft die Dateiendung. `null` bei gültigem Format, sonst eine
  /// verständliche deutsche Fehlermeldung.
  static String? validateFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex == -1
        ? ''
        : fileName.substring(dotIndex + 1).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Bitte eine PNG- oder JPEG-Datei auswählen.';
    }
    return null;
  }

  /// Prüft die Dateigrösse (maximal 5 MB).
  static String? validateSize(int sizeInBytes) {
    if (sizeInBytes > maxBytes) {
      return 'Die Datei ist zu gross (maximal 5 MB).';
    }
    return null;
  }

  /// Prüft, ob sich die Bytes tatsächlich als Bild dekodieren lassen (fängt
  /// beschädigte oder nicht lesbare Dateien ab).
  static Future<bool> isDecodableImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      await codec.getNextFrame();
      return true;
    } catch (_) {
      return false;
    }
  }
}
