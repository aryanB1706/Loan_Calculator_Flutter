import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class _Slide {
  const _Slide(this.title, this.subtitle, this.icons);

  final String title;
  final String subtitle;
  final List<IconData> icons;
}

/// Marketing slides shown above the login and OTP sheets.
class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key, this.initialPage = 0});

  final int initialPage;

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  static const double _tileSize = 184;

  static const List<_Slide> _slides = [
    _Slide(
      'Flexible Loan Options',
      'Loan types to cater to different financial needs',
      [
        Icons.directions_car_outlined,
        Icons.two_wheeler_outlined,
        Icons.laptop_mac_outlined,
        Icons.smartphone_outlined,
      ],
    ),
    _Slide(
      'Instant Loan Approval',
      'Users will receive approval within minutes',
      [Icons.task_alt_outlined],
    ),
    _Slide('24x7 Customer Care', 'Dedicated customer support team', [
      Icons.support_agent_outlined,
    ]),
  ];

  PageController? _pageController;
  double? _viewportFraction;
  late int _page = widget.initialPage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fraction = _fractionFor(MediaQuery.sizeOf(context).width);

    if (fraction != _viewportFraction) {
      _pageController?.dispose();
      _viewportFraction = fraction;
      _pageController = PageController(
        initialPage: _page,
        viewportFraction: fraction,
      );
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  // A page must be wide enough that the neighbouring tile starts exactly at
  // the screen edge, so only the centred tile is visible and no icon is cut.
  static double _fractionFor(double screenWidth) {
    return (0.5 + _tileSize / (2 * screenWidth)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];

    return Column(
      children: [
        SizedBox(
          height: _tileSize,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (_, index) => _buildSlide(_slides[index]),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          slide.title,
          style: AppTextStyles.title.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 8),
        Text(
          slide.subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.slideSubtitle),
        ),
        const SizedBox(height: 16),
        _buildDots(),
      ],
    );
  }

  Widget _buildSlide(_Slide slide) {
    final isGrid = slide.icons.length > 1;

    return Center(
      child: isGrid
          ? _buildIconGrid(slide.icons)
          : Container(
              width: _tileSize,
              height: _tileSize,
              decoration: _tileDecoration(),
              child: Icon(slide.icons.first, size: 64, color: AppColors.white),
            ),
    );
  }

  Widget _buildIconGrid(List<IconData> icons) {
    return SizedBox(
      width: _tileSize,
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          for (final icon in icons)
            Container(
              width: 80,
              height: 80,
              decoration: _tileDecoration(),
              child: Icon(icon, size: 40, color: AppColors.white),
            ),
        ],
      ),
    );
  }

  BoxDecoration _tileDecoration() {
    return BoxDecoration(
      color: AppColors.slideTile,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _slides.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == _page ? AppColors.white : AppColors.slideDot,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
