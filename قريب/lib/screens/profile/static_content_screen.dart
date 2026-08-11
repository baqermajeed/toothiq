import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_spacing.dart';

/// شاشة محتوى ثابت قابلة لإعادة الاستخدام (سياسة الخصوصية، الشركة المطورة، الدعم).
/// العنوان والنص يُمرَّران عبر Get.arguments: {'title': String, 'body': String}.
/// يمكن تمرير نوع المحتوى عبر: {'type': 'privacy-policy'}.
class StaticContentScreen extends StatelessWidget {
  const StaticContentScreen({super.key});

  static const String _privacyPolicyType = 'privacy-policy';

  static String _getTitle(dynamic arguments) {
    if (arguments is Map && arguments['title'] != null) {
      return arguments['title'] as String;
    }
    return 'محتوى';
  }

  static String _getContentType(dynamic arguments) {
    if (arguments is Map && arguments['type'] != null) {
      return arguments['type'] as String;
    }
    return '';
  }

  static String _getBody(dynamic arguments) {
    if (arguments is Map && arguments['body'] != null) {
      return arguments['body'] as String;
    }
    return '';
  }

  static List<_ContentSection> _privacyPolicySections() {
    return [
      _ContentSection(
        title: 'المعلومات التي نجمعها',
        description: 'نجمع الحد الأدنى من البيانات اللازمة لتقديم الخدمة بشكل صحيح.',
        icon: Icons.inventory_2_rounded,
        bullets: [
          'معلومات الحساب: الاسم، رقم الهاتف، والبريد الإلكتروني عند التسجيل.',
          'معلومات الطلب: تفاصيل الطلب، العنوان، الملاحظات النصية أو الصوتية فقط.',
          'الموقع الجغرافي: لتحديد المتاجر القريبة، تعيين عنوان التوصيل، ومتابعة موقع السائق على الخريطة أثناء استخدام التطبيق فقط (بموافقتك).',
          'بيانات تقنية: نوع الجهاز، نظام التشغيل، ومعرّفات التطبيق لتحسين الأداء.',
        ],
      ),
      _ContentSection(
        title: 'كيف نستخدم معلوماتك',
        description: 'نستخدم البيانات فقط لتشغيل الخدمة وتطويرها.',
        icon: Icons.auto_fix_high_rounded,
        bullets: [
          'إنشاء الحساب وإدارة الطلبات والتوصيل.',
          'التواصل معك بخصوص الطلبات والتنبيهات المهمة.',
          'تحسين جودة الخدمة وتحليل الأعطال والأخطاء.',
          'منع الاحتيال والالتزام بالمتطلبات القانونية.',
        ],
      ),
      _ContentSection(
        title: 'مشاركة المعلومات',
        description: 'لا نبيع بياناتك لأي طرف.',
        icon: Icons.share_rounded,
        bullets: [
          'مشاركة البيانات اللازمة مع المتاجر ومزودي التوصيل لتنفيذ الطلب.',
          'مشاركة محدودة مع مزودي الخدمات (الخرائط للإشارة إلى موقعك وموقع السائق، والإشعارات).',
          'الإفصاح عند وجود التزام قانوني أو أمر قضائي.',
        ],
      ),
      _ContentSection(
        title: 'الاحتفاظ بالبيانات',
        description: 'نحتفظ بالبيانات للمدة اللازمة فقط.',
        icon: Icons.schedule_rounded,
        bullets: [
          'نحتفظ ببيانات الحساب طالما كان الحساب نشطاً.',
          'قد نحتفظ ببعض البيانات لفترة إضافية للامتثال القانوني.',
          'يمكنك طلب حذف الحساب والبيانات عبر الدعم داخل التطبيق.',
        ],
      ),
      _ContentSection(
        title: 'حماية البيانات',
        description: 'نطبق إجراءات تقنية وتنظيمية لحماية المعلومات.',
        icon: Icons.lock_rounded,
        bullets: [
          'تشفير البيانات أثناء النقل قدر الإمكان.',
          'ضوابط وصول داخلية لحماية البيانات.',
          'مراجعات دورية لتحسين الأمان.',
        ],
      ),
      _ContentSection(
        title: 'حقوق المستخدم',
        description: 'لديك السيطرة على بياناتك.',
        icon: Icons.verified_user_rounded,
        bullets: [
          'الاطلاع على بياناتك وتحديثها من داخل التطبيق.',
          'طلب حذف الحساب أو بعض البيانات.',
          'سحب صلاحية الموقع (أثناء الاستخدام) من إعدادات الجهاز في أي وقت.',
        ],
      ),
      _ContentSection(
        title: 'خصوصية الأطفال',
        description: 'الخدمة غير مخصصة للأطفال.',
        icon: Icons.child_care_rounded,
        bullets: [
          'لا نستهدف جمع بيانات من الأطفال دون السن القانوني.',
          'إذا تم ذلك عن طريق الخطأ يرجى التواصل معنا لحذفها.',
        ],
      ),
      _ContentSection(
        title: 'التحديثات على السياسة',
        description: 'قد نقوم بتحديث هذه السياسة من وقت لآخر.',
        icon: Icons.update_rounded,
        bullets: [
          'سنُظهر التعديلات الجوهرية داخل التطبيق.',
          'استمرارك في استخدام التطبيق يعني موافقتك على التحديثات.',
        ],
      ),
      _ContentSection(
        title: 'التواصل معنا',
        description: 'نستقبل استفساراتك المتعلقة بالخصوصية.',
        icon: Icons.support_agent_rounded,
        bullets: [
          'تواصل معنا عبر صفحة الدعم داخل التطبيق.',
          'أو عبر معلومات التواصل الموضحة في قسم الدعم.',
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final title = _getTitle(args);
    final contentType = _getContentType(args);
    final body = _getBody(args);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: contentType == _privacyPolicyType
            ? _PrivacyPolicyContent(sections: _privacyPolicySections())
            : _PlainContent(body: body),
      ),
    );
  }
}

class _PlainContent extends StatelessWidget {
  const _PlainContent({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      body,
      style: TextStyle(
        fontFamily: kFontFamilyCairo,
        fontSize: 16.sp,
        height: 1.6,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent({required this.sections});

  final List<_ContentSection> sections;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HighlightCard(
          title: 'نلتزم بحماية خصوصيتك',
          subtitle: 'آخر تحديث: 3 فبراير 2026',
          highlights: const [
            'نستخدم بياناتك لتقديم الخدمة وتحسينها فقط.',
            'لا نبيع بياناتك لأي طرف.',
            'يمكنك طلب حذف حسابك في أي وقت.',
          ],
        ),
        AppSpacing.verticalLg,
        ...sections.map((section) => _PolicySectionCard(
              section: section,
              backgroundColor: isDark ? colorScheme.surface.withValues(alpha: 0.45) : Colors.white,
              borderColor: isDark ? colorScheme.onSurface.withValues(alpha: 0.15) : colorScheme.primary.withValues(alpha: 0.2),
            )),
        AppSpacing.verticalMd,
        Text(
          'باستخدامك للتطبيق فإنك توافق على سياسة الخصوصية هذه.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontFamilyCairo,
            fontSize: 14.sp,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.subtitle,
    required this.highlights,
  });

  final String title;
  final String subtitle;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? colorScheme.primary.withValues(alpha: 0.15) : colorScheme.primary.withValues(alpha: 0.08);

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip_rounded, color: colorScheme.primary, size: 22.sp),
              AppSpacing.horizontalSm,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalSm,
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 13.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          AppSpacing.verticalMd,
          ...highlights.map((item) => _BulletRow(text: item)),
        ],
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  const _PolicySectionCard({
    required this.section,
    required this.backgroundColor,
    required this.borderColor,
  });

  final _ContentSection section;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(section.icon, color: colorScheme.primary, size: 20.sp),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontFamily: kFontFamilyCairo,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalSm,
          Text(
            section.description,
            style: TextStyle(
              fontFamily: kFontFamilyCairo,
              fontSize: 14.sp,
              height: 1.6,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          AppSpacing.verticalSm,
          ...section.bullets.map((item) => _BulletRow(text: item)),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.horizontalSm,
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: kFontFamilyCairo,
                fontSize: 14.sp,
                height: 1.6,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentSection {
  const _ContentSection({
    required this.title,
    required this.description,
    required this.bullets,
    required this.icon,
  });

  final String title;
  final String description;
  final List<String> bullets;
  final IconData icon;
}
