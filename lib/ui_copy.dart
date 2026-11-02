// lib/ui_copy.dart
// ============================================================
// نصوص إرشادية موحّدة لتجربة المستخدم (عربي بسيط)
// ============================================================

import 'config.dart';

/// نصوص التوضيحات والشروحات في الواجهة.
/// لا تضع هنا منطق أعمال — نصوص عرض فقط.
class UiCopy {
  UiCopy._();

  // ─── آيات (نص المصحف مع اسم السورة ورقم الآية) ───
  static const String ayahSakinah =
      'وَمِنْ آيَاتِهِ أَنْ خَلَقَ لَكُم مِّنْ أَنفُسِكُمْ أَزْوَاجًا لِّتَسْكُنُوا إِلَيْهَا وَجَعَلَ بَيْنَكُم مَّوَدَّةً وَرَحْمَةً ۚ إِنَّ فِي ذَٰلِكَ لَآيَاتٍ لِّقَوْمٍ يَتَفَكَّرُونَ';
  static const String ayahSakinahRef = 'سورة الروم، الآية 21';

  static const String ayahNikah =
      'وَأَنكِحُوا الْأَيَامَىٰ مِنكُمْ وَالصَّالِحِينَ مِنْ عِبَادِكُمْ وَإِمَائِكُمْ ۚ إِن يَكُونُوا فُقَرَاءَ يُغْنِهِمُ اللَّهُ مِن فَضْلِهِ ۗ وَاللَّهُ وَاسِعٌ عَلِيمٌ';
  static const String ayahNikahRef = 'سورة النور، الآية 32';

  static const String ayahQurrat =
      'وَالَّذِينَ يَقُولُونَ رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا';
  static const String ayahQurratRef = 'سورة الفرقان، الآية 74';

  // ─── مقدمة ───
  static const String introWelcomeTitle = 'ميثاق';
  static const String introWelcomeTagline = 'تيسير الزواج الشرعي';

  /// ملخص الصفحات التعريفية القديمة في سطرين قصيرين.
  static const String introSummary =
      'زواج جاد في سوريا بخصوصية، والولي حاضر حين يلزم. '
      'تكمل ملفك وتراجعه الإدارة ثم تختار رغباتك، '
      'وتطلب قاعة أو تصويراً أو تنظيماً من هنا.';

  static const String introSummaryNote =
      'الجدية • الخصوصية • الولي • قاعة • تصوير';

  static const String introStartButton = 'أبدأ على بركة الله';

  // ─── تسجيل / دخول ───
  static const String authMarriageHint =
      'حساب الزواج للشاب أو الفتاة الراغبين في زواج شرعي. '
      'بعد التسجيل تراجع الإدارة ملفك قبل التفعيل.';

  static const String authServicesHint =
      'حساب الخدمات فقط لمن يريد تصفّح خدمات الأعراس وحجزها، '
      'دون مسار التعارف للزواج.';

  static const String authAfterSignupHint =
      'بعد إكمال الملف تنتقل إلى الصفحة الرئيسية وتكمل رحلتك بهدوء.';

  static const String authLoginTitle = 'أهلاً بعودتك';
  static const String authSignupTitle = 'ابدأ حسابك في ميثاق';
  static const String authLoginSubtitle =
      'ادخل لمتابعة ملفك ورحلتك في ميثاق.';
  static const String authSignupSubtitle =
      'خطوة جادة نحو زواج شرعي، في بيئة واضحة وموثوقة.';
  static const String authSignupButton = 'أنشئ الحساب على بركة الله';
  static const String authLoginButton = 'تسجيل الدخول';

  // ─── انتظار التحقق (للحالات الإدارية القديمة إن وُجدت) ───
  static const String waitingTitle = 'حسابك قيد المراجعة';
  static const String waitingBody =
      'الإدارة تراجع حسابك الآن. '
      'لا حاجة لتحديث الصفحة بنفسك؛ نتحقق من التفعيل تلقائياً.';

  static const String waitingWhatChecked =
      'يُراجع عادة اكتمال الملف وملاءمة البيانات.';

  // ─── الرئيسية ───
  static const String homeWelcomeHint =
      'مساران: زواج شرعي جاد، وخدمات تيسّر العرس.';

  static const String homeMarriageCardTitle = 'مسار الزواج';
  static const String homeMarriageCardBody =
      'تصفّح الملفات المناسبة، أرسل رغباتك، وتواصل ضمن ضوابط تحفظ الكرامة.';

  static const String homeServicesCardTitle = 'خدمات الأعراس';
  static const String homeServicesCardBody =
      'اختر مزود الخدمة واطلب الحجز. الإدارة تراجع الطلب قبل التأكيد.';

  static const String homeServicesAction = 'تصفّح خدمات العرس';

  static const String homeSettingsCardTitle = 'الإعدادات والحساب';
  static const String homeSettingsCardBody =
      'تحديث كلمة المرور، التواصل مع الإدارة، أو إدارة حسابك.';

  // ─── استكشاف / رغبات ───
  static String get explorationGroomHint =>
      'يمكنك اختيار حتى ${AppConfig.maxGroomRequests} رغبات في الطلب الواحد. '
      'الهوية تظهر برمز يحفظ الخصوصية حتى مراحل لاحقة.';

  static const String explorationBrideHint =
      'تظهر لك الرغبات الواردة لتراجعيها. القبول يفتح تواصلاً منظماً داخل المنصة.';

  static const String explorationPrivacyHint =
      'أرقام الهواتف لا تُعرض في هذه المرحلة. التواصل يبدأ داخل المنصة.';

  // ─── تبادل التواصل (بدل المحادثة) ───
  static String get chatRulesShort =>
      'بعد تأكيد الشاب للصورة يطلب من الطرفين دفع رسوم تبادل التواصل، '
      'ثم يراجع المشرف ويوافق على إظهار الأرقام.';

  static String get chatRulesLong =>
      '• بعد موافقة الفتاة يؤكد الشاب بعد رؤية الصورة.\n'
      '• يدفع الطرفان رسوم تبادل التواصل عبر شام كاش.\n'
      '• المشرف يراجع الدفع ثم يوافق على تبادل الأرقام.\n'
      '• بيانات التواصل تظهر فقط بعد موافقة الإدارة.';

  static const String chatAdminReviewHint =
      'بانتظار مراجعة الإدارة قبل إظهار بيانات التواصل.';

  // ─── خدمات ───
  static const String servicesBrowseHint =
      'هذه خدمات معتمدة. إرسال الحجز طلب مراجعة، '
      'وليس دفعاً إلكترونياً داخل التطبيق.';

  static const String serviceDetailBookHint =
      'بعد الإرسال تتابع الإدارة الطلب مع مزود الخدمة. '
      'حالة الطلب تظهر في «حجوزاتي».';

  static const String bookingsStatusHint =
      'بعد قبول الطلب ارفع إشعار العربون. عند تأكيده يصبح الحجز جاهزاً، '
      'ثم يكتمل بعد تنفيذ الخدمة.';

  static const String partyRequestHint =
      'طلب تنظيم المناسبة يُرسل للإدارة مع الخدمات التي اخترتها. '
      'إن طُلب إثبات دفع، فارفعه من المسار المخصص في حسابك.';
}
