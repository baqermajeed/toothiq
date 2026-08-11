import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/section/section_app_bar.dart';
import '../../widget/settings/info_page_widgets.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  static void open() => Get.to(() => const ContactUsPage());

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.settingsPageBackground,
        appBar: const SectionAppBar(title: 'تواصل معنا'),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoPageHero(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'نحن هنا\nلخدمتك دائماً',
                subtitle:
                    'فريق الدعم جاهز للإجابة على استفساراتك ومساعدتك في أي وقت — بأسلوب محترف وودّي.',
                gradientColors: [
                  Color(0xFFF3F0E8),
                  Color(0xFFFAF8F4),
                  Colors.white,
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const InfoSectionTitle(
                      title: 'قنوات التواصل',
                      badge: 'مباشر',
                    ),
                    SizedBox(height: 14.h),
                    const InfoContactTile(
                      icon: Icons.phone_in_talk_rounded,
                      iconColor: AppColors.productStore,
                      iconBg: AppColors.primaryLight,
                      title: 'الهاتف',
                      value: '0770 000 0000',
                    ),
                    SizedBox(height: 10.h),
                    const InfoContactTile(
                      icon: Icons.mail_outline_rounded,
                      iconColor: Color(0xFF5C6BC0),
                      iconBg: Color(0xFFEEF0FB),
                      title: 'البريد الإلكتروني',
                      value: 'support@dentalstore.iq',
                    ),
                    SizedBox(height: 10.h),
                    const InfoContactTile(
                      icon: Icons.chat_rounded,
                      iconColor: Color(0xFF25D366),
                      iconBg: Color(0xFFE8F9EF),
                      title: 'واتساب',
                      value: 'راسلنا مباشرة',
                    ),
                    SizedBox(height: 10.h),
                    const InfoContactTile(
                      icon: Icons.camera_alt_outlined,
                      iconColor: Color(0xFFE1306C),
                      iconBg: Color(0xFFFDEEF3),
                      title: 'انستغرام',
                      value: '@dental_store_iq',
                    ),
                    SizedBox(height: 28.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(
                          color: AppColors.orderDetailCardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52.w,
                            height: 52.w,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              Icons.support_agent_rounded,
                              color: AppColors.productStore,
                              size: 28.sp,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                MyText(
                                  'متوسط وقت الرد',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  textAlign: TextAlign.right,
                                ),
                                SizedBox(height: 4.h),
                                MyText(
                                  'أقل من 30 دقيقة',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.productTitle,
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
