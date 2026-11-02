import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../app_colors.dart';
import '../design/tokens.dart';
import '../config.dart';
import '../ui_copy.dart';
import '../services/api_service.dart';
import '../services/api_exceptions.dart';   
import '../services/notifications_service.dart';
import '../services/session_service.dart';
import '../utils/error_handler.dart';
import '../utils/profile_fields.dart';
import '../widgets/islamic_decorations.dart';
import 'exploration/widgets/bride_result_card.dart';
import '../widgets/ux_helpers.dart';
import 'contact_exchange_screen.dart';

class ExplorationScreen extends StatefulWidget {
  final bool isGroomRole;

  /// عند true: بعد التحميل يُفتح فوراً حوار مراجعة صورة الفتاة (إن وُجدت موافقة).
  final bool forceOpenAwaitingReview;

  /// عند العرض داخل تبويب الهيكل: بلا شريط عنوان مكرّر.
  final bool embedded;

  const ExplorationScreen({
    Key? key,
    this.isGroomRole = true,
    this.forceOpenAwaitingReview = false,
    this.embedded = false,
  }) : super(key: key);

  @override
  State<ExplorationScreen> createState() => _ExplorationScreenState();
}

class _ExplorationScreenState extends State<ExplorationScreen>
    with WidgetsBindingObserver {
  final SupabaseClient _client = Supabase.instance.client;

  final List<String> _queue = [];

  String? _currentGroomCode;
  String? _currentBrideCode;

  /// بيانات الشاب المستخدمة في مطابقة متطلبات العروس
  Map<String, dynamic>? _groomData;
final ScrollController _filterScrollController = ScrollController();
  bool _isLoading = true;
  bool _contactOpened = false;
  bool _isSubmitting = false;
  bool _groomSearchLocked = false;

  List<Map<String, dynamic>> _allBrides = [];

  int _pageSize = 10;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  Timer? _refreshTimer;
  Timer? _countdownTimer;
  Future<List<Map<String, dynamic>>>? _incomingProposalsFuture;
  String? _contactExchangesKey;
  Future<List<Map<String, dynamic>>>? _contactExchangesFuture;

  // ============================================================
  // الفلاتر المختارة
  // ============================================================

  List<String> _gov = [];
  List<String> _residence = [];
  List<String> _age = [];
  List<String> _edu = [];
  List<String> _social = [];
  List<String> _height = [];
  List<String> _weight = [];
  List<String> _hijab = [];
  List<String> _skin = [];
  List<String> _beauty = [];
  List<String> _religious = [];
  List<String> _eyeColors = [];
  List<String> _hairColors = [];
  List<String> _hairTypes = [];

  /// هذه الفلاتر أصبحت تعتمد على features في JSONB
  List<String> _acceptPolygamy = [];
  List<String> _securedHousing = [];
  List<String> _quranMemorization = [];
  List<String> _reducedMahr = [];
  List<Map<String, dynamic>>? _allBridesCache;
  List<Map<String, dynamic>> _awaitingGroomProposals = [];
  List<Map<String, dynamic>> _groomOpenProposals = [];
  String? _proposalsLoadError;
  bool _awaitingReviewOpen = false;
  final Set<String> _seenAwaitingIds = {};

  /// فلاتر features الجديدة
  List<String> _religiousStudy = [];
  List<String> _featureFinancialStatus = [];

  List<String> _smoking = [];
  List<String> _hookah = [];

 bool _filtersApplied = false;

// ═══ Cache للفلترة ═══
List<Map<String, dynamic>>? _cachedFiltered;
bool _filtersDirty = true;
  // ============================================================
  // خيارات الفلاتر
  // ============================================================

  final List<String> _govs = [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'إدلب',
    'دير الزور',
    'الرقة',
    'الحسكة',
    'درعا',
    'السويداء',
    'القنيطرة',
  ];

  final List<String> _skins = [
    'بيضاء',
    'حنطية',
    'سمراء',
  ];

  final List<String> _edus = [
    'تاسع',
    'بكلوريا علمي',
    'بكلوريا أدبي',
    'دراسة جامعية',
    'جامعة', // توافق مع ملفات قديمة
    'لا يوجد',
    'لايوجد', // توافق مع ملفات قديمة
  ];

  final List<String> _ages = [
    '17-20',
    '21-25',
    '26-30',
    '31-35',
    '36-40',
    '41-50',
  ];

  final List<String> _socials = [
    'عزباء',
    'مطلقة',
    'أرملة',
  ];

  final List<String> _heightRanges = [
    '140-150',
    '150-160',
    '160-170',
    '170-180',
    '180-190',
    '190-200',
  ];

  final List<String> _weightRanges = [
    '40-50',
    '50-60',
    '60-70',
    '70-80',
    '80-90',
    '90-100',
    '100-110',
    '110-120',
  ];

  final List<String> _hijabs = [
    'خمار',
    'حجاب كامل',
    'حجاب',
  ];

  final List<String> _beautyLevels = [
    'عادي جداً',
    'عادي',
    'جيد',
    'جيد جداً',
  ];

  final List<String> _religiousLevels = [
    'ضعيف جداً',
    'ضعيف',
    'وسط',
    'جيد',
    'جيد جداً',
    'ممتاز',
  ];

  final List<String> _eyeColorOptions = [
    'بني',
    'أسود',
    'أزرق',
    'أخضر',
    'عسلي',
    'رمادي',
  ];

  final List<String> _hairColorOptions = [
    'أسود',
    'بني',
    'أشقر',
    'أحمر',
    'رمادي',
  ];

  final List<String> _hairTypeOptions = [
    'ناعم',
    'خشن',
    'مجعد',
    'مموج',
  ];

  final List<String> _yesNoOptions = [
    'نعم',
    'لا',
  ];

  /// نفس قيم ميزة الحالة المادية المرتفعة في تسجيل الفتاة (نعم/لا)
  final List<String> _financialFeatureOptions = [
    'نعم',
    'لا',
  ];

  // ============================================================
  // Lifecycle
  // ============================================================

 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  // 🔒 تحقق من الدور الفعلي
  _verifyRoleAndInit();
}

Future<void> _verifyRoleAndInit() async {
  debugPrint('🟢🟢🟢 EXPLORATION INIT');
  debugPrint('🟢 widget.isGroomRole = ${widget.isGroomRole}');

  try {
    final userId = _client.auth.currentUser?.id;
    debugPrint('🟢 userId = $userId');

    if (userId == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/intro');
      return;
    }

    final profile = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    if (!mounted) return;

    if (profile == null) {
      try {
        await _client.auth.signOut();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/intro');
      return;
    }

    final actualRole = profile['role']?.toString();
    final shouldBeGroom = actualRole == 'groom';

    debugPrint('🟢 actualRole = $actualRole');
    debugPrint('🟢 shouldBeGroom = $shouldBeGroom');
    debugPrint('🟢 widget.isGroomRole = ${widget.isGroomRole}');

    // 🔴🔴🔴 الحماية الأساسية
    if (shouldBeGroom != widget.isGroomRole) {
      debugPrint('🔴🔴🔴 ROLE MISMATCH! Redirecting...');

      if (shouldBeGroom) {
        await SessionService.clearBrideCode();
      } else {
        await SessionService.clearGroomCode();
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ExplorationScreen(
            isGroomRole: shouldBeGroom,
          ),
        ),
      );
      return;
    }

    // ✅ الدور مطابق
    _startTimers();

    // ⭐⭐⭐ الإصلاح: حمّل البيانات الآن ⭐⭐⭐
    await _loadAllData();

  } catch (e, st) {
    debugPrint('❌ _verifyRoleAndInit: $e');
    debugPrint('$st');

    // ⭐ حتى عند الخطأ، أوقف التحميل
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

void _startTimers() {
  _refreshTimer = Timer.periodic(
    const Duration(minutes: 5),
    (_) {
      if (!mounted || _contactOpened) return;

      // الإبقاء على نتائج البحث، مع متابعة موافقة الفتاة.
      if (_filtersApplied) {
        if (widget.isGroomRole) {
          _loadAwaitingGroomProposals();
        }
        return;
      }

      _loadAllData();
    },
  );

  _countdownTimer = Timer.periodic(
    const Duration(minutes: 1),
    (_) {
      if (!mounted || _contactOpened) return;
      if (widget.isGroomRole) {
        _loadAwaitingGroomProposals();
        return;
      }
      setState(() {});
    },
  );
}

 

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAllData(resetSearch: false);
    }
  }
  @override
void dispose() {
  _refreshTimer?.cancel();
  _countdownTimer?.cancel();
  _filterScrollController.dispose();   // ⭐ جديد

  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

  // ============================================================
  // تحميل البيانات
  // ============================================================

  Future<void> _loadAllData({bool resetSearch = true}) async {
  if (!mounted) return;

  if (resetSearch) {
    setState(() {
      _isLoading = true;
    });
  }

  // Safety timer — 15 ثانية للتحميل الكامل فقط
  final safetyTimer = resetSearch
      ? Timer(const Duration(seconds: 15), () {
          if (mounted && _isLoading) {
            setState(() {
              _isLoading = false;
            });
          }
        })
      : null;

  try {
    // ═══════════════════════════════════════════════════════
    // 🔒 عزل صارم بين الأدوار
    // ═══════════════════════════════════════════════════════
    if (widget.isGroomRole) {
      // ─── شاب ───
      await SessionService.clearBrideCode();
      _currentBrideCode = null;

      await _loadGroomData();
      await _loadAwaitingGroomProposals();

      // لا ننزّل الكتالوج كاملاً — النتائج تأتي من السيرفر عند تطبيق الفلاتر
      if (!mounted) return;

      if (resetSearch) {
        setState(() {
          _allBrides = [];
          _currentPage = 0;
          _hasMore = false;
          _cachedFiltered = null;
          _filtersApplied = false;
        });
        _markFiltersDirty();
      }
    } else {
      // ─── فتاة ───
      // لا تحمّل بيانات الشباب
      await SessionService.clearGroomCode();
      _currentGroomCode = null;
      _groomData = null;

      await _loadBrideData();
      _refreshIncomingProposals();
    }

    _contactExchangesKey = null;
    _contactExchangesFuture = null;
  } catch (e) {
    debugPrint('❌ خطأ في تحميل البيانات: $e');
  } finally {
    safetyTimer?.cancel();
  }

  if (!mounted) return;
  if (resetSearch) {
    setState(() {
      _isLoading = false;
    });
  } else if (!_isLoading) {
    setState(() {});
  }
}

  void _refreshIncomingProposals() {
    _incomingProposalsFuture = _getProposalsDirect();
  }

  Future<List<Map<String, dynamic>>> _contactExchangesFor(String roleKey) {
    final cached = _contactExchangesFuture;
    if (_contactExchangesKey == roleKey && cached != null) return cached;

    _contactExchangesKey = roleKey;
    final future = _fetchContactExchanges();
    _contactExchangesFuture = future;
    return future;
  }

  Future<List<Map<String, dynamic>>> _fetchContactExchanges() async {
    final list = await ApiService.getProposals();
    return list
        .where((p) => ApiService.proposalNeedsContactExchange(p))
        .toList();
  }

  Future<void> _openContactExchange({
    required String proposalId,
    required bool isBrideParty,
  }) async {
    if (proposalId.isEmpty) return;
    _contactOpened = true;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContactExchangeScreen(
            proposalId: proposalId,
            isBrideParty: isBrideParty,
          ),
        ),
      );
    } finally {
      _contactOpened = false;
      _contactExchangesKey = null;
      _contactExchangesFuture = null;
      if (mounted) setState(() {});
    }
  }
  // ============================================================
  // تحميل جميع العرائس للفلترة
  // ============================================================

  /// فلاتر الواجهة → حمولة السيرفر
  Map<String, dynamic> _buildServerFilters() {
    final filters = <String, dynamic>{};
    void put(String key, List<String> values) {
      if (values.isNotEmpty) filters[key] = List<String>.from(values);
    }

    put('governorates', _gov);
    put('residences', _residence);
    put('education', _edu);
    put('social_status', _social);
    put('height', _height);
    put('weight', _weight);
    put('hijab', _hijab);
    put('skin', _skin);
    put('beauty', _beauty);
    put('religious', _religious);
    put('eye_colors', _eyeColors);
    put('hair_colors', _hairColors);
    put('hair_types', _hairTypes);
    put('accept_polygamy', _acceptPolygamy);
    put('secured_housing', _securedHousing);
    put('quran_memorization', _quranMemorization);
    put('reduced_mahr', _reducedMahr);
    put('religious_study', _religiousStudy);
    put('high_financial_status', _featureFinancialStatus);
    put('smoking', _smoking);
    put('hookah', _hookah);
    put('age', _age);
    return filters;
  }

  Future<List<Map<String, dynamic>>> _loadAllBridesForFilteringForceRefresh() async {
    ApiService.clearBridesCache();
    _allBridesCache = null;
    final result = await ApiService.searchBrides(
      page: 0,
      limit: _pageSize,
      filters: _buildServerFilters(),
      forceRefresh: true,
    );
    return List<Map<String, dynamic>>.from(result['items'] as List);
  }

  // ============================================================
  // بيانات الشاب
  // ============================================================

  Future<void> _loadGroomData() async {
    try {
      final savedGroomCode =
          await SessionService.getGroomCode();

      if (savedGroomCode != null &&
          savedGroomCode.isNotEmpty) {
        _currentGroomCode = savedGroomCode;
      }

      final userId = _client.auth.currentUser?.id;

      Map<String, dynamic>? data;

      if (userId != null) {
        data = await _client
            .from('grooms')
            .select(
              'groom_code, '
              'governorate, '
              'residence, '
              'education_level, '
              'income, '
              'financial_status, '
              'housing_type, '
              'smoking, '
              'hookah, '
              'religious_commitment, '
              'height_cm, '
              'weight_kg, '
              'skin_color, '
              'birth_date',
            )
            .eq('user_id', userId)
            .maybeSingle();
      }

      /// احتياط في حال لم نجد السجل عن طريق user_id
      if (data == null &&
          savedGroomCode != null &&
          savedGroomCode.isNotEmpty) {
        data = await _client
            .from('grooms')
            .select(
              'groom_code, '
              'governorate, '
              'residence, '
              'education_level, '
              'income, '
              'financial_status, '
              'housing_type, '
              'smoking, '
              'hookah, '
              'religious_commitment, '
              'height_cm, '
              'weight_kg, '
              'skin_color, '
              'birth_date',
            )
            .eq(
              'groom_code',
              savedGroomCode,
            )
            .maybeSingle();
      }

      if (data != null) {
        _groomData =
            Map<String, dynamic>.from(data);

        final code =
            data['groom_code']
                ?.toString()
                .trim();

        if (code != null && code.isNotEmpty) {
          _currentGroomCode = code;

          await SessionService.saveGroomCode(
            code,
          );
        }

        debugPrint('✅ تم تحميل بيانات الشاب للمطابقة');
      } else {
        _groomData = null;
      }

    } catch (e, stackTrace) {
      _groomData = null;

      debugPrint(
        '❌ خطأ في _loadGroomData: $e',
      );
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // بيانات ولي الأمر
  // ============================================================

  Future<void> _loadBrideData() async {
    try {
      final savedBrideCode =
          await SessionService.getBrideCode();

      if (savedBrideCode != null &&
          savedBrideCode.isNotEmpty) {
        _currentBrideCode = savedBrideCode;
        return;
      }

      final user = _client.auth.currentUser;

      if (user == null) {
        debugPrint('❌ لا يوجد مستخدم مسجل الدخول');
        return;
      }

      final result = await _client.rpc(
  'get_my_bride_profile',
);

if (result == null) {
  debugPrint(
    '❌ لم يتم العثور على سجل فتاة لهذا المستخدم',
  );
  return;
}

final bride = result is Map
    ? Map<String, dynamic>.from(result)
    : null;

if (bride == null) {
  debugPrint(
    '❌ استجابة غير صحيحة من get_my_bride_profile',
  );
  return;
}

      final brideCode =
          bride['anonymous_code']?.toString();

      if (brideCode != null &&
          brideCode.isNotEmpty) {
        _currentBrideCode = brideCode;

        await SessionService.saveBrideCode(
          brideCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        '❌ خطأ في _loadBrideData: $e',
      );

      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // تحميل المزيد
  // ============================================================

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || !_filtersApplied) return;

    if (!mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;

      final result = await ApiService.searchBrides(
        page: nextPage,
        limit: _pageSize,
        filters: _buildServerFilters(),
        forceRefresh: true,
      );
      final moreData =
          List<Map<String, dynamic>>.from(result['items'] as List);

      if (!mounted) return;

      setState(() {
        _allBrides = [
          ..._allBrides,
          ...moreData,
        ];
        _cachedFiltered = _allBrides;
        _currentPage = nextPage;
        _hasMore = result['has_more'] == true;
        _isLoadingMore = false;
        _filtersDirty = false;
      });
    } catch (e) {
      debugPrint(
        '❌ خطأ في تحميل المزيد: $e',
      );

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // ============================================================
  // طلبات تبادل التواصل (بدل غرف المحادثة)
  // ============================================================

  Widget _contactExchangeBanner({
    required bool isBrideParty,
  }) {
    final roleKey = isBrideParty ? 'bride' : 'groom';

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _contactExchangesFor(roleKey),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = snap.data!;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: IslamicCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _iconBox(
                      Icons.contact_phone_outlined,
                      AppColors.successLight,
                      AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'طلبات تبادل التواصل',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...items.map(
                  (r) {
                    final status = r['status']?.toString() ?? '';
                    final id = r['id']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              size: 18,
                              color: AppColors.primaryLight,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBrideParty
                                        ? 'شاب: ${r['groom_code']}'
                                        : 'عروس: ${r['bride_code']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _proposalStatusLabel(status),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(9),
                                  ),
                                ),
                                onPressed: () => _openContactExchange(
                                  proposalId: id,
                                  isBrideParty: isBrideParty,
                                ),
                                child: const Text(
                                  'فتح',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Multi Select
  // ============================================================

  Future<List<String>?> _showMultiSelect({
    required String title,
    required List<String> options,
    required List<String> selected,
  }) async {
    final tempSelected =
        List<String>.from(selected);

    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                _iconBox(
                  Icons.tune_rounded,
                  AppColors.primarySoft,
                  AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) {
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: options.map((option) {
                      final isSelected =
                          tempSelected.contains(option);

                      return CheckboxListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        activeColor:
                            AppColors.primary,
                        title: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              if (!tempSelected
                                  .contains(option)) {
                                tempSelected.add(option);
                              }
                            } else {
                              tempSelected.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: Text(tr('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                  tempSelected,
                ),
                child: Text(tr('confirm')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _multiDrop(
    String txt,
    List<String> options,
    List<String> selected,
  ) {
    final hasSelection = selected.isNotEmpty;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () async {
            final result =
                await _showMultiSelect(
              title: txt,
              options: options,
              selected: selected,
            );

            if (result != null && mounted) {
              setState(() {
                selected
                  ..clear()
                  ..addAll(result);
              });
              _markFiltersDirty();
            }
          },
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 50,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: hasSelection
                  ? AppColors.primarySoft
                  : AppColors.surface,
              borderRadius:
                  BorderRadius.circular(11),
              border: Border.all(
                color: hasSelection
                    ? AppColors.primary
                    : AppColors.border,
                width: hasSelection ? 1.2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        txt,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w600,
                          color: hasSelection
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasSelection
                            ? selected.join('، ')
                            : 'الكل',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: hasSelection
                      ? AppColors.primary
                      : AppColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // أدوات JSONB
  // ============================================================

  Map<String, dynamic> _jsonMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) {
        return {};
      }

      try {
        final decoded = jsonDecode(text);

        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return {};
  }

  List<String> _jsonList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (value == null) {
      return [];
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) {
        return [];
      }

      try {
        final decoded = jsonDecode(text);

        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}

      return [text];
    }

    return [value.toString().trim()];
  }

  /// قراءة feature مع دعم البيانات القديمة.
  List<String> _brideFeatureValues(
    Map<String, dynamic> bride,
    String key, {
    String? legacyColumn,
  }) {
    final features =
        _jsonMap(bride['features']);

    final featureValues =
        _jsonList(features[key]);

    if (featureValues.isNotEmpty) {
      return featureValues;
    }

    if (legacyColumn != null) {
      return _jsonList(bride[legacyColumn]);
    }

    return [];
  }

  bool _matchesSelectedFeature(
    Map<String, dynamic> bride,
    String key,
    List<String> selected, {
    String? legacyColumn,
  }) {
    if (selected.isEmpty) {
      return true;
    }

    final values = _brideFeatureValues(
      bride,
      key,
      legacyColumn: legacyColumn,
    );

    if (values.isEmpty) {
      return false;
    }

    return selected.any(
      (selectedValue) =>
          values.any(
            (value) =>
                value.trim() ==
                selectedValue.trim(),
          ),
    );
  }

  bool _matchesAllowedValue(
    dynamic groomValue,
    List<String> allowed,
  ) {
    if (allowed.isEmpty) {
      return true;
    }

    final value =
        groomValue?.toString().trim() ?? '';

    /// القيمة المفقودة لا تحقق الشرط.
    if (value.isEmpty) {
      return false;
    }

    return allowed.any(
      (item) =>
          item.trim() == value,
    );
  }

  // ============================================================
  // مطابقة متطلبات العروس مع الشاب
  // ============================================================

  bool _matchesBrideRequirements(Map<String, dynamic> bride) {
  // لا نعرف من هو الشاب؟
  if (_groomData == null || _groomData!.isEmpty) {
    return true;   // ✅ اقبل العروس (لا تُفلتر)
  }

  final requirements = _jsonMap(bride['requirements']);
  


    /// العروس القديمة التي لا تملك requirements
    /// ليس لديها شروط جديدة للمطابقة.
    if (requirements.isEmpty) {
      return true;
    }

    // ----------------------------------------------------------
    // المحافظة
    // ----------------------------------------------------------

    final governorateReq =
        _jsonList(
      requirements['governorate'],
    );

    if (!_matchesAllowedValue(
      _groomData!['governorate'],
      governorateReq,
    )) {
      return false;
    }

    // ----------------------------------------------------------
    // محافظة الإقامة
    // ----------------------------------------------------------

    final residenceReq =
        _jsonList(
      requirements['residence'],
    );

    if (!_matchesAllowedValue(
      _groomData!['residence'],
      residenceReq,
    )) {
      return false;
    }

    // ----------------------------------------------------------
    // التعليم
    // ----------------------------------------------------------

    final educationReq =
        _jsonList(
      requirements['education'] ??
          requirements['education_level'],
    );

    if (!_matchesAllowedValue(
      _groomData!['education_level'],
      educationReq,
    )) {
      return false;
    }

    // ----------------------------------------------------------
    // الدخل
    // ----------------------------------------------------------

    final incomeReq =
        _jsonList(
      requirements['income'],
    );

    if (incomeReq.isNotEmpty &&
        !_matchesIncomeRequirement(
          _groomData!['income'],
          incomeReq,
        )) {
      return false;
    }

    // ----------------------------------------------------------
    // العمر
    // ----------------------------------------------------------

    final ageReq =
        _jsonList(
      requirements['age'],
    );

    if (ageReq.isNotEmpty) {
      final groomAge =
          _ageFromBirthDate(
        _groomData!['birth_date'],
      );

      if (groomAge == null) {
        return false;
      }

      final ageMatches =
          ageReq.any(
        (range) =>
            _valueInRange(
          groomAge,
          range,
        ),
      );

      if (!ageMatches) {
        return false;
      }
    }

    // ----------------------------------------------------------
    // الحالة المادية
    // ----------------------------------------------------------

    final financialReq =
        _jsonList(
      requirements['financial_status'],
    );

    if (!_matchesAllowedValue(
      _groomData!['financial_status'],
      financialReq,
    )) {
      return false;
    }

    // ----------------------------------------------------------
    // السكن
    // ----------------------------------------------------------

    final housingReq =
        _jsonList(
      requirements['housing'] ??
          requirements['housing_type'],
    );

    if (!_matchesAllowedValue(
      _groomData!['housing_type'],
      housingReq,
    )) {
      return false;
    }

    // ----------------------------------------------------------
    // التدخين
    // ----------------------------------------------------------

    final smokingReq =
        _jsonList(
      requirements['smoking'],
    );

    if (!_matchesAllowedValue(
      _groomData!['smoking'],
      smokingReq,
    )) {
      return false;
    }

    // ----------------------------------------------------------
    // النرجيلة
    // ----------------------------------------------------------

    final hookahReq =
        _jsonList(
      requirements['hookah'],
    );

    if (!_matchesAllowedValue(
      _groomData!['hookah'],
      hookahReq,
    )) {
      return false;
    }

    // ----------------------------------------------------------
    // الالتزام الديني
    // ----------------------------------------------------------

    final religiousReq =
        _jsonList(
      requirements['religious_commitment'],
    );

    if (!_matchesAllowedValue(
      _groomData!['religious_commitment'],
      religiousReq,
    )) {
      return false;
    }

    // ----------------------------------------------------------
    // الطول
    // ----------------------------------------------------------

    final heightReq =
        _jsonList(
      requirements['height'],
    );

    if (heightReq.isNotEmpty) {
      final height =
          int.tryParse(
        _groomData!['height_cm']
                ?.toString() ??
            '',
      );

      if (height == null) {
        return false;
      }

      final matches =
          heightReq.any(
        (range) =>
            _valueInRange(
          height,
          range,
        ),
      );

      if (!matches) {
        return false;
      }
    }

    // ----------------------------------------------------------
    // الوزن
    // ----------------------------------------------------------

    final weightReq =
        _jsonList(
      requirements['weight'],
    );

    if (weightReq.isNotEmpty) {
      final weight =
          int.tryParse(
        _groomData!['weight_kg']
                ?.toString() ??
            '',
      );

      if (weight == null) {
        return false;
      }

      final matches =
          weightReq.any(
        (range) =>
            _valueInRange(
          weight,
          range,
        ),
      );

      if (!matches) {
        return false;
      }
    }

    // ----------------------------------------------------------
    // لون البشرة
    // ----------------------------------------------------------

    final skinReq =
        _jsonList(
      requirements['skin_color'],
    );

    if (!_matchesAllowedValue(
      _groomData!['skin_color'],
      skinReq,
    )) {
      return false;
    }

   

    /// وصلت العروس إلى هنا = كل متطلباتها محققة.
    return true;
  }

  // ============================================================
  // مطابقة الدخل
  // ============================================================
_IncomeRange _parseIncomeRange(String text) {
    if (text.isEmpty) {
      return const _IncomeRange(
        min: null,
        max: null,
        minInclusive: true,
        maxInclusive: true,
      );
    }

    // تنظيف المسافات والفواصل لتجنب فشل التحويل (e.g. "1,000" -> "1000")
    String clean = text.replaceAll(' ', '').replaceAll(',', '');

    if (clean.startsWith('>=')) {
      final val = double.tryParse(clean.substring(2));
      return _IncomeRange(
        min: val,
        max: null,
        minInclusive: true,
        maxInclusive: true,
      );
    } else if (clean.startsWith('<=')) {
      final val = double.tryParse(clean.substring(2));
      return _IncomeRange(
        min: null,
        max: val,
        minInclusive: true,
        maxInclusive: true,
      );
    } else if (clean.contains('-')) {
      final parts = clean.split('-');
      if (parts.length == 2) {
        final minVal = double.tryParse(parts[0]);
        final maxVal = double.tryParse(parts[1]);
        return _IncomeRange(
          min: minVal,
          max: maxVal,
          minInclusive: true,
          maxInclusive: true,
        );
      }
    }

    final val = double.tryParse(clean);
    return _IncomeRange(
      min: val,
      max: val,
      minInclusive: true,
      maxInclusive: true,
    );
  }

  bool _incomeRangeFits(
    _IncomeRange groom,
    _IncomeRange requirement,
  ) {
    // الحد الأدنى للشاب يجب أن يحقق
    // الحد الأدنى المطلوب.
    if (requirement.min != null) {
      if (groom.min == null) {
        return false;
      }

      if (groom.min! <
          requirement.min!) {
        return false;
      }

      if (groom.min ==
              requirement.min &&
          !requirement.minInclusive &&
          groom.minInclusive) {
        return false;
      }

      if (groom.min ==
              requirement.min &&
          !requirement.minInclusive &&
          !groom.minInclusive) {
        // كلاهما صارم، مقبول.
      }
    }

    // الحد الأعلى للشاب يجب ألا يتجاوز
    // الحد الأعلى المطلوب.
    if (requirement.max != null) {
      if (groom.max == null) {
        return false;
      }

      if (groom.max! >
          requirement.max!) {
        return false;
      }

      if (groom.max ==
              requirement.max &&
          !requirement.maxInclusive &&
          groom.maxInclusive) {
        return false;
      }
    }

    return true;
  }

  bool _matchesIncomeRequirement(
    dynamic groomIncome,
    List<String> requirements,
  ) {
    if (groomIncome == null ||
        groomIncome
            .toString()
            .trim()
            .isEmpty) {
      return false;
    }

    final groomRange =
        _parseIncomeRange(
      groomIncome,
    );

    if (groomRange == null) {
      final groomText =
          groomIncome
              .toString()
              .trim();

      return requirements.any(
        (req) =>
            req.trim() ==
            groomText,
      );
    }

    for (final requirement
        in requirements) {
      final reqRange =
          _parseIncomeRange(
        requirement,
      );

      if (reqRange != null &&
          _incomeRangeFits(
            groomRange,
            reqRange,
          )) {
        return true;
      }

      if (reqRange == null &&
          requirement.trim() ==
              groomIncome
                  .toString()
                  .trim()) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // الفلترة
  // ============================================================

  List<Map<String, dynamic>> _filterBrides(
    List<Map<String, dynamic>> source,
  ) {
    var list = source.toList();

    String clean(dynamic value) =>
        value?.toString().trim() ?? '';

    // ----------------------------------------------------------
    // المحافظة
    // ----------------------------------------------------------

    if (_gov.isNotEmpty) {
      list = list.where((b) {
        return _gov.contains(
          clean(b['current_governorate']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // الإقامة
    // ----------------------------------------------------------

    if (_residence.isNotEmpty) {
      list = list.where((b) {
        return _residence.contains(
          clean(
            b['current_residence'] ??
                b['current_governorate'],
          ),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // التعليم
    // ----------------------------------------------------------

    if (_edu.isNotEmpty) {
      list = list.where((b) {
        final education =
            clean(b['education_level']);

        return _edu.any(
          (e) =>
              e.trim() == education ||
              (e == 'دراسة جامعية' &&
                  education ==
                      'دراسة جامعية '),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // الحالة الاجتماعية
    // ----------------------------------------------------------

    if (_social.isNotEmpty) {
      list = list.where((b) {
        return _social.contains(
          clean(b['social_status']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // الطول
    // ----------------------------------------------------------

    if (_height.isNotEmpty) {
      list = list.where((b) {
        final height =
            int.tryParse(
          clean(b['height_cm']),
        );

        if (height == null) return false;

        return _height.any(
          (range) => _valueInRange(
            height,
            range,
          ),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // الوزن
    // ----------------------------------------------------------

    if (_weight.isNotEmpty) {
      list = list.where((b) {
        final weight =
            int.tryParse(
          clean(b['weight_kg']),
        );

        if (weight == null) return false;

        return _weight.any(
          (range) => _valueInRange(
            weight,
            range,
          ),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // الحجاب
    // ----------------------------------------------------------

    if (_hijab.isNotEmpty) {
      list = list.where((b) {
        return _hijab.contains(
          clean(b['hijab_status']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // البشرة
    // ----------------------------------------------------------

    if (_skin.isNotEmpty) {
      list = list.where((b) {
        return _skin.contains(
          clean(b['skin_color']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // الجمال
    // ----------------------------------------------------------

    if (_beauty.isNotEmpty) {
      list = list.where((b) {
        return _beauty.contains(
          clean(b['beauty_level']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // الالتزام
    // ----------------------------------------------------------

    if (_religious.isNotEmpty) {
      list = list.where((b) {
        return _religious.contains(
          clean(b['religious_commitment']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // لون العيون
    // ----------------------------------------------------------

    if (_eyeColors.isNotEmpty) {
      list = list.where((b) {
        return _eyeColors.contains(
          clean(b['eye_color']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // لون الشعر
    // ----------------------------------------------------------

    if (_hairColors.isNotEmpty) {
      list = list.where((b) {
        return _hairColors.contains(
          clean(b['hair_color']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // طبيعة الشعر
    // ----------------------------------------------------------

    if (_hairTypes.isNotEmpty) {
      list = list.where((b) {
        return _hairTypes.contains(
          clean(b['hair_type']),
        );
      }).toList();
    }

    

    // ==========================================================
    // FEATURES الخاصة بالعروس
    // ==========================================================

    /// قبول التعدد
    if (_acceptPolygamy.isNotEmpty) {
      list = list.where((b) {
        return _matchesSelectedFeature(
          b,
          'accept_polygamy',
          _acceptPolygamy,
          legacyColumn: 'accept_polygamy',
        );
      }).toList();
    }

    /// السكن المؤمن
    if (_securedHousing.isNotEmpty) {
      list = list.where((b) {
        return _matchesSelectedFeature(
          b,
          'secured_housing',
          _securedHousing,
          legacyColumn: 'secured_housing',
        );
      }).toList();
    }

    /// حفظ القرآن
    if (_quranMemorization.isNotEmpty) {
      list = list.where((b) {
        return _matchesSelectedFeature(
          b,
          'quran_memorization',
          _quranMemorization,
          legacyColumn: 'quran_memorization',
        );
      }).toList();
    }

    /// مهر منخفض
    if (_reducedMahr.isNotEmpty) {
      list = list.where((b) {
        return _matchesSelectedFeature(
          b,
          'reduced_mahr',
          _reducedMahr,
          legacyColumn: 'reduced_mahr',
        );
      }).toList();
    }

    /// دراسة شرعية
    if (_religiousStudy.isNotEmpty) {
      list = list.where((b) {
        return _matchesSelectedFeature(
          b,
          'religious_study',
          _religiousStudy,
        );
      }).toList();
    }

    /// الحالة المادية المرتفعة
    if (_featureFinancialStatus.isNotEmpty) {
      list = list.where((b) {
        return _matchesSelectedFeature(
          b,
          'high_financial_status',
          _featureFinancialStatus,
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // التدخين
    // ----------------------------------------------------------

    if (_smoking.isNotEmpty) {
      list = list.where((b) {
        return _smoking.contains(
          clean(b['smoking']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // النرجيلة
    // ----------------------------------------------------------

    if (_hookah.isNotEmpty) {
      list = list.where((b) {
        return _hookah.contains(
          clean(b['hookah']),
        );
      }).toList();
    }

    // ----------------------------------------------------------
    // العمر
    // ----------------------------------------------------------

    if (_age.isNotEmpty) {
      list = list.where((b) {
        final birthDate =
            clean(b['birth_date']);

        final date =
            DateTime.tryParse(birthDate);

        if (date == null) return false;

        final age = _calculateAge(
          date.toIso8601String(),
        );

        return _age.any(
          (range) => _valueInRange(
            age,
            range,
          ),
        );
      }).toList();
    }

    // ==========================================================
    // المرحلة الثانية:
    // مطابقة متطلبات كل عروس مع بيانات الشاب
    // ==========================================================

    list = list.where(
      _matchesBrideRequirements,
    ).toList();

    return list;
  }

  // ============================================================
  // المجال الرقمي
  // ============================================================

  bool _valueInRange(
    int value,
    String range,
  ) {
    final parts =
        range.split('-');

    if (parts.length != 2) {
      return false;
    }

    final min =
        int.tryParse(parts[0].trim());

    final max =
        int.tryParse(parts[1].trim());

    if (min == null || max == null) {
      return false;
    }

    return value >= min && value <= max;
  }

  // ============================================================
  // تطبيق الفلاتر
  // ============================================================
Future<void> _applyFilters() async {
  if (!mounted) return;
  if (_groomSearchLocked) {
    ErrorHandler.showWarning(
      context,
      'لديك رغبات مرسلة. البحث يُفتح بعد انتهائها.',
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    ApiService.clearBridesCache();
    final result = await ApiService.searchBrides(
      page: 0,
      limit: _pageSize,
      filters: _buildServerFilters(),
      forceRefresh: true,
    );
    final filteredList =
        List<Map<String, dynamic>>.from(result['items'] as List);
    debugPrint(
      '🔍 Server search: ${filteredList.length} (total=${result['total']})',
    );

    if (!mounted) return;

    setState(() {
      _allBrides = filteredList;
      _cachedFiltered = filteredList;
      _currentPage = 0;
      _hasMore = result['has_more'] == true;
      _filtersDirty = false;
      _isLoading = false;
      _filtersApplied = true; // يفتح واجهة النتائج المنفصلة
    });
  } catch (e, st) {
    debugPrint('❌ Error applying filters: $e\n$st');
    if (mounted) {
      setState(() => _isLoading = false);
      ErrorHandler.showError(
        context,
        e,
        customMessage: 'تعذر تطبيق الفلاتر',
      );
    }
  }
}

  // ============================================================
  // مسح الفلاتر
  // ============================================================

  void _clearFilters() {
    setState(() {
      _gov = [];
      _residence = [];
      _age = [];
      _edu = [];
      _social = [];
      _height = [];
      _weight = [];
      _hijab = [];
      _skin = [];
      _beauty = [];
      _religious = [];
      _eyeColors = [];
      _hairColors = [];
      _hairTypes = [];

      _acceptPolygamy = [];
      _securedHousing = [];
      _quranMemorization = [];
      _reducedMahr = [];

      _religiousStudy = [];
      _featureFinancialStatus = [];

      _smoking = [];
      _hookah = [];

      _filtersApplied = false;
      _queue.clear();
    });
    _markFiltersDirty();
  }
  // ============================================================
// Cache الفلترة
// ============================================================

void _markFiltersDirty() {
  _filtersDirty = true;
}

List<Map<String, dynamic>> _getFilteredBrides() {
  // النتائج مُصفّاة على السيرفر
  return _cachedFiltered ?? _allBrides;
}

  // ============================================================
  // إرسال الرغبات
  // ============================================================

  Future<void> _submitQueue() async {
    if (_queue.isEmpty) {
      ErrorHandler.showError(
        context,
        'يرجى اختيار رغبة واحدة على الأقل',
      );
      return;
    }

    if (_queue.length > AppConfig.maxGroomRequests) {
      ErrorHandler.showWarning(
        context,
        'يمكن اختيار ${AppConfig.maxGroomRequests} رغبات كحد أقصى',
      );
      return;
    }

    if (_currentGroomCode == null ||
        _currentGroomCode!.isEmpty) {
      ErrorHandler.showError(
        context,
        'تعذر تحديد حسابك. يرجى تسجيل الدخول مرة أخرى',
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final brideCodes =
          List<String>.from(_queue);

      debugPrint(
        '🔵 إرسال ${brideCodes.length} رغبات عبر ApiService...',
      );

      final result =
    await ApiService.sendProposals(
  brideCodes,
);

if (!mounted) return;

final success = result['success'] == true;

final count =
    int.tryParse(
          result['count']?.toString() ?? '',
        ) ??
        0;

final message =
    result['message']?.toString() ??
        'فشل إرسال الرغبات';

if (!success) {
  // ═══ Deno يُرجع رسالة عربية واضحة ═══
  ErrorHandler.showError(
    context,
    message,
  );
  return;
}

if (!mounted) return;

ErrorHandler.showSuccess(context, 'تم إرسال $count رغبات بنجاح');

if (!mounted) return;
Navigator.pushNamedAndRemoveUntil(
  context,
  '/home-groom',
  (route) => false,
);
return;
    } catch (e) {
  debugPrint('Submit queue error: $e');

  if (mounted) {
    ErrorHandler.showError(context, e);
  }
} finally {
  if (mounted) {
    setState(() {
      _isSubmitting = false;
    });
  }
}
  }
//-------------------------------------------------------------
Future<void> _logout(BuildContext context) async {
  try {
    // افصل FCM قبل مسح الجلسة (يحتاج مستخدماً حالياً)
    try {
      await NotificationsService.logout();
    } catch (_) {}

    await SessionService.clearSession();
  } catch (e) {
    debugPrint('⚠️ Exploration logout error: $e');
  }

  if (!mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/intro',
    (route) => false,
  );
}

  // ============================================================
  // شاشة الشاب
  // ============================================================

  Widget _buildSearchLockedView() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadAllData(resetSearch: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          if (_proposalsLoadError != null) ...[
            IslamicCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _proposalsLoadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _loadAwaitingGroomProposals(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_awaitingGroomProposals.isNotEmpty) ...[
            _buildAwaitingGroomBanner(),
            const SizedBox(height: 10),
          ],
          _contactExchangeBanner(isBrideParty: false),
          const SizedBox(height: 10),
          IslamicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _iconBox(
                  Icons.lock_outline_rounded,
                  AppColors.goldSoft,
                  AppColors.goldDark,
                  size: 56,
                  iconSize: 28,
                ),
                const SizedBox(height: 12),
                const Text(
                  'البحث مغلق حالياً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _awaitingGroomProposals.isNotEmpty
                      ? 'فتاة وافقت على طلبك. استخدم زر «عرض صورة الفتاة» أعلاه أو الزر العائم للمراجعة والموافقة.'
                      : 'لديك رغبات نشطة. عندما توافق فتاة يظهر زر عرض صورتها هنا.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'رغباتك الحالية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (_groomOpenProposals.isEmpty && _proposalsLoadError == null)
            const IslamicCard(
              padding: EdgeInsets.all(14),
              child: Text(
                'لا توجد رغبات نشطة حالياً. اسحب للأسفل للتحديث.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ..._groomOpenProposals.map(_buildGroomOpenProposalTile),
        ],
      ),
    );
  }

  Widget _buildGroomOpenProposalTile(Map<String, dynamic> p) {
    final id = p['id']?.toString() ?? '';
    final brideCode = p['bride_code']?.toString() ?? '';
    final status = p['status']?.toString() ?? '';
    final isAwaiting = status == 'awaiting_groom';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IslamicCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              brideCode.isEmpty ? 'طلب زواج' : 'الفتاة: $brideCode',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _proposalStatusLabel(status),
              style: TextStyle(
                fontSize: 12,
                color: isAwaiting ? AppColors.success : AppColors.textSecondary,
                fontWeight: isAwaiting ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isAwaiting && id.isNotEmpty) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _showGroomConfirmBrideDialog(
                  proposalId: id,
                  brideCode: brideCode,
                  markSeenOnOpen: true,
                ),
                icon: const Icon(Icons.photo_camera_front_outlined, size: 20),
                label: const Text('عرض صورة الفتاة والموافقة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroomExplorer() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_groomSearchLocked) {
      return _buildSearchLockedView();
    }

    // واجهة النتائج منفصلة عن شاشة الفلاتر
    if (_filtersApplied) {
      return _buildResultsScreen();
    }

    return Column(
      children: [
        if (_awaitingGroomProposals.isNotEmpty)
          Flexible(
            flex: 0,
            child: _buildAwaitingGroomBanner(),
          ),
        Flexible(
          flex: 0,
          child: InfoBanner(
            message: UiCopy.explorationGroomHint,
            tone: InfoBannerTone.tip,
            onHelp: () => showHelpSheet(
              context,
              title: 'قواعد الرغبات والخصوصية',
              body:
                  '${UiCopy.explorationGroomHint}\n\n${UiCopy.explorationPrivacyHint}',
            ),
          ),
        ),
        Flexible(
          flex: 0,
          child: _contactExchangeBanner(isBrideParty: false),
        ),
        Flexible(
          flex: 0,
          child: _buildFilterPanel(),
        ),
        Expanded(
          child: _buildEmptyExplorerState(),
        ),
        if (_queue.isNotEmpty)
          Flexible(
            flex: 0,
            child: _buildQueuePanel(),
          ),
      ],
    );
  }

  Future<void> _loadAwaitingGroomProposals() async {
    try {
      final list = await ApiService.getProposals();
      final awaiting = list
          .where((p) => p['status']?.toString() == 'awaiting_groom')
          .toList();
      final open = list
          .where((p) => ApiService.proposalBlocksGroomSearch(p))
          .toList();
      final searchLocked = open.isNotEmpty;
      if (!mounted) return;
      setState(() {
        _awaitingGroomProposals = awaiting;
        _groomOpenProposals = open;
        _proposalsLoadError = null;
        _groomSearchLocked = searchLocked;
        if (searchLocked) {
          _filtersApplied = false;
          _queue.clear();
        }
      });
      debugPrint(
        '📋 proposals=${list.length} open=${open.length} '
        'awaiting_groom=${awaiting.length} '
        'statuses=${list.map((p) => p['status']).toList()}',
      );
      if (widget.forceOpenAwaitingReview && awaiting.isNotEmpty) {
        // إعادة فتح المراجعة حتى لو أُغلقت سابقاً بـ «لاحقاً»
        for (final p in awaiting) {
          final id = p['id']?.toString();
          if (id != null) _seenAwaitingIds.remove(id);
        }
      }
      _scheduleAwaitingReview();
    } catch (e) {
      debugPrint('⚠️ load awaiting groom proposals: $e');
      if (!mounted) return;
      setState(() {
        _proposalsLoadError =
            'تعذر تحميل الرغبات. تحقق من الإنترنت ثم اسحب للتحديث.';
      });
    }
  }

  String _proposalStatusLabel(String? status) {
    switch (status) {
      case 'waiting':
        return 'في الطابور';
      case 'pending':
        return 'بانتظار رد الفتاة';
      case 'awaiting_groom':
        return 'وافقت الفتاة — راجع الصورة';
      case 'accepted':
        return 'تم التأكيد (قديم)';
      case 'pending_payment':
        return 'بانتظار دفع رسوم التواصل';
      case 'pending_admin_review':
        return 'بانتظار مراجعة المشرف';
      case 'matched':
        return 'تم تبادل التواصل';
      default:
        return status ?? 'غير معروف';
    }
  }

  void _scheduleAwaitingReview() {
    if (!mounted ||
        !widget.isGroomRole ||
        _awaitingReviewOpen ||
        _contactOpened) {
      return;
    }

    Map<String, dynamic>? next;
    for (final proposal in _awaitingGroomProposals) {
      final id = proposal['id']?.toString() ?? '';
      if (id.isEmpty || _seenAwaitingIds.contains(id)) continue;
      next = proposal;
      break;
    }
    if (next == null) return;

    final id = next['id'].toString();
    final brideCode = next['bride_code']?.toString() ?? '';
    // لا نُعلّمها «مُشاهَدة» إلا بعد نجاح فتح الحوار
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _awaitingReviewOpen) return;
      _showGroomConfirmBrideDialog(
        proposalId: id,
        brideCode: brideCode,
        markSeenOnOpen: true,
      );
    });
  }

  Widget _buildAwaitingGroomBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: IslamicCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'عرض صورة الفتاة بعد موافقتها',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'اضغط الزر لعرض صورتها وملفها، ثم وافق لفتح المحادثة أو ارفض لحذف الطلب.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            ..._awaitingGroomProposals.map((p) {
              final id = p['id']?.toString() ?? '';
              final brideCode = p['bride_code']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: id.isEmpty
                      ? null
                      : () => _showGroomConfirmBrideDialog(
                            proposalId: id,
                            brideCode: brideCode,
                            markSeenOnOpen: true,
                          ),
                  icon: const Icon(Icons.photo_camera_front_outlined, size: 20),
                  label: Text(
                    brideCode.isEmpty
                        ? 'عرض صورة الفتاة والموافقة'
                        : 'عرض صورة الفتاة $brideCode',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openFirstAwaitingReview() {
    if (_awaitingGroomProposals.isEmpty) return;
    final p = _awaitingGroomProposals.first;
    final id = p['id']?.toString() ?? '';
    final brideCode = p['bride_code']?.toString() ?? '';
    if (id.isEmpty) return;
    _seenAwaitingIds.remove(id);
    _showGroomConfirmBrideDialog(
      proposalId: id,
      brideCode: brideCode,
      markSeenOnOpen: true,
    );
  }

  Future<void> _showGroomConfirmBrideDialog({
    required String proposalId,
    required String brideCode,
    bool markSeenOnOpen = false,
  }) async {
    if (_awaitingReviewOpen || !mounted) return;
    _awaitingReviewOpen = true;

    try {
    final navigator = Navigator.of(context, rootNavigator: true);
    var loaderShown = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loaderShown = true;
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );
    await WidgetsBinding.instance.endOfFrame;

    Map<String, dynamic> preview = {};
    Object? previewError;
    try {
      preview = await ApiService.getBridePreviewForProposal(proposalId);
    } on ApiException catch (e) {
      previewError = e;
    } catch (e) {
      previewError = e;
    } finally {
      if (loaderShown && mounted) {
        navigator.pop();
      }
    }
    if (!mounted) return;

    final bride = preview['bride'];
    if (bride is! Map || preview.isEmpty) {
      final msg = previewError is ApiException
          ? previewError.userMessage
          : (preview['message']?.toString() ??
              preview['error']?.toString() ??
              'تعذر تحميل ملف الفتاة. اسحب للتحديث ثم أعد المحاولة.');
      ErrorHandler.showError(
        context,
        previewError,
        customMessage: msg,
      );
      return;
    }

    if (markSeenOnOpen) {
      _seenAwaitingIds.add(proposalId);
    }
    final brideMap = Map<String, dynamic>.from(bride);
    final photoUrl =
        brideMap['personal_photo_signed_url']?.toString();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'تأكيد بعد رؤية الصورة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: (MediaQuery.sizeOf(dialogContext).height * 0.46)
                  .clamp(180.0, 420.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photoUrl,
                            height: 220,
                            width: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: AppColors.primarySoft,
                              child: const Icon(Icons.person, size: 64),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'لا تتوفر صورة شخصية حالياً',
                          style: TextStyle(color: AppColors.goldDark),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _detailRow('الرمز', brideMap['anonymous_code'] ?? brideCode),
                    _detailRow(
                      'العمر',
                      ageLabel(brideMap['birth_date']),
                    ),
                    _detailRow(
                      'المحافظة',
                      brideMap['current_governorate'],
                    ),
                    _detailRow(
                      'الإقامة',
                      brideMap['current_residence'],
                    ),
                    _detailRow(
                      'التعليم',
                      brideMap['education_level'],
                    ),
                    _detailRow(
                      'الحالة الاجتماعية',
                      brideMap['social_status'],
                    ),
                    _detailRow(
                      'الحجاب',
                      brideMap['hijab_status'],
                    ),
                    _detailRow(
                      'الالتزام',
                      brideMap['religious_commitment'],
                    ),
                    _detailRow(
                      'الطول',
                      _heightFromStoredValue(brideMap['height_cm']),
                    ),
                    _detailRow(
                      'الوزن',
                      _weightFromStoredValue(brideMap['weight_kg']),
                    ),
                    _detailRow('البشرة', brideMap['skin_color']),
                    const SizedBox(height: 8),
                    const Text(
                      'بالموافقة ستُفتح المحادثة للطرفين. الدفع يبقى بعد موافقتكما داخل المحادثة.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.maxFinite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _confirmAwaitingByGroom(
                          proposalId: proposalId,
                          brideCode: brideCode,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text(
                        'موافقة وفتح الدردشة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('لاحقاً'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _rejectAwaitingByGroom(proposalId);
                      },
                      child: const Text(
                        'رفض وحذف',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    } finally {
      _awaitingReviewOpen = false;
      if (mounted) _scheduleAwaitingReview();
    }
  }

  Future<void> _confirmAwaitingByGroom({
    required String proposalId,
    required String brideCode,
  }) async {
    final result = await ApiService.confirmProposal(proposalId);
    if (!mounted) return;
    if (result['success'] != true) {
      ErrorHandler.showError(
        context,
        null,
        customMessage: result['message']?.toString() ?? 'تعذر التأكيد',
      );
      return;
    }

    await _loadAwaitingGroomProposals();
    if (!mounted) return;

    ErrorHandler.showSuccess(
      context,
      'تم التأكيد — ادفع رسوم تبادل التواصل',
    );

    await _openContactExchange(
      proposalId: proposalId,
      isBrideParty: false,
    );
  }

  Future<void> _rejectAwaitingByGroom(String proposalId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الرفض'),
          content: const Text(
            'سيتم حذف الطلب نهائياً. هل أنت متأكد؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف نهائياً'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;

    final result = await ApiService.rejectProposalByGroom(proposalId);
    if (!mounted) return;
    if (result['success'] != true) {
      ErrorHandler.showError(
        context,
        null,
        customMessage: result['message']?.toString() ?? 'تعذر الحذف',
      );
      return;
    }

    await _loadAwaitingGroomProposals();
    if (!mounted) return;
    ErrorHandler.showSuccess(context, 'تم حذف الطلب نهائياً');
  }

  /// شاشة نتائج البحث (منفصلة عن لوحة الفلاتر)
  Widget _buildResultsScreen() {
    final totalHint = _getFilteredBrides().length;
    final title = _hasMore
        ? 'نتائج البحث'
        : 'نتائج البحث ($totalHint)';

    return Column(
      children: [
        Material(
          color: Colors.white,
          elevation: 0.5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 8, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'العودة للفلاتر',
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _filtersApplied = false;
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasMore
                            ? 'مرّر للأسفل لعرض المزيد'
                            : 'عدّل الفلاتر من زر «تعديل»',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filtersApplied = false;
                    });
                  },
                  icon: const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'تعديل',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_awaitingGroomProposals.isNotEmpty)
          _buildAwaitingGroomBanner(),
        Expanded(child: _buildResults()),
        if (_queue.isNotEmpty)
          Flexible(
            flex: 0,
            child: _buildQueuePanel(),
          ),
      ],
    );
  }

 Widget _buildFilterPanel() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    child: IslamicCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← مهم
        children: [
          // ═══════════════════════════════════════
          // العنوان (بدون تغيير)
          // ═══════════════════════════════════════
          Row(
            children: [
              _iconBox(
                Icons.filter_alt_outlined,
                AppColors.primarySoft,
                AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'البحث عن شريكة مناسبة',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'حدد الصفات التي تبحث عنها',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasSelectedFilters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedFilterCount} محدد',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldDark,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ═══════════════════════════════════════
          // ⭐ الفلاتر — الآن قابلة للتمرير ⭐
          // ═══════════════════════════════════════
          ConstrainedBox(
  constraints: const BoxConstraints(maxHeight: 280),
  child: Scrollbar(
    controller: _filterScrollController,   // ← صريح
    thumbVisibility: true,                  // ← يظهر دائمًا
    child: SingleChildScrollView(
      controller: _filterScrollController, // ← نفس الـ controller
      child: _buildFilterRows(),
    ),
  ),
),
          const SizedBox(height: 9),

          // ═══════════════════════════════════════
          // الأزرار (بدون تغيير)
          // ═══════════════════════════════════════
          LayoutBuilder(
            builder: (context, constraints) {
              final clearButton = OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 17,
                ),
                label: Text(
                  tr('clear_all'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              );
              final applyButton = ElevatedButton.icon(
                onPressed: _isLoading ? null : _applyFilters,
                icon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                ),
                label: Text(
                  tr('apply_filters'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              );
              if (constraints.maxWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    applyButton,
                    const SizedBox(height: 8),
                    clearButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: clearButton),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: applyButton),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFilterRows() {
    final fields = <(String, List<String>, List<String>)>[
      ('المحافظة', _govs, _gov),
      ('الإقامة', _govs, _residence),
      ('العمر', _ages, _age),
      ('التعليم', _edus, _edu),
      ('الحالة', _socials, _social),
      ('الطول', _heightRanges, _height),
      ('الوزن', _weightRanges, _weight),
      ('الحجاب', _hijabs, _hijab),
      ('البشرة', _skins, _skin),
      ('الجمال', _beautyLevels, _beauty),
      ('الالتزام', _religiousLevels, _religious),
      ('لون العيون', _eyeColorOptions, _eyeColors),
      ('لون الشعر', _hairColorOptions, _hairColors),
      ('طبيعة الشعر', _hairTypeOptions, _hairTypes),
      ('تقبل التعدد', _yesNoOptions, _acceptPolygamy),
      ('سكن مؤمن', _yesNoOptions, _securedHousing),
      ('حفظ القرآن', _yesNoOptions, _quranMemorization),
      ('مهر منخفض', _yesNoOptions, _reducedMahr),
      ('دراسة شرعية', _yesNoOptions, _religiousStudy),
      ('حالة مادية', _financialFeatureOptions, _featureFinancialStatus),
      ('التدخين', _yesNoOptions, _smoking),
      ('النرجيلة', _yesNoOptions, _hookah),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 390 ? 2 : 3;
        final rows = <Widget>[];
        for (var i = 0; i < fields.length; i += columns) {
          final end = i + columns > fields.length ? fields.length : i + columns;
          final slice = fields.sublist(i, end);
          rows.add(
            Row(
              children: [
                for (final field in slice)
                  _multiDrop(field.$1, field.$2, field.$3),
                for (var pad = slice.length; pad < columns; pad++)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  // ============================================================
  // النتائج
  // ============================================================

  Widget _buildResults() {
    final list = _getFilteredBrides();

    if (list.isEmpty) {
      return _buildNoResults();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_isLoadingMore ||
            !_hasMore) {
          return false;
        }

        final metrics =
            notification.metrics;

        final remaining =
            metrics.maxScrollExtent -
                metrics.pixels;

        if (remaining <= 200) {
          _loadMore();
        }

        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          16,
        ),
        itemCount:
            list.length +
                (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= list.length) {
            return const Padding(
              padding:
                  EdgeInsets.all(20),
              child: Center(
                child:
                    CircularProgressIndicator(
                  color:
                      AppColors.primary,
                ),
              ),
            );
          }

          return _buildBrideResultCard(
            list[i],
          );
        },
      ),
    );
  }

  // ============================================================
  // بطاقة العروس (معدلة)
  // ============================================================
  Widget _buildBrideResultCard(
    Map<String, dynamic> item,
  ) {
    final bCode =
        item['anonymous_code']?.toString() ?? 'BRIDE-${item['id']}';

    final isSelected = _queue.contains(bCode);

    final age = _ageFromBirthDate(item['birth_date']);

    // استخراج الميزات (Features) بأمان
    final acceptPolygamy =
        hasFeature(item, 'accept_polygamy', legacyColumn: 'accept_polygamy');
    final securedHousing =
        hasFeature(item, 'secured_housing', legacyColumn: 'secured_housing');
    final quranMemorization = hasFeature(
      item,
      'quran_memorization',
      legacyColumn: 'quran_memorization',
    );
    final reducedMahr =
        hasFeature(item, 'reduced_mahr', legacyColumn: 'reduced_mahr');
    final religiousStudy = hasFeature(item, 'religious_study');
    final highFinancial = hasFeature(item, 'high_financial_status');

    // نجمع القيم المعروفة فقط. لا نعرض «غير محدد» حتى لا
    // تغرق المعلومات المهمة في الضجيج.
    final details = <BrideChipData>[];
    var unknown = 0;

    void addOrCount(IconData icon, String? raw, {String? suffix}) {
      final v = raw?.trim() ?? '';
      if (v.isEmpty) {
        unknown++;
        return;
      }
      details.add(
        BrideChipData(icon: icon, label: suffix == null ? v : '$v $suffix'),
      );
    }

    details.add(
      BrideChipData(
        icon: Icons.cake_outlined,
        label: age == null ? 'العمر غير محدد' : '$age سنة',
      ),
    );
    if (age == null) unknown++;

    addOrCount(
      Icons.height_outlined,
      _heightFromStoredValue(item['height_cm']),
    );
    addOrCount(
      Icons.monitor_weight_outlined,
      _weightFromStoredValue(item['weight_kg']),
    );
    addOrCount(Icons.face_outlined, item['skin_color']?.toString());
    addOrCount(Icons.school_outlined, item['education_level']?.toString());
    addOrCount(Icons.people_outline, item['social_status']?.toString());
    addOrCount(
      Icons.face_retouching_natural_outlined,
      item['hijab_status']?.toString(),
    );
    addOrCount(
      Icons.menu_book_outlined,
      item['religious_commitment']?.toString(),
    );

    final features = <({String label, Color bg, Color fg})>[];
    if (religiousStudy) {
      features.add(
        (
          label: 'دراسة شرعية',
          bg: AppColors.primarySoft,
          fg: AppColors.primary,
        ),
      );
    }
    if (highFinancial) {
      features.add(
        (
          label: 'حالة مادية مرتفعة',
          bg: AppColors.goldSoft,
          fg: AppColors.goldDark,
        ),
      );
    }
    if (acceptPolygamy) {
      features.add(
        (
          label: 'تقبل التعدد',
          bg: AppColors.successLight,
          fg: AppColors.success,
        ),
      );
    }
    if (securedHousing) {
      features.add(
        (label: 'سكن مؤمن', bg: AppColors.primarySoft, fg: AppColors.primary),
      );
    }
    if (quranMemorization) {
      features.add(
        (
          label: 'حافظة للقرآن',
          bg: AppColors.goldSoft,
          fg: AppColors.goldDark,
        ),
      );
    }
    if (reducedMahr) {
      features.add(
        (
          label: 'مهر منخفض',
          bg: AppColors.warningLight,
          fg: AppColors.warning,
        ),
      );
    }

    final governorate = item['current_governorate']?.toString() ?? '';
    final residence = item['current_residence']?.toString() ?? '';
    final location = [
      if (governorate.isNotEmpty && governorate != 'غير محدد') governorate,
      if (residence.isNotEmpty && residence != 'غير محدد') residence,
    ].join(' - ');

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm + 2),
      child: BrideResultCard(
        code: bCode,
        location: location,
        details: details,
        features: features,
        unknownCount: unknown,
        selected: isSelected,
        onToggle: () {
          setState(() {
            if (isSelected) {
              _queue.remove(bCode);
            } else {
              if (_queue.length >= AppConfig.maxGroomRequests) {
                ErrorHandler.showWarning(
                  context,
                  'يمكن اختيار ${AppConfig.maxGroomRequests} رغبات كحد أقصى',
                );
                return;
              }
              _queue.add(bCode);
            }
          });
        },
        onOpenProfile: () => _showBrideProfile(item),
      ),
    );
  }

  // ============================================================
  // دوال مساعدة للبطاقة
  // ============================================================
  
  // نافذة عرض الملف الكامل للعروس
  void _showBrideProfile(Map<String, dynamic> bride) {
    final age = _ageFromBirthDate(bride['birth_date']);
    final reqRows = brideRequirementRows(bride);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                _iconBox(
                  Icons.person_outline,
                  AppColors.primarySoft,
                  AppColors.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'الملف الشخصي للعروس',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _detailRow('رمز العروس', bride['anonymous_code']),
                  _detailRow('العمر', age != null ? '$age سنة' : null),
                  _detailRow('المحافظة', bride['current_governorate']),
                  _detailRow('الإقامة', bride['current_residence']),
                  _detailRow('الطول', _heightFromStoredValue(bride['height_cm'])),
                  _detailRow('الوزن', _weightFromStoredValue(bride['weight_kg'])),
                  _detailRow('لون البشرة', bride['skin_color']),
                  _detailRow('لون الشعر', bride['hair_color']),
                  _detailRow('نوع الشعر', bride['hair_type']),
                  _detailRow('لون العيون', bride['eye_color']),
                  _detailRow('مستوى الجمال', bride['beauty_level']),
                  _detailRow('التحصيل العلمي', bride['education_level']),
                  _detailRow('تفاصيل التعليم', bride['education_details']),
                  _detailRow('الحالة الاجتماعية', bride['social_status']),
                  _detailRow('الالتزام الديني', bride['religious_commitment']),
                  _detailRow('نوع الحجاب', bride['hijab_status']),
                  _detailRow('التدخين', bride['smoking']),
                  _detailRow('النرجيلة', bride['hookah']),
                  _detailRow('الأمراض المزمنة', bride['chronic_disease']),
                  _detailRow('العيوب الخلقية', bride['birth_defect']),
                  _detailRow('صف نفسها', bride['interests']),
                  _detailRow('اللغات', bride['languages']),
                  const SizedBox(height: 10),
                  const Text(
                    'الميزات:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  for (final f in kBrideFeatureKeys)
                    _detailRow(
                      f.value,
                      featureDisplay(bride, f.key, legacyColumn: f.key),
                    ),
                  if (reqRows.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'متطلبات الشاب:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    for (final r in reqRows) _detailRow(r.key, r.value),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }


  // ============================================================
  // الرغبات المختارة
  // ============================================================

  Widget _buildQueuePanel() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        border: Border(
          top: BorderSide(
            color: AppColors.gold
                .withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_list_numbered_rounded,
                size: 19,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'الرغبات المختارة',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 13,
                    color:
                        AppColors.goldDark,
                  ),
                ),
              ),
              Text(
                '${_queue.length}/${AppConfig.maxGroomRequests}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.goldDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: Row(
              children: _queue
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        left: 5,
                      ),
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          border:
                              Border.all(
                            color: AppColors
                                .gold
                                .withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Text(
                          '${entry.key + 1}. ${entry.value}',
                          style:
                              const TextStyle(
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w600,
                            color: AppColors
                                .textPrimary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 9),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isSubmitting
                      ? null
                      : _submitQueue,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      size: 18,
                    ),
              label: Text(
                _isSubmitting
                    ? 'جاري الإرسال...'
                    : tr('send_proposals'),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // لا توجد نتائج
  // ============================================================

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: IslamicCard(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              _iconBox(
                Icons.search_off_rounded,
                AppColors.goldSoft,
                AppColors.goldDark,
                size: 60,
                iconSize: 30,
              ),
              const SizedBox(height: 13),
              const Text(
                'لا توجد نتائج مطابقة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'جرب تعديل بعض عوامل التصفية للحصول على نتائج أكثر.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color:
                      AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyExplorerState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: IslamicCard(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              _iconBox(
                Icons.manage_search_rounded,
                AppColors.primarySoft,
                AppColors.primary,
                size: 64,
                iconSize: 32,
              ),
              const SizedBox(height: 14),
              const Text(
                'ابدأ البحث',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.primary,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'حدد الصفات المناسبة لك ثم اضغط على تطبيق الفلترة.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color:
                      AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // شاشة ولي الأمر
  // ============================================================

  Widget _buildBrideManager() {
    if (_isLoading) {
      return _buildLoading();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAllData,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          20,
        ),
        children: [
          InfoBanner(
            message: UiCopy.explorationBrideHint,
            tone: InfoBannerTone.info,
            onHelp: () => showHelpSheet(
              context,
              title: 'كيف تُدار الطلبات؟',
              body:
                  '${UiCopy.explorationBrideHint}\n\n${UiCopy.explorationPrivacyHint}',
            ),
          ),
          _contactExchangeBanner(isBrideParty: true),

          const SizedBox(height: 10),

          IslamicCard(
            child: Row(
              children: [
                _iconBox(
                  Icons.inbox_outlined,
                  AppColors.primarySoft,
                  AppColors.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلبات الزواج الواردة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'يمكنك مراجعة الطلبات واتخاذ القرار المناسب.',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (_currentBrideCode != null &&
              _currentBrideCode!.isNotEmpty &&
              _currentBrideCode !=
                  'BRIDE-DEFAULT')
            _buildIncomingRequests(),
        ],
      ),
    );
  }

  // ============================================================
  // جلب الرغبات
  // ============================================================

  Future<List<Map<String, dynamic>>>
      _getProposalsDirect() async {
    try {
      final brideCode =
          await SessionService.getBrideCode();

      if (brideCode == null ||
          brideCode.isEmpty) {
        return [];
      }

      // لا نطلب/نعرض priority للفتاة — ترتيب الرغبات خاص بالشاب فقط
      final result = await _client
          .from('proposals')
          .select(
            'id, status, groom_code, bride_code, activated_at',
          )
          .eq(
            'bride_code',
            brideCode,
          )
          .order(
            'activated_at',
            ascending: true,
          );

      return List<
          Map<String, dynamic>>.from(
        result,
      );
    } catch (e) {
      debugPrint(
        '❌ خطأ في جلب الطلبات: $e',
      );
      return [];
    }
  }

  // ============================================================
  // الوقت المتبقي
  // ============================================================

  String _calculateRemaining(
    String? activatedAt,
  ) {
    if (activatedAt == null ||
        activatedAt.isEmpty) {
      return 'بانتظار التفعيل';
    }

    try {
      final activatedTime =
          DateTime.parse(activatedAt);

      final expiresAt =
    activatedTime.add(
  const Duration(hours: 48),
);

      final remaining =
          expiresAt.difference(
        DateTime.now(),
      );

      if (remaining.isNegative ||
          remaining.inSeconds <= 0) {
        return 'انتهت المهلة';
      }

      final hours =
          remaining.inHours;

      final minutes =
          remaining.inMinutes
              .remainder(60);

      if (hours > 0) {
        return 'متبقي $hours س و $minutes د';
      }

      return 'متبقي $minutes د';
    } catch (_) {
      return 'غير محدد';
    }
  }

  // ============================================================
  // الطلبات الواردة
  // ============================================================

  Widget _buildIncomingRequests() {
    return FutureBuilder<
        List<Map<String, dynamic>>>(
      future: _incomingProposalsFuture ??= _getProposalsDirect(),
      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding:
                EdgeInsets.all(30),
            child: Center(
              child:
                  CircularProgressIndicator(
                color:
                    AppColors.primary,
              ),
            ),
          );
        }

        final allProposals =
            snapshot.data ?? [];

        final activeRequests =
            allProposals.where((r) {
          final status =
              r['status']
                      ?.toString() ??
                  '';

          return status == 'pending' ||
              status == 'awaiting_groom' ||
              status == 'accepted' ||
              status == 'pending_payment' ||
              status == 'pending_admin_review' ||
              status == 'matched';
        }).toList();

        if (activeRequests.isEmpty) {
          return _buildNoRequests();
        }

        return Column(
          children:
              activeRequests.map((r) {
            return _buildProposalCard(r);
          }).toList(),
        );
      },
    );
  }

  Widget _buildProposalCard(
    Map<String, dynamic> r,
  ) {
    final status =
        r['status']?.toString() ?? '';

    final groomCode =
        r['groom_code']?.toString() ?? '';

    final proposalId = r['id'];

    final isPending = status == 'pending';
    final isAwaitingGroom = status == 'awaiting_groom';
    final needsContact = ApiService.proposalNeedsContactExchange(r);
    final proposalIdStr = proposalId?.toString() ?? '';

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: IslamicCard(
        padding:
            const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _iconBox(
                  isPending
                      ? Icons.person_add_alt_1_outlined
                      : isAwaitingGroom
                          ? Icons.hourglass_top_rounded
                          : Icons.contact_phone_outlined,
                  isPending
                      ? AppColors.goldSoft
                      : isAwaitingGroom
                          ? AppColors.warningLight
                          : AppColors.successLight,
                  isPending
                      ? AppColors.goldDark
                      : isAwaitingGroom
                          ? AppColors.goldDark
                          : AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلب من الشاب',
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        groomCode,
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors.primary,
                        ),
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _statusBadge(
                  isPending
                      ? _calculateRemaining(
                          r['activated_at']
                              ?.toString(),
                        )
                      : isAwaitingGroom
                          ? 'بانتظار الشاب'
                          : _proposalStatusLabel(status),
                  isPending || isAwaitingGroom || needsContact,
                ),
              ],
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () =>
                  _showGroomProfile(
                groomCode,
              ),
              icon: const Icon(
                Icons.person_search_outlined,
                size: 18,
              ),
              label: const Text(
                'عرض الملف الشخصي',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors.primary,
                side: const BorderSide(
                  color:
                      AppColors.border,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),

            if (isPending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _acceptProposal(
                        proposalId,
                        groomCode,
                      ),
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'قبول',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.success,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _rejectProposal(
                        proposalId,
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'رفض',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.error,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (isAwaitingGroom) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'في انتظار تأكيد الشاب بعد رؤية صورتك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            if (needsContact) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openContactExchange(
                    proposalId: proposalIdStr,
                    isBrideParty: true,
                  ),
                  icon: const Icon(
                    Icons.contact_phone_outlined,
                    size: 18,
                  ),
                  label: Text(
                    status == 'matched'
                        ? 'عرض معلومات التواصل'
                        : 'الدفع ومراجعة التواصل',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(
    String text,
    bool pending,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth: 105,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: pending
            ? AppColors.warningLight
            : AppColors.successLight,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
          color: pending
              ? AppColors.goldDark
              : AppColors.success,
        ),
      ),
    );
  }

  Widget _buildNoRequests() {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8),
      child: IslamicCard(
        child: Column(
          children: [
            _iconBox(
              Icons.inbox_outlined,
              AppColors.surfaceTint,
              AppColors.mutedText,
              size: 64,
              iconSize: 30,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد طلبات نشطة',
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'عندما يرسل شاب رغبته، سيظهر طلبه هنا.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ============================================================
// قبول الطلب
// ============================================================

Future<void> _acceptProposal(
  dynamic proposalId,
  String groomCode,
) async {
  try {
    if (_currentBrideCode == null ||
        _currentBrideCode!.isEmpty) {
      ErrorHandler.showError(
        context,
        null,
        customMessage: 'تعذر تحديد حساب ولي الأمر',
      );
      return;
    }

    final data = await ApiService.acceptProposal(proposalId.toString());

    if (data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'فشل قبول الطلب');
    }

    if (!mounted) return;

    _refreshIncomingProposals();
    setState(() {});

    ErrorHandler.showSuccess(
      context,
      'تم القبول. بانتظار تأكيد الشاب بعد رؤية الصورة — بدون محادثة حالياً.',
    );
  } catch (e) {
    debugPrint('❌ خطأ قبول الطلب: $e');

    if (!mounted) return;

    ErrorHandler.showError(
      context,
      e,
      customMessage: 'تعذر قبول الطلب',
    );
  }
}
 // ============================================================
// رفض الطلب
// ============================================================

Future<void> _rejectProposal(
  dynamic proposalId,
) async {
  try {
    final data = await ApiService.rejectProposal(proposalId.toString());

    if (data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'فشل رفض الطلب');
    }

    if (!mounted) return;

    _refreshIncomingProposals();
    setState(() {});

    ErrorHandler.showSuccess(
      context,
      'تم رفض الطلب',
    );
  } catch (e) {
    debugPrint('❌ خطأ رفض الطلب: $e');

    if (!mounted) return;

    ErrorHandler.showError(
      context,
      e,
      customMessage: 'تعذر رفض الطلب',
    );
  }
}

  // ============================================================
  // عرض ملف الشاب
  // ============================================================

  Future<void> _showGroomProfile(
  String groomCode,
) async {
  try {
    debugPrint('🔵 Loading groom details: $groomCode');

    // ═══════════════════════════════════════════════════════
    // ✅ استخدم Deno API بدل Supabase مباشرة
    // (يتجاوز RLS + يفحص الصلاحيات تلقائياً)
    // ═══════════════════════════════════════════════════════
    final data = await ApiService.getGroomDetails(groomCode);

    if (data.isEmpty) {
      if (mounted) {
        ErrorHandler.showError(
          context,
          null,
          customMessage: 'الملف غير متوفر',
        );
      }
      return;
    }

    debugPrint('✅ Groom details loaded');

    // ═══════════════════════════════════════════════════════
    // ✅ استخدم signed URL من Deno
    // ═══════════════════════════════════════════════════════
    String? photoUrl;
    final signedUrl = data['personal_photo_signed_url']?.toString();
    if (signedUrl != null && signedUrl.isNotEmpty) {
      photoUrl = signedUrl;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                _iconBox(
                  Icons.person_outline,
                  AppColors.primarySoft,
                  AppColors.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'الملف الشخصي للشاب',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (photoUrl != null)
                    Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold,
                        ),
                        child: ClipOval(
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildDialogAvatar(null),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildDialogAvatar(null),

                  const SizedBox(height: 15),

                  _detailRow('رمز الشاب', data['groom_code']),
                  _detailRow(
                    'العمر',
                    data['birth_date'] != null
                        ? '${_calculateAge(data['birth_date'])} سنة'
                        : null,
                  ),
                  _detailRow('المحافظة', data['governorate']),
                  _detailRow(
                    'مكان الولادة / الإقامة',
                    data['place_of_birth'] ?? data['residence'],
                  ),
                  if (data['social_status'] != null &&
                      data['social_status'].toString().trim().isNotEmpty)
                    _detailRow('الحالة الاجتماعية', data['social_status']),
                  _detailRow('التحصيل العلمي', data['education_level']),
                  _detailRow('تفاصيل التعليم', data['education_details']),
                  _detailRow('المهنة', data['job_title']),
                  _detailRow('الدخل', data['income']),
                  _detailRow('الحالة المادية', data['financial_status']),
                  _detailRow('السكن', data['housing_type']),
                  _detailRow('الممتلكات', data['properties']),
                  _detailRow(
                    'الطول',
                    _heightFromStoredValue(data['height_cm']),
                  ),
                  _detailRow(
                    'الوزن',
                    _weightFromStoredValue(data['weight_kg']),
                  ),
                  _detailRow('لون البشرة', data['skin_color']),
                  _detailRow('التدخين', data['smoking']),
                  _detailRow('النرجيلة', data['hookah']),
                  _detailRow(
                    'الالتزام الديني',
                    data['religious_commitment'],
                  ),
                  _detailRow('الجاهزية للزواج', data['marriage_ready']),
                  _detailRow('الأمراض المزمنة', data['chronic_disease']),
                  _detailRow('العيوب الخلقية', data['birth_defect']),
                  _detailRow('صف نفسه', data['interests']),
                  _detailRow('اللغات', data['languages']),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  } on ApiException catch (e) {
    debugPrint('❌ API Error: ${e.message}');

    if (!mounted) return;

    // ═══ ترجمة أخطاء Deno ═══
    String msg = e.userMessage;

    if (e.statusCode == 403) {
      msg = 'لا يمكن عرض هذا الملف حالياً';
    } else if (e.statusCode == 404) {
      msg = 'الملف غير موجود';
    }

    ErrorHandler.showError(
      context,
      null,
      customMessage: msg,
    );
  } catch (e) {
    debugPrint('❌ Groom profile error: $e');

    if (mounted) {
      ErrorHandler.showError(
        context,
        e,
        customMessage: 'تعذر عرض الملف',
      );
    }
  }
}

  // ============================================================
  // عناصر مساعدة
  // ============================================================

  Widget _iconBox(
    IconData icon,
    Color background,
    Color foreground, {
    double size = 42,
    double iconSize = 21,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          size * 0.27,
        ),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: foreground,
      ),
    );
  }

  Widget _detailRow(
    String label,
    dynamic value,
  ) {
    final text =
        value == null ||
                value.toString().trim().isEmpty
            ? 'غير محدد'
            : value.toString();

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color:
              AppColors.surfaceGreen,
          borderRadius:
              BorderRadius.circular(9),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 95,
              child: Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogAvatar(
    dynamic name,
  ) {
    String letter = '?';

    final value =
        name?.toString().trim();

    if (value != null &&
        value.isNotEmpty) {
      letter = value.characters.first;
    }

    return Container(
      width: 108,
      height: 108,
      decoration:
          const BoxDecoration(
        shape: BoxShape.circle,
        color:
            AppColors.primarySoft,
      ),
      alignment:
          Alignment.center,
      child: Text(
        letter,
        style:
            const TextStyle(
          fontSize: 42,
          fontWeight:
              FontWeight.bold,
          color:
              AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          SizedBox(height: 12),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              fontSize: 12,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(
    dynamic birthDate,
  ) {
    final date =
        DateTime.tryParse(
      birthDate.toString(),
    );

    if (date == null) return 0;

    final now = DateTime.now();

    int age =
        now.year - date.year;

    if (now.month < date.month ||
        (now.month ==
                date.month &&
            now.day <
                date.day)) {
      age--;
    }

    return age;
  }

  int? _ageFromBirthDate(
    dynamic birthDate,
  ) {
    if (birthDate == null) {
      return null;
    }

    final date =
        DateTime.tryParse(
      birthDate.toString(),
    );

    if (date == null) {
      return null;
    }

    return _calculateAge(
      date.toIso8601String(),
    );
  }

  String? _heightFromStoredValue(
    dynamic value,
  ) {
    if (value == null) return null;

    final number =
        int.tryParse(
      value.toString(),
    );

    if (number == null) {
      return value.toString();
    }

    for (final range in [
      '130-140',
      '140-150',
      '150-160',
      '160-170',
      '170-180',
      '180-190',
      '190-200',
    ]) {
      final start =
          int.tryParse(
        range.split('-').first,
      );

      if (start == number) {
        return '$range سم';
      }
    }

    return '$number سم';
  }

  String? _weightFromStoredValue(
    dynamic value,
  ) {
    if (value == null) return null;

    final number =
        int.tryParse(
      value.toString(),
    );

    if (number == null) {
      return value.toString();
    }

    for (final range in [
      '40-50',
      '50-60',
      '60-70',
      '70-80',
      '80-90',
      '90-100',
      '100-110',
      '110-120',
    ]) {
      final start =
          int.tryParse(
        range.split('-').first,
      );

      if (start == number) {
        return '$range كغ';
      }
    }

    return '$number كغ';
  }

  bool get _hasSelectedFilters {
    return _selectedFilterCount > 0;
  }

  int get _selectedFilterCount {
    return [
      _gov,
      _residence,
      _age,
      _edu,
      _social,
      _height,
      _weight,
      _hijab,
      _skin,
      _beauty,
      _religious,
      _eyeColors,
      _hairColors,
      _hairTypes,
      _acceptPolygamy,
      _securedHousing,
      _quranMemorization,
      _reducedMahr,
      _religiousStudy,
      _featureFinancialStatus,
      _smoking,
      _hookah,
    ].where(
      (list) => list.isNotEmpty,
    ).length;
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Directionality(
      textDirection:
          ui.TextDirection.rtl,
      child: IslamicScaffold(
        appBar: widget.embedded
            ? null
            : IslamicAppBar(
                title: widget.isGroomRole
                    ? (_awaitingGroomProposals.isNotEmpty
                        ? 'مراجعة صورة الفتاة'
                        : (_groomSearchLocked
                            ? 'متابعة الرغبات'
                            : 'البحث عن شريكة'))
                    : 'طلبات الزواج',
          actions: [
            if (widget.isGroomRole && _awaitingGroomProposals.isNotEmpty)
              IconButton(
                tooltip: 'عرض صورة الفتاة',
                icon: const Icon(Icons.photo_camera_front_outlined),
                onPressed: _openFirstAwaitingReview,
              ),
            HelpIconButton(
              title: widget.isGroomRole
                  ? 'كيف يعمل البحث؟'
                  : 'كيف تعمل الطلبات؟',
              body: widget.isGroomRole
                  ? '${UiCopy.explorationGroomHint}\n\n${UiCopy.explorationPrivacyHint}'
                  : '${UiCopy.explorationBrideHint}\n\n${UiCopy.explorationPrivacyHint}',
              color: Colors.white,
            ),
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(
                Icons.settings_outlined,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/settings',
                );
              },
            ),
                IconButton(
                  tooltip: 'تسجيل الخروج',
                  icon: const Icon(
                    Icons.logout_rounded,
                  ),
                  onPressed: () => _logout(context),
                ),
              ],
            ),
        floatingActionButton:
            widget.isGroomRole && _awaitingGroomProposals.isNotEmpty
                ? FloatingActionButton.extended(
                    onPressed: _openFirstAwaitingReview,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.photo_camera_front_outlined),
                    label: const Text('عرض صورة الفتاة'),
                  )
                : null,
        body: widget.isGroomRole
            ? _buildGroomExplorer()
            : _buildBrideManager(),
      ),
    );
  }
}

// ============================================================
// نطاق الدخل
// ============================================================

class _IncomeRange {
  final double? min;
  final double? max;
  final bool minInclusive;
  final bool maxInclusive;

  const _IncomeRange({
    required this.min,
    required this.max,
    required this.minInclusive,
    required this.maxInclusive,
  });
}
/// كلاس مساعد لتمرير البيانات إلى الـ Isolate
class FilterPayload {
  final List<Map<String, dynamic>> brides;
  final Map<String, dynamic> filters;

  FilterPayload({required this.brides, required this.filters});
}

/// دالة مستقلة تعمل في Isolate منفصل لمنع تجمّد واجهة المستخدم أثناء الفلترة
List<Map<String, dynamic>> _filterBridesTask(FilterPayload payload) {
  final brides = payload.brides;
  final filters = payload.filters;

  return brides.where((bride) {
    // تطبيق فلاتر العمر
    if (filters['minAge'] != null && (bride['age'] ?? 0) < filters['minAge']) {
      return false;
    }
    if (filters['maxAge'] != null && (bride['age'] ?? 0) > filters['maxAge']) {
      return false;
    }

    // تطبيق فلتر السكن/المدينة
    if (filters['city'] != null && filters['city'].toString().isNotEmpty) {
      if (bride['city'] != filters['city']) return false;
    }

    // تطبيق فلتر الحالة الاجتماعية
    if (filters['maritalStatus'] != null && filters['maritalStatus'].toString().isNotEmpty) {
      if (bride['marital_status'] != filters['maritalStatus']) return false;
    }

    // تطبيق فلتر مستوى التعليم
    if (filters['education'] != null && filters['education'].toString().isNotEmpty) {
      if (bride['education'] != filters['education']) return false;
    }

    return true;
  }).toList();
}