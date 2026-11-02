import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../widgets/islamic_decorations.dart';

class TermsScreen extends StatefulWidget {
  final bool isGroomRole;

  const TermsScreen({
    Key? key,
    this.isGroomRole = true,
  }) : super(key: key);

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _accepted = false;

  // ============================================================
  // عنوان القسم
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primarySoftGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.goldLight,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.goldDark,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة الشرط
  // ============================================================

  Widget _buildTerm(
    String title,
    String body,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(
              top: 6,
            ),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  body,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة إخلاء المسؤولية
  // ============================================================

  Widget _buildDisclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.goldLight,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.goldDark,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'المنصة وسيط رقمي لتيسير التعارف الشرعي فقط.\n'
              'لا تتحمل المنصة مسؤولية القرارات النهائية للطرفين.\n'
              'يُنصح بالاستخارة والاستشارة قبل أي قرار.\n'
              'المنصة غير مسؤولة عن أي سوء استخدام من المستخدمين.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.8,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة الموافقة
  // ============================================================

  Widget _buildAcceptanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: _accepted
            ? AppColors.successLight
            : AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _accepted
              ? AppColors.success.withValues(
                  alpha: 0.45,
                )
              : AppColors.border,
          width: _accepted ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _accepted = !_accepted;
          });
        },
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: _accepted,
              onChanged: (value) {
                setState(() {
                  _accepted = value ?? false;
                });
              },
              activeColor: AppColors.primary,
              checkColor: Colors.white,
            ),

            const SizedBox(width: 4),

            const Expanded(
              child: Text(
                'أوافق على كافة الضوابط الشرعية وشروط الاستخدام وأتعهد بالصدق والجدية',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // البناء
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final title = widget.isGroomRole
        ? 'شروط التسجيل للشاب'
        : 'شروط التسجيل للفتاة';

    return IslamicScaffold(
      appBar: IslamicAppBar(
        title: title,
      ),
      body: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth > 760
                    ? 700.0
                    : constraints.maxWidth;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            // ==================================================
                            // رأس الصفحة
                            // ==================================================

                            Container(
                              padding:
                                  const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient:
                                    AppColors.primaryGradient,
                                borderRadius:
                                    BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(
                                      alpha: 0.16,
                                    ),
                                    blurRadius: 18,
                                    offset:
                                        const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration:
                                        BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white
                                          .withValues(
                                        alpha: 0.12,
                                      ),
                                      border: Border.all(
                                        color: AppColors
                                            .goldLight,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      color: AppColors
                                          .goldLight,
                                      size: 29,
                                    ),
                                  ),

                                  const SizedBox(width: 15),

                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          'وثيقة الضوابط',
                                          textAlign:
                                              TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'الشروط الشرعية وشروط الاستخدام',
                                          textAlign:
                                              TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            height: 1.5,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            const Text(
                              'باستخدامك للتطبيق فأنت توافق على كافة الشروط التالية:',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.7,
                                color:
                                    AppColors.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ==================================================
                            // أولاً
                            // ==================================================

                            _buildSectionTitle(
                              'أولاً: الضوابط الشرعية والأخلاقية',
                              Icons.auto_awesome_outlined,
                            ),

                            _buildTerm(
                              '1. النية الصادقة والجدية',
                              'الهدف الوحيد من التسجيل هو السعي للزواج الشرعي الموثق. يمنع منعاً باتاً أي استخدام آخر للتطبيق.',
                            ),

                            _buildTerm(
                              '2. رعاية الأهل وموافقة الولي',
                              'يُشترط علم ولي أمر الفتاة وموافقته الصريحة على التسجيل والتواصل. لا يمكن للفتاة التسجيل بدون ولي.',
                            ),

                            _buildTerm(
                              '3. الصدق والشفافية',
                              'توفير معلومات صحيحة ودقيقة 100%. أي معلومة خاطئة تؤدي للحظر النهائي.',
                            ),

                            _buildTerm(
                              '4. غض البصر وحفظ الخصوصية',
                              'يُمنع تداول أي بيانات شخصية أو صور خارج التطبيق. الالتزام بغض البصر واجب شرعي.',
                            ),

                            _buildTerm(
                              '5. الالتزام بالآداب الإسلامية',
                              'الالتزام بالحوار المهذب والجاد. يمنع المزاح غير اللائق أو الكلام الخارج.',
                            ),

                            const SizedBox(height: 12),

                            // ==================================================
                            // ثانياً
                            // ==================================================

                            _buildSectionTitle(
                              'ثانياً: شروط الاستخدام والأمان',
                              Icons.security_outlined,
                            ),

                            _buildTerm(
                              '1. توثيق الحسابات',
                              'يحق للتطبيق طلب وسائل توثيق إضافية (هوية، دفتر عائلة، مكالمة تحقق).',
                            ),

                            _buildTerm(
                              '2. سياسة التواصل',
                              'التواصل مع الولي فقط بعد موافقته الصريحة. المحادثة محدودة بـ 48 ساعة و50 رسالة.',
                            ),

                            _buildTerm(
                              '3. حظر الإساءة',
                              'أي سلوك غير لائق أو محاولة تبادل أرقام أو وسائل تواصل خارجية يعرض الحساب للحظر النهائي.',
                            ),

                            _buildTerm(
                              '4. حماية البيانات',
                              'جميع البيانات مشفرة. لا يحق لأي مستخدم الوصول لبيانات غيره.',
                            ),

                            _buildTerm(
                              '5. الإبلاغ عن المخالفات',
                              'يجب الإبلاغ فوراً عن أي سلوك مخالف عبر زر البلاغ.',
                            ),

                            const SizedBox(height: 12),

                            // ==================================================
                            // ثالثاً
                            // ==================================================

                            _buildSectionTitle(
                              'ثالثاً: إخلاء المسؤولية',
                              Icons.gavel_outlined,
                            ),

                            _buildDisclaimerCard(),

                            const SizedBox(height: 20),

                            // ==================================================
                            // عبارة ختامية
                            // ==================================================

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      AppColors.borderLight,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.favorite_border_rounded,
                                    size: 21,
                                    color:
                                        AppColors.primary,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'نلتزم في ميثاق بتوفير بيئة جادة ومحترمة تحفظ الخصوصية والكرامة.',
                                      textAlign:
                                          TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.6,
                                        color:
                                            AppColors
                                                .textSecondary,
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
                  ),
                ),

                // ==========================================================
                // منطقة الموافقة والمتابعة
                // ==========================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.borderLight,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.05,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                      ),
                      child: Column(
                        children: [
                          _buildAcceptanceCard(),

                          const SizedBox(height: 12),

                          IslamicButton(
                            label: 'متابعة التسجيل',
                            onPressed: _accepted
                                ? () {
                                    Navigator
                                        .pushReplacementNamed(
                                      context,
                                      widget.isGroomRole
                                          ? '/groom'
                                          : '/bride',
                                    );
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      
    );
  }
}