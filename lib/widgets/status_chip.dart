// lib/widgets/status_chip.dart
// ─────────────────────────────
// Reusable chip that displays an attendance status with the right colour.

import 'package:flutter/material.dart';
import 'package:cleandesk_ai/core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status; // "present" | "checked_out" | "absent"
  final bool small;

  const StatusChip({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    final fontSize = small ? 10.0 : 12.0;
    final paddingH = small ? 8.0 : 10.0;
    final paddingV = small ? 4.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      decoration: BoxDecoration(
        color:        config.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  6,
            height: 6,
            decoration: BoxDecoration(
              color:  config.dotColor,
              shape:  BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              fontSize:   fontSize,
              fontWeight: FontWeight.w600,
              color:      config.textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _ChipConfig _config(String status) {
    switch (status) {
      case 'present':
        return const _ChipConfig(
          label:      'Present',
          background: AppTheme.chipPresent,
          textColor:  AppTheme.chipPresentText,
          dotColor:   AppTheme.chipPresentText,
        );
      case 'checked_out':
        return const _ChipConfig(
          label:      'Checked Out',
          background: AppTheme.chipCheckedOut,
          textColor:  AppTheme.chipCheckedOutText,
          dotColor:   AppTheme.chipCheckedOutText,
        );
      case 'absent':
      default:
        return const _ChipConfig(
          label:      'Absent',
          background: AppTheme.chipAbsent,
          textColor:  AppTheme.chipAbsentText,
          dotColor:   AppTheme.chipAbsentText,
        );
    }
  }
}

class _ChipConfig {
  final String label;
  final Color background;
  final Color textColor;
  final Color dotColor;
  const _ChipConfig({
    required this.label,
    required this.background,
    required this.textColor,
    required this.dotColor,
  });
}
