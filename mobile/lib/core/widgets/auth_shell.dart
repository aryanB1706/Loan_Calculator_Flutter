import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'onboarding_carousel.dart';

/// Blue branded header with the onboarding slides and a white rounded sheet
/// for the screen's own content. Shared by the login and OTP screens.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.sheet, this.initialSlide = 0});

  final Widget sheet;
  final int initialSlide;

  static const double _sheetRadius = 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 36),
                      Image.asset('assets/images/logo.png', width: 212),
                      const SizedBox(height: 24),
                      OnboardingCarousel(initialPage: initialSlide),
                      const SizedBox(height: 24),
                      Expanded(child: _buildSheet()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.mint],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(_sheetRadius)),
      ),
      // The 6px gradient strip above the white sheet is the top border.
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_sheetRadius),
          ),
        ),
        child: sheet,
      ),
    );
  }
}
