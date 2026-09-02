import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/postal_code_service.dart';
import '../theme/app_theme.dart';

/// PLZ- und Ort-Felder mit Autovervollständigung für Schweizer Adressen.
/// Ist [enabled] false (z.B. bei einem anderen Land als „Schweiz“), verhalten
/// sich beide Felder wie normale manuelle Eingabefelder ohne Vorschläge und
/// ohne die strikte vierstellige PLZ-Regel bzw. Kombinationsprüfung.
class SwissAddressFields extends StatefulWidget {
  const SwissAddressFields({
    super.key,
    required this.formKey,
    required this.postalCodeController,
    required this.cityController,
    required this.postalCodeService,
    required this.enabled,
    this.addressRequired = true,
  });

  /// Form, zu der diese Felder gehören – wird nach einer Vorschlagsauswahl
  /// neu validiert, damit ein zuvor angezeigter Fehler sofort verschwindet.
  final GlobalKey<FormState> formKey;
  final TextEditingController postalCodeController;
  final TextEditingController cityController;
  final PostalCodeService postalCodeService;
  final bool enabled;

  /// Ob PLZ und Ort ausgefüllt sein müssen. Standardmässig `true` (z.B.
  /// Firmeneinrichtung, Rechnungsempfänger). Bei `false` bleiben leere Felder
  /// gültig, eine vorhandene Eingabe wird aber weiterhin gegen das amtliche
  /// Verzeichnis geprüft (z.B. für einen reinen Lieferanten-Kontakt ohne
  /// zwingende Rechnungsadresse).
  final bool addressRequired;

  @override
  State<SwissAddressFields> createState() => _SwissAddressFieldsState();
}

class _SwissAddressFieldsState extends State<SwissAddressFields> {
  List<PostalCodeEntry> _suggestions = const [];

  void _handleQuery(String query) {
    if (!widget.enabled) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    final results = widget.postalCodeService.search(query);
    setState(() => _suggestions = results);
  }

  void _closeSuggestions() {
    if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
  }

  void _selectSuggestion(PostalCodeEntry entry) {
    // Beide Controller sofort aktualisieren – dies aktualisiert automatisch
    // auch die sichtbaren Textfelder, da diese an die Controller gebunden
    // sind.
    widget.postalCodeController.text = entry.postalCode;
    widget.cityController.text = entry.locality;
    setState(() => _suggestions = const []);
    // Formularzustand aktualisieren, damit ein zuvor angezeigter PLZ- oder
    // Ort-Fehler nach der gültigen Auswahl sofort verschwindet.
    widget.formKey.currentState?.validate();
    FocusScope.of(context).unfocus();
  }

  String? _validatePostalCode(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return widget.addressRequired ? 'Pflichtfeld' : null;
    }
    if (!widget.enabled) return null;
    if (!RegExp(r'^\d{4}$').hasMatch(trimmed)) {
      return 'Bitte eine gültige vierstellige Schweizer PLZ eingeben.';
    }
    return null;
  }

  String? _validateCity(String? value) {
    final city = (value ?? '').trim();
    if (city.isEmpty) {
      return widget.addressRequired ? 'Bitte Ort eingeben' : null;
    }
    if (!widget.enabled) return null;
    final postalCode = widget.postalCodeController.text.trim();
    // Kombination nur prüfen, wenn die PLZ für sich bereits gültig ist –
    // sonst wird der PLZ-Fehler bereits separat angezeigt.
    if (!RegExp(r'^\d{4}$').hasMatch(postalCode)) return null;
    if (!widget.postalCodeService.isValidCombination(postalCode, city)) {
      return 'Diese PLZ/Ort-Kombination ist nicht bekannt.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // TapRegion umschliesst Felder UND Vorschlagsliste als eine Einheit:
    // Ein Tap auf einen Vorschlag zählt damit nicht als "ausserhalb" und
    // löst kein vorzeitiges Unfocus/Schliessen aus, bevor der Tap selbst
    // verarbeitet wurde (sonst verschwindet die Liste zwischen Pointer-Down
    // und -Up, und der Tap geht ins Leere).
    return TapRegion(
      onTapOutside: (_) => _closeSuggestions(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: TextFormField(
                  key: const Key('setup_postal_code'),
                  controller: widget.postalCodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: widget.enabled
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ]
                      : null,
                  decoration: const InputDecoration(labelText: 'PLZ'),
                  // Verhindert, dass das Framework beim Tap auf einen
                  // Vorschlag automatisch unfocust, bevor der Tap verarbeitet
                  // wurde. Das Schliessen übernimmt die TapRegion oben.
                  onTapOutside: (_) {},
                  validator: _validatePostalCode,
                  onChanged: _handleQuery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('setup_city'),
                  controller: widget.cityController,
                  decoration: const InputDecoration(labelText: 'Ort'),
                  onTapOutside: (_) {},
                  validator: _validateCity,
                  onChanged: _handleQuery,
                ),
              ),
            ],
          ),
          if (widget.enabled && _suggestions.isNotEmpty)
            _buildSuggestionsList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      key: const Key('postal_code_suggestions'),
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 260),
      // Material statt eines farbigen Container/DecoratedBox, damit ListTile
      // seinen Hintergrund/Ink-Splash korrekt auf diesem Ancestor zeichnet.
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.fieldBorder),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _suggestions.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.fieldBorder),
          itemBuilder: (context, index) {
            final entry = _suggestions[index];
            return InkWell(
              key: Key(
                // PLZ+Ort allein sind nicht immer eindeutig (z.B. "8376
                // Fischingen" existiert amtlich sowohl im Kanton TG als
                // auch im Kanton SG) – der Kanton macht den Key eindeutig.
                'postal_suggestion_${entry.postalCode}_${entry.locality}_${entry.canton}',
              ),
              onTap: () => _selectSuggestion(entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(entry.label, style: const TextStyle(fontSize: 14)),
              ),
            );
          },
        ),
      ),
    );
  }
}
