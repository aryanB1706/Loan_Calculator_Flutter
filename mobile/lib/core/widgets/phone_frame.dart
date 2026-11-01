import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Keeps the phone layout on wide screens (a laptop browser, a tablet): the app
/// stays in a centred column of phone width instead of stretching edge to edge.
/// On a phone it does nothing.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const double maxWidth = 430;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= maxWidth) {
      return child;
    }

    return ColoredBox(
      color: AppColors.primaryDark,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          // Screens that read the window width (for layout maths) must see the
          // width they actually get, not the full browser width.
          child: MediaQuery(
            data: media.copyWith(size: Size(maxWidth, media.size.height)),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
