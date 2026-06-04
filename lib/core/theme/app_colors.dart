import 'package:flutter/material.dart';
import '../../features/home/data/models/site_task_models.dart';

class AppColors {
  AppColors._();

  static const Color primary       = Color(0xFFB5651D);
  static const Color primaryLight  = Color(0xFFD4845A);
  static const Color primaryDark   = Color(0xFF7B3F0E);
  static const Color surfaceWarm   = Color(0xFFFDF0E0);
  static const Color background    = Color(0xFFFAF6F1);
  static const Color divider       = Color(0xFFEDD9C5);
  static const Color textPrimary   = Color(0xFF2C1810);
  static const Color textSecondary = Color(0xFF7A5C4F);
  static const Color textHint      = Color(0xFFBBA99F);

  static const Color pending      = Color(0xFFBA7517);
  static const Color pendingBg    = Color(0xFFFAEEDA);
  static const Color inProgress   = Color(0xFF185FA5);
  static const Color inProgressBg = Color(0xFFE6F1FB);
  static const Color completed    = Color(0xFF3B6D11);
  static const Color completedBg  = Color(0xFFEAF3DE);
  static const Color onHold       = Color(0xFF993C1D);
  static const Color onHoldBg     = Color(0xFFFAECE7);

  static Color statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress: return inProgress;
      case TaskStatus.completed:  return completed;
      case TaskStatus.onHold:     return onHold;
      default:                    return pending;
    }
  }

  static Color statusBg(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress: return inProgressBg;
      case TaskStatus.completed:  return completedBg;
      case TaskStatus.onHold:     return onHoldBg;
      default:                    return pendingBg;
    }
  }

  static const List<Color> avatarBgs = [
    Color(0xFFE1F5EE), Color(0xFFFAEEDA), Color(0xFFEEEDFE),
    Color(0xFFFAECE7), Color(0xFFE6F1FB),
  ];
  static const List<Color> avatarFgs = [
    Color(0xFF085041), Color(0xFF633806), Color(0xFF3C3489),
    Color(0xFF712B13), Color(0xFF0C447C),
  ];

  static Color avatarBg(int index) => avatarBgs[index % avatarBgs.length];
  static Color avatarFg(int index) => avatarFgs[index % avatarFgs.length];
}
