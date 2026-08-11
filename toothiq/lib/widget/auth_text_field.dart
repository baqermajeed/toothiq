import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_colors.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData icon;
  final String? errorText;
  final TextInputType keyboardType;
  final bool readOnly;
  final bool isPassword;
  final VoidCallback? onTap;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    this.controller,
    required this.hint,
    required this.icon,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.isPassword = false,
    this.onTap,
    this.trailing,
    this.onChanged,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;

  bool get _hasError => (widget.errorText ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: _hasError ? AppColors.error : const Color(0xFFE5E7EB),
              width: _hasError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            readOnly: widget.readOnly,
            obscureText: widget.isPassword && _obscure,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Expo Arabic',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontFamily: 'Expo Arabic',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
              prefixIcon: Padding(
                padding: EdgeInsetsDirectional.only(end: 4.w),
                child: Icon(
                  widget.icon,
                  color: AppColors.textSecondary,
                  size: 22.sp,
                ),
              ),
              suffixIcon: _buildSuffix(),
            ),
          ),
        ),
        if (_hasError) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.info_outline,
                size: 16.sp,
                color: AppColors.error,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  widget.errorText!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Expo Arabic',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffix() {
    if (widget.isPassword) {
      return IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 22.sp,
        ),
      );
    }

    if (widget.trailing == null) return null;

    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8.w),
      child: widget.trailing,
    );
  }
}
