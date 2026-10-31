import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One hidden text field receives the typing (so paste and SMS autofill work)
/// while the boxes only display its characters.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.length,
    required this.onChanged,
    this.controller,
    this.hasError = false,
    this.enabled = true,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool hasError;
  final bool enabled;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  static const double _boxHeight = 50;
  static const double _boxGap = 10;

  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: _boxGap),
                Expanded(child: _buildBox(i)),
              ],
            ],
          ),
          Positioned.fill(child: _buildHiddenField()),
        ],
      ),
    );
  }

  Widget _buildHiddenField() {
    return Opacity(
      opacity: 0,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: true,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: widget.length,
        enableInteractiveSelection: false,
        showCursor: false,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: widget.onChanged,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBox(int index) {
    final text = _controller.text;
    final isFilled = index < text.length;
    final isActive =
        _focusNode.hasFocus && index == text.length.clamp(0, widget.length - 1);

    return Container(
      height: _boxHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: _borderColor(isActive),
          width: isActive ? 1.4 : 1,
        ),
      ),
      child: Text(isFilled ? text[index] : '', style: AppTextStyles.heading),
    );
  }

  Color _borderColor(bool isActive) {
    if (widget.hasError) {
      return AppColors.error;
    }
    return isActive ? AppColors.primary : AppColors.border;
  }
}
