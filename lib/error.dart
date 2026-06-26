import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

Widget copyableText(String text, {TextStyle? style}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      Clipboard.setData(ClipboardData(text: text));
      HapticFeedback.lightImpact();
    },
    child: Tooltip(
      message: 'Tap to copy error',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(text, style: style)),
          const SizedBox(width: 6),
          Icon(Icons.copy_rounded, size: 12, color: AcousticColors.midGray),
        ],
      ),
    ),
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Clipboard.setData(ClipboardData(text: message));
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error copied to clipboard'),
              duration: Duration(seconds: 1),
              backgroundColor: AcousticColors.sonarCyan.withOpacity(0.3),
            ),
          );
        },
        child: Row(
          children: [
            Icon(Icons.copy_rounded, size: 14, color: AcousticColors.sonarCyan),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
      backgroundColor: AcousticColors.darkCarbon,
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: AcousticColors.sonarCyan,
        onPressed: () {},
      ),
    ),
  );
}

Future<void> showErrorDialog(BuildContext context, String title, String message) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AcousticColors.darkCarbon,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AcousticColors.warnOrange.withOpacity(0.3)),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AcousticColors.warnOrange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AcousticColors.titanium,
              ),
            ),
          ),
        ],
      ),
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Clipboard.setData(ClipboardData(text: message));
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error copied to clipboard'),
              duration: Duration(seconds: 1),
              backgroundColor: AcousticColors.sonarCyan.withOpacity(0.3),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AcousticColors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  message,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AcousticColors.steel,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.copy_rounded, size: 14, color: AcousticColors.midGray),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'ACKNOWLEDGED',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AcousticColors.sonarCyan,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget errorBanner(String message) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      Clipboard.setData(ClipboardData(text: message));
      HapticFeedback.lightImpact();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AcousticColors.warnOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AcousticColors.warnOrange.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, size: 14, color: AcousticColors.warnOrange),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: AcousticColors.warnOrange,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.copy_rounded, size: 10, color: AcousticColors.midGray),
        ],
      ),
    ),
  );
}
