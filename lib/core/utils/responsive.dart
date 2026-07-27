import 'package:flutter/material.dart';

abstract final class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 &&
      MediaQuery.sizeOf(context).width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  /// Centered constrained body for all content screens.
  /// Mobile: full width. Web: max 600px centered.
  static Widget constrained(Widget child, {double maxWidth = 600}) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );

  /// Map and full-bleed screens use 900px max.
  static Widget constrainedWide(Widget child) =>
      constrained(child, maxWidth: 900);
}
