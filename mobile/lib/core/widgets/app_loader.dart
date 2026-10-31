import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = 24,
    this.color = AppColors.primary,
    this.message,
  });

  final double size;
  final Color color;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
