import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';
import 'brand.dart';
import 'shell.dart';

/// Standard branded workspace for Infortts ecosystem nodes.
///
/// Every frontend app must expose a tab bar and a settings page (guaranteed by
/// [InforttsAppShell]); this widget provides the shared in-tab content: the
/// procedural 3D emblem, the app name, its tagline and the package identifier.
class InforttsNodeWorkspace extends StatelessWidget {
  final String appName;
  final String tagline;
  final String? packageId;

  const InforttsNodeWorkspace({
    super.key,
    required this.appName,
    required this.tagline,
    this.packageId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcousticColors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Infortts3DLogo(appName: appName, size: 170, interactive: false),
              const SizedBox(height: 28),
              Text(
                appName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                  color: AcousticColors.titanium,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tagline,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AcousticColors.steel,
                  height: 1.5,
                ),
              ),
              if (packageId != null && packageId!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AcousticColors.panelBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AcousticColors.midGray.withOpacity(0.2)),
                  ),
                  child: Text(
                    packageId!,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AcousticColors.sonarCyan,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const InforttsWatermark(size: 10),
            ],
          ),
        ),
      ),
    );
  }
}