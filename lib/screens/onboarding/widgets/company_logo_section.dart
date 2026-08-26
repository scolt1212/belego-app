import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../services/logo_picker_service.dart';
import '../../../theme/app_theme.dart';

/// Optionaler Bereich für das Firmenlogo: echte, plattformübergreifende
/// Auswahl (Android/iOS-Galerie, Web-Dateiauswahl) inkl. Vorschau, Ersetzen
/// und Entfernen. Zeigt niemals einen falschen Erfolgsstatus – ohne
/// ausgewähltes Logo steht ehrlich „Noch kein Logo ausgewählt“.
class CompanyLogoSection extends StatelessWidget {
  const CompanyLogoSection({
    super.key,
    required this.logoBytes,
    required this.logoFileName,
    required this.onLogoChanged,
  });

  final Uint8List? logoBytes;
  final String? logoFileName;

  /// Wird mit `(bytes, fileName)` bei Auswahl/Ersetzen, mit `(null, null)`
  /// beim Entfernen aufgerufen.
  final void Function(Uint8List? bytes, String? fileName) onLogoChanged;

  Future<void> _pickLogo(BuildContext context) async {
    final result = await LogoPickerService().pick();
    if (result == null) return; // Nutzer hat abgebrochen.
    if (!context.mounted) return;
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.errorMessage!)));
      return;
    }
    onLogoChanged(result.bytes, result.fileName);
  }

  void _removeLogo() => onLogoChanged(null, null);

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoBytes != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Firmenlogo',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Das Logo erscheint später oben links auf Rechnungen und Offerten.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            key: const Key('logo_preview_box'),
            width: 160,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: hasLogo
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    // BoxFit.contain: Logo wird nie verzerrt, Transparenz
                    // (z.B. bei PNG) bleibt erhalten.
                    child: Image.memory(logoBytes!, fit: BoxFit.contain),
                  )
                : const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            hasLogo
                ? (logoFileName ?? 'Logo ausgewählt')
                : 'Noch kein Logo ausgewählt',
            key: const Key('logo_status_text'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                key: const Key('setup_logo_select'),
                // Im Theme ist OutlinedButton standardmässig volle Breite
                // (für einzelne CTA-Buttons); hier soll er kompakt neben dem
                // "Entfernen"-Button in einer Row stehen.
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => _pickLogo(context),
                child: Text(hasLogo ? 'Ersetzen' : 'Auswählen'),
              ),
              if (hasLogo) ...[
                const SizedBox(width: 12),
                TextButton(
                  key: const Key('setup_logo_remove'),
                  onPressed: _removeLogo,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Text('Entfernen'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
