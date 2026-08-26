import 'package:flutter/material.dart';

/// Begrenzt die Inhaltsbreite auf grossen Bildschirmen (z.B. Desktop-Browser)
/// und zentriert den Inhalt, statt ihn unnatürlich über die gesamte Breite
/// zu strecken. Auf schmalen Bildschirmen (Smartphones) hat es keine Wirkung.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
