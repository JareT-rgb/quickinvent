import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NumericKeypad extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChange;

  const NumericKeypad({
    super.key,
    required this.controller,
    this.onChange,
  });

  void _onKeyPress(String value) {
    if (value == 'C') {
      controller.clear();
    } else if (value == 'DEL') {
      final text = controller.text;
      if (text.isNotEmpty) {
        controller.text = text.substring(0, text.length - 1);
      }
    } else if (value == '.') {
      if (!controller.text.contains('.')) {
        controller.text += value;
      }
    } else {
      controller.text += value;
    }
    
    // Set cursor to end
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    
    if (onChange != null) {
      onChange!();
    }
  }

  Widget _buildKey(String text, {Color? color, IconData? icon}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: color ?? AppTheme.surface,
          borderRadius: AppTheme.radiusSmall,
          elevation: 1,
          child: InkWell(
            borderRadius: AppTheme.radiusSmall,
            onTap: () => _onKeyPress(text),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: AppTheme.textPrimary)
                  : Text(
                      text,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _buildKey('C', color: AppTheme.error.withValues(alpha: 0.1)),
              _buildKey('0'),
              _buildKey('DEL', icon: Icons.backspace_outlined, color: AppTheme.warning.withValues(alpha: 0.1)),
            ],
          ),
        ),
      ],
    );
  }
}
