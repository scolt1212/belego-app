import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../utils/logo_validation.dart';

/// Ergebnis einer Logo-Auswahl.
class LogoPickResult {
  const LogoPickResult.success({required this.bytes, required this.fileName})
    : errorMessage = null;

  const LogoPickResult.failure(String message)
    : bytes = null,
      fileName = null,
      errorMessage = message;

  final Uint8List? bytes;
  final String? fileName;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null;
}

/// Wählt ein Firmenlogo aus der Galerie (Android/iOS) bzw. per Dateiauswahl
/// (Web) aus und validiert Format, Grösse und Lesbarkeit. Plattformübergreifend
/// über das offizielle `image_picker`-Paket.
class LogoPickerService {
  LogoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Öffnet die Bildauswahl. Gibt `null` zurück, wenn der Nutzer abgebrochen
  /// hat (kein Fehler), sonst ein Ergebnis mit Erfolg oder einer
  /// verständlichen deutschen Fehlermeldung.
  Future<LogoPickResult?> pick() async {
    final XFile? file;
    try {
      file = await _picker.pickImage(source: ImageSource.gallery);
    } catch (_) {
      return const LogoPickResult.failure(
        'Die Bildauswahl konnte nicht geöffnet werden.',
      );
    }
    if (file == null) return null;

    final nameError = LogoValidation.validateFileName(file.name);
    if (nameError != null) return LogoPickResult.failure(nameError);

    final length = await file.length();
    final sizeError = LogoValidation.validateSize(length);
    if (sizeError != null) return LogoPickResult.failure(sizeError);

    final bytes = await file.readAsBytes();
    if (!await LogoValidation.isDecodableImage(bytes)) {
      return const LogoPickResult.failure(
        'Diese Datei ist kein gültiges Bild.',
      );
    }

    return LogoPickResult.success(bytes: bytes, fileName: file.name);
  }
}
