import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/app_colors.dart';
import '../my_text.dart';
import 'app_image.dart';

class ImagePickerBox extends StatelessWidget {
  const ImagePickerBox({
    super.key,
    required this.label,
    required this.imagePath,
    required this.onPicked,
    this.size = 120,
    this.shape = BoxShape.rectangle,
    this.icon = Icons.add_a_photo_outlined,
  });

  final String label;
  final String? imagePath;
  final ValueChanged<String> onPicked;
  final double size;
  final BoxShape shape;
  final IconData icon;

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText('اختر مصدر الصورة', fontSize: 16.sp),
              SizedBox(height: 16.h),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('من المعرض', style: TextStyle(fontFamily: 'Expo Arabic')),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('الكاميرا', style: TextStyle(fontFamily: 'Expo Arabic')),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file != null) onPicked(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final radius = shape == BoxShape.circle
        ? BorderRadius.circular(size.w)
        : BorderRadius.circular(16.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(label, fontSize: 13.sp, fontWeight: FontWeight.w600),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _pick(context),
          child: Stack(
            children: [
              AppImage(
                path: imagePath,
                width: size.w,
                height: size.w,
                borderRadius: radius,
                icon: icon,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.vertical(
                      bottom: shape == BoxShape.circle
                          ? Radius.circular(size.w)
                          : Radius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 14.sp),
                      SizedBox(width: 4.w),
                      MyText(
                        imagePath == null ? 'إضافة' : 'تغيير',
                        fontSize: 11.sp,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GalleryImagePicker extends StatelessWidget {
  const GalleryImagePicker({
    super.key,
    required this.images,
    required this.onChanged,
    this.maxImages = 4,
  });

  final List<String> images;
  final ValueChanged<List<String>> onChanged;
  final int maxImages;

  Future<void> _addImage(BuildContext context) async {
    if (images.length >= maxImages) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      onChanged([...images, file.path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MyText('صور إضافية للمنتج', fontSize: 13.sp, fontWeight: FontWeight.w600),
            const Spacer(),
            MyText(
              '${images.length}/$maxImages',
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 80.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final path in images)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Stack(
                    children: [
                      AppImage(
                        path: path,
                        width: 80.w,
                        height: 80.w,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () {
                            onChanged(images.where((p) => p != path).toList());
                          },
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 14.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (images.length < maxImages)
                GestureDetector(
                  onTap: () => _addImage(context),
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Icon(Icons.add, color: AppColors.primary, size: 28.sp),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
