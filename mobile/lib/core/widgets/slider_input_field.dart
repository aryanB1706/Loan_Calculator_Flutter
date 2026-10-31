import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A label with a small editable value box, and a slider underneath.
/// Typing and sliding edit the same value; the owner keeps them in sync.
class SliderInputField extends StatelessWidget {
  const SliderInputField({
    super.key,
    required this.label,
    required this.textController,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.minLabel,
    required this.maxLabel,
    required this.onSliderChanged,
    required this.onTextChanged,
    required this.onEditingComplete,
    this.prefixText,
    this.suffixText,
  });

  final String label;
  final TextEditingController textController;
  final double sliderValue;
  final double min;
  final double max;
  final int divisions;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onEditingComplete;
  final String? prefixText;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 140, child: _buildValueBox()),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: _sliderTheme(context),
          child: Slider(
            value: sliderValue.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onSliderChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: AppTextStyles.caption),
            Text(maxLabel, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildValueBox() {
    return TextField(
      controller: textController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyLarge,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onTextChanged,
      onEditingComplete: onEditingComplete,
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        onEditingComplete();
      },
      decoration: InputDecoration(
        isDense: true,
        prefixText: prefixText,
        suffixText: suffixText,
        prefixStyle: AppTextStyles.bodyLarge,
        suffixStyle: AppTextStyles.bodyLarge,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      trackHeight: 14,
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.sliderTrack,
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      overlayShape: SliderComponentShape.noOverlay,
      thumbShape: const _BarThumbShape(),
      trackShape: const RoundedRectSliderTrackShape(),
    );
  }
}

class _BarThumbShape extends SliderComponentShape {
  const _BarThumbShape();

  static const double _width = 4;
  static const double _height = 34;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(_width, _height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: _width, height: _height),
      const Radius.circular(AppSizes.radiusSmall),
    );
    context.canvas.drawRRect(rect, Paint()..color = AppColors.primary);
  }
}
