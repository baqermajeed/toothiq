import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/orders_controller.dart';
import '../dialogs/guest_register_dialog.dart';
import '../dialogs/order_success_credentials_dialog.dart';
import '../dialogs/order_success_dialog.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_button.dart';
import '../common/app_toast.dart';
import '../common/app_spacing.dart';
import '../common/app_text_field.dart';
import '../common/hold_to_record_button.dart';

/// عرض لوحة ملاحظات الطلب (نص + صوت) ثم إرسال الطلب.
/// إن كان المستخدم ضيفاً، يعرض GuestRegisterDialog أولاً.
/// [onOrderSuccess] يُستدعى عند إتمام الطلب بنجاح (مثلاً لإغلاق السلة الجانبية والانتقال).
Future<void> showOrderNotesSheet({void Function()? onOrderSuccess}) async {
  final auth = Get.find<AuthController>();
  GuestRegisterResult? guestCredentials;
  if (!auth.isAuthenticated) {
    final result = await showGuestRegisterDialog();
    if (result == null) return;
    guestCredentials = result;
  }
  Get.bottomSheet(
    OrderNotesSheet(
      onOrderSuccess: onOrderSuccess,
      guestCredentials: guestCredentials,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    ignoreSafeArea: false,
  );
}

class OrderNotesSheet extends StatefulWidget {
  const OrderNotesSheet({
    super.key,
    this.onOrderSuccess,
    this.guestCredentials,
  });

  final void Function()? onOrderSuccess;
  final GuestRegisterResult? guestCredentials;

  @override
  State<OrderNotesSheet> createState() => _OrderNotesSheetState();
}

class _OrderNotesSheetState extends State<OrderNotesSheet> {
  final TextEditingController _notesController = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();

  String? _audioPath;
  bool _isRecording = false;
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // طلب صلاحية الميكروفون (مهم على iOS — يجب وجود NSMicrophoneUsageDescription في Info.plist)
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          AppToast.show(
            'صلاحية الميكروفون',
            'نحتاج صلاحية الميكروفون لتسجيل ملاحظتك الصوتية مع الطلب وإرسالها للمحل. يرجى السماح من الإعدادات إن رغبت بالتسجيل.',
            type: ToastType.warning,
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/order_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100), path: path);
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) {
        AppToast.show(
          'التسجيل',
          'فشل بدء التسجيل. نحتاج صلاحية الميكروفون لتسجيل الملاحظة الصوتية مع الطلب. تأكد من منح الصلاحية من الإعدادات.',
          type: ToastType.warning,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _recorder.stop();
      if (mounted && path != null && path.isNotEmpty) {
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
      } else if (mounted) {
        setState(() => _isRecording = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  void _removeAudio() {
    setState(() => _audioPath = null);
  }

  Future<String?> _uploadAudio() async {
    if (_audioPath == null || _audioPath!.isEmpty) return null;
    final file = File(_audioPath!);
    if (!await file.exists()) return null;
    final api = Get.find<AuthController>().apiClient;
    final url = await api.uploadOrderNoteAudio(_audioPath!);
    return url;
  }

  Future<void> _submit() async {
    final notes = _notesController.text.trim();
    setState(() => _isSubmitting = true);

    String? notesAudioUrl;
    if (_audioPath != null) {
      setState(() => _isUploading = true);
      try {
        notesAudioUrl = await _uploadAudio();
      } on ApiException catch (e) {
        debugPrint('[OrderNotes] رفع الصوت - ApiException: ${e.message}');
        if (kDebugMode && e.statusCode != null) {
          debugPrint('[OrderNotes] statusCode: ${e.statusCode}');
        }
        setState(() {
          _isSubmitting = false;
          _isUploading = false;
        });
        final userMessage = e.statusCode == 403 && e.message.toLowerCase().contains('disabled')
            ? 'حسابك معطّل. يرجى التواصل مع الدعم لتفعيله.'
            : e.message;
        AppToast.show('رفع الصوت', userMessage, type: ToastType.error, duration: const Duration(seconds: 4));
        return;
      } catch (e, st) {
        debugPrint('[OrderNotes] فشل رفع الملاحظة الصوتية: $e');
        debugPrint('[OrderNotes] StackTrace: $st');
        setState(() {
          _isSubmitting = false;
          _isUploading = false;
        });
        AppToast.show('رفع الصوت', 'فشل رفع الملاحظة الصوتية', type: ToastType.error);
        return;
      }
      setState(() => _isUploading = false);
    }

    final cart = Get.find<CartController>();
    final order = await cart.completeOrderFromCart(
      notes: notes.isEmpty ? null : notes,
      notesAudioUrl: notesAudioUrl,
    );
    setState(() => _isSubmitting = false);
    if (order != null && mounted) {
      Get.back();
      void onDone() {
        if (Get.isRegistered<OrdersController>()) {
          Get.find<OrdersController>().loadOrders();
        }
        widget.onOrderSuccess?.call();
      }
      final creds = widget.guestCredentials;
      if (creds != null) {
        showOrderSuccessWithCredentialsDialog(
          phone: creds.phone,
          code: creds.code,
          orderId: order.id,
          onClose: onDone,
        );
      } else {
        showOrderSuccessDialog(orderId: order.id, onClose: onDone);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? colorScheme.surfaceContainerHighest : Colors.white;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    'ملاحظات الطلب',
                    style: TextStyle(
                      fontFamily: kFontFamilyCairo,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close_rounded, size: 24.sp, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Divider(height: 1.h, color: AppColors.border.withValues(alpha: 0.6)),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ملاحظة كتابية (اختياري)',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    AppTextField(
                      controller: _notesController,
                      hint: 'مثال: أريد الطلب يكون باجر يجيني',
                      maxLines: 3,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'ملاحظة صوتية (اختياري) — اضغط مع الاستمرار للتسجيل، ارفع لإيقاف',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'لماذا الميكروفون؟ لتسجيل ملاحظتك الصوتية وإرفاقها بالطلب وإرسالها للمحل فقط.',
                      style: TextStyle(
                        fontFamily: kFontFamilyCairo,
                        fontSize: 12.sp,
                        height: 1.35,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (_audioPath == null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: HoldToRecordButton(
                          isRecording: _isRecording,
                          onRecordingStart: _startRecording,
                          onRecordingStop: _stopRecording,
                          // minHeight: 52.h,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.audiotrack_rounded, size: 24.sp, color: colorScheme.primary),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'ملاحظة صوتية مرفقة',
                                style: TextStyle(
                                  fontFamily: kFontFamilyCairo,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _removeAudio,
                              icon: Icon(Icons.delete_outline_rounded, size: 22.sp, color: colorScheme.error),
                              tooltip: 'حذف',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg + 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'إلغاء',
                      outlined: true,
                      // minHeight: 52.h,
                      onPressed: _isSubmitting ? null : () => Get.back(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'إرسال الطلب',
                      // minHeight: 52.h,
                      loading: _isSubmitting || _isUploading,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
