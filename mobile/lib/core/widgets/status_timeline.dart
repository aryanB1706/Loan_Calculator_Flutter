import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum TimelineState { done, current, pending, failed }

class TimelineStep {
  const TimelineStep({required this.title, required this.state, this.subtitle});

  final String title;
  final TimelineState state;
  final String? subtitle;
}

/// Vertical list of outlined steps joined by a line, as in the status design.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) _buildConnector(steps[i]),
          _buildStep(steps[i]),
        ],
      ],
    );
  }

  Widget _buildConnector(TimelineStep next) {
    final reached = next.state != TimelineState.pending;

    return Container(
      width: 2,
      height: 16,
      color: reached ? _color(next.state) : AppColors.border,
    );
  }

  Widget _buildStep(TimelineStep step) {
    final color = _color(step.state);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(_icon(step.state), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(color: color),
                ),
                if (step.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          // Balances the leading icon so the title stays centred.
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Color _color(TimelineState state) {
    switch (state) {
      case TimelineState.done:
        return AppColors.success;
      case TimelineState.current:
        return AppColors.primary;
      case TimelineState.failed:
        return AppColors.error;
      case TimelineState.pending:
        return AppColors.textMuted;
    }
  }

  IconData _icon(TimelineState state) {
    switch (state) {
      case TimelineState.done:
        return Icons.event_available_outlined;
      case TimelineState.failed:
        return Icons.event_busy_outlined;
      case TimelineState.current:
      case TimelineState.pending:
        return Icons.event_note_outlined;
    }
  }
}
