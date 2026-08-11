import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_theme.dart';

/// زر تسجيل صوتي: عند الضغط يبدأ التسجيل، وعند رفع الإصبع يتوقف.
/// [isRecording] من الـ controller/state.
/// [onRecordingStart] يُستدعى عند الضغط، [onRecordingStop] عند الرفع أو الإلغاء.
class HoldToRecordButton extends StatelessWidget {
  const HoldToRecordButton({
    super.key,
    required this.isRecording,
    required this.onRecordingStart,
    required this.onRecordingStop,
    this.label,
    this.recordingLabel,
    this.minHeight,
  });

  final bool isRecording;
  final VoidCallback onRecordingStart;
  final VoidCallback onRecordingStop;
  /// النص عند عدم التسجيل (افتراضي: اضغط للتسجيل).
  final String? label;
  /// النص أثناء التسجيل (افتراضي: ارفع لإيقاف التسجيل).
  final String? recordingLabel;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.4)
        : colorScheme.outline.withValues(alpha: 0.6);

    return GestureDetector(
      onTapDown: (_) => onRecordingStart(),
      onTapUp: (_) => onRecordingStop(),
      onTapCancel: () => onRecordingStop(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: minHeight != null ? 0 : 16.h),
        constraints: minHeight != null ? BoxConstraints(minHeight: minHeight!) : null,
        decoration: BoxDecoration(
          color: isRecording
              ? colorScheme.errorContainer.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isRecording ? colorScheme.error : borderColor,
            width: isRecording ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              size: 24.sp,
              color: isRecording ? colorScheme.error : colorScheme.primary,
            ),
            SizedBox(width: 10.w),
            Text(
              isRecording
                  ? (recordingLabel ?? 'ارفع لإيقاف التسجيل')
                  : (label ?? 'اضغط للتسجيل'),
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: isRecording ? colorScheme.onErrorContainer : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
