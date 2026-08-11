import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../../widget/section/section_app_bar.dart';
import '../../widget/settings/info_page_widgets.dart';
import 'contact_us_page.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static void open() => Get.to(() => const HelpPage());

  static const _faqs = [
    (
      'كيف أطلب منتجاً من التطبيق؟',
      'تصفح المنتجات، أضفها إلى السلة، ثم أكمل خطوات الطلب بإدخال معلوماتك وعنوان التوصيل وطريقة الدفع.',
    ),
    (
      'هل المنتجات أصلية ومضمونة؟',
      'نعم، نتعامل مع متاجر معتمدة فقط، وكل منتج يخضع لمعايير جودة صارمة قبل عرضه في المنصة.',
    ),
    (
      'كيف أتتبع طلبي؟',
      'يمكنك متابعة حالة طلبك من صفحة «طلباتك» حيث تظهر كل المراحل من التأكيد حتى التوصيل.',
    ),
    (
      'هل التوصيل متاح لكل المحافظات؟',
      'نغطي معظم المحافظات العراقية، ويتم تأكيد إمكانية التوصيل لعنوانك عند إتمام الطلب.',
    ),
    (
      'كيف أعدّل معلوماتي أو عنواني؟',
      'من صفحة الأعدادات يمكنك تعديل ملفك الشخصي وإدارة عناوين التوصيل المحفوظة بكل سهولة.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.settingsPageBackground,
        appBar: const SectionAppBar(title: 'المساعدة'),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoPageHero(
                icon: Icons.help_outline_rounded,
                title: 'كيف يمكننا\nمساعدتك؟',
                subtitle:
                    'إجابات سريعة لأكثر الأسئلة شيوعاً — وإذا احتجت المزيد، فريقنا جاهز لخدمتك.',
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _QuickHelpCard(
                            icon: Icons.shopping_bag_outlined,
                            title: 'الطلبات',
                            color: AppColors.productStore,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _QuickHelpCard(
                            icon: Icons.local_shipping_outlined,
                            title: 'التوصيل',
                            color: const Color(0xFF5C6BC0),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _QuickHelpCard(
                            icon: Icons.payments_outlined,
                            title: 'الدفع',
                            color: AppColors.settingsIcon,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),
                    const InfoSectionTitle(
                      title: 'الأسئلة الشائعة',
                      badge: 'FAQ',
                    ),
                    SizedBox(height: 14.h),
                    ..._faqs.map(
                      (faq) => InfoFaqTile(
                        question: faq.$1,
                        answer: faq.$2,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Material(
                      color: AppColors.bottomNavBackground,
                      borderRadius: BorderRadius.circular(22.r),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: ContactUsPage.open,
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Row(
                            children: [
                              Container(
                                width: 48.w,
                                height: 48.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Icon(
                                  Icons.headset_mic_rounded,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    MyText(
                                      'لم تجد إجابتك؟',
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      textAlign: TextAlign.right,
                                    ),
                                    SizedBox(height: 4.h),
                                    MyText(
                                      'تواصل مع فريق الدعم الآن',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70,
                                size: 16.sp,
                              ),
                            ],
                          ),
                        ),
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

class _QuickHelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _QuickHelpCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.settingsCardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.orderCardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(height: 10.h),
          MyText(
            title,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.productTitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
