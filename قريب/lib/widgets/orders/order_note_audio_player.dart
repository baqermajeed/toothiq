import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_toast.dart';

/// مشغّل ملاحظة صوتية للطلب. يعرض زر تشغيل/إيقاف.
class OrderNoteAudioPlayer extends StatefulWidget {
  const OrderNoteAudioPlayer({
    super.key,
    required this.audioUrl,
  });

  /// رابط الملاحظة الصوتية (قد يكون نسبياً من الـ API).
  final String? audioUrl;

  @override
  State<OrderNoteAudioPlayer> createState() => _OrderNoteAudioPlayerState();
}

class _OrderNoteAudioPlayerState extends State<OrderNoteAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  String get _fullUrl {
    final url = widget.audioUrl;
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final base = ApiConfig.baseUrl.endsWith('/') ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1) : ApiConfig.baseUrl;
    return base + (url.startsWith('/') ? url : '/$url');
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final url = _fullUrl;
    if (url.isEmpty) return;
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _player.play(UrlSource(url));
      setState(() {
        _isLoading = false;
        _isPlaying = true;
      });
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.show('تشغيل الصوت', 'تعذّر تشغيل الملاحظة الصوتية', type: ToastType.error);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        IconButton.filled(
          onPressed: _isLoading ? null : _togglePlay,
          icon: _isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                )
              : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 24.sp),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: EdgeInsets.all(10.r),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'ملاحظة صوتية',
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
