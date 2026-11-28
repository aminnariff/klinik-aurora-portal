import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_management_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_modifier_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/point_management/create_point_request.dart';
import 'package:klinik_aurora_portal/models/point_management/point_modifier.dart';
import 'package:klinik_aurora_portal/models/point_management/user_points_response.dart' as user_model;
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/aurora/aurora_3d_star_badge.dart';
import 'package:klinik_aurora_portal/views/widgets/reward/eligible_rewards_panel.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/table/data_per_page.dart';
import 'package:klinik_aurora_portal/views/widgets/table/pagination.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

enum PatientSearchType { phone, ic }

class PointHomepage extends StatefulWidget {
  static const routeName = '/points';
  static const displayName = 'Points';
  const PointHomepage({super.key});

  @override
  State<PointHomepage> createState() => _PointHomepageState();
}

class _PointHomepageState extends State<PointHomepage> {
  /// Green for balance figures; #1E822B is unreadable on dark surfaces.
  Color get _successInk => appIsDarkMode ? const Color(0xFF6EE7B7) : const Color(0xFF1E822B);

  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);

  final InputFieldAttribute _amount = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Payment Amount',
    prefixText: 'RM',
  );

  PatientSearchType _searchType = PatientSearchType.phone;
  final TextEditingController _searchController = TextEditingController(text: kDebugMode ? '012' : '');
  String? _searchError;
  UserResponse? _selectedPatient;
  final List<UserResponse> _recentPatients = [];
  bool _filterTodayOnly = false;

  int _selectedMobileTab = 0;

  /// Bonus rules configured under Point Modifiers, fetched from the API.
  ///
  /// Empty when none are configured or the request failed — awarding base
  /// points keeps working either way.
  List<PointModifier> _availableModifiers = [];
  final Set<String> _selectedModifiers = {};

  @override
  void dispose() {
    _searchController.dispose();
    _amount.controller.dispose();
    super.dispose();
  }

  void _fetchModifiers() {
    PointModifierController.getActive(context).then((value) {
      if (!mounted) return;
      if (responseCode(value.code)) {
        setState(() => _availableModifiers = value.data ?? []);
      } else {
        debugPrint('[Points] Could not load modifiers: ${value.message}');
      }
    });
  }

  /// On-screen estimate only.
  ///
  /// The server recalculates from the amount and the selected modifier IDs, and
  /// will award more than this if a campaign multiplier is live — the portal
  /// has no way to read that multiplier, so this is labelled an estimate.
  int _calculateTotalPoints(String amountStr) {
    final basePoints = calculateCustomerPoints(amountStr);
    if (basePoints == 0) return 0;

    var finalPoints = basePoints;
    for (final id in _selectedModifiers) {
      final modifier = _availableModifiers.where((m) => m.id == id).firstOrNull;
      // A modifier deleted or expired since page load simply drops out here;
      // the server would ignore it too.
      if (modifier == null) continue;
      finalPoints += modifier.bonusFor(basePoints);
    }
    return finalPoints;
  }

  @override
  void initState() {
    super.initState();
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(PointHomepage.displayName);
      runFiltering();
      context.read<UserController>().userAllResponse = null;
      _fetchModifiers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: mobileView(), tablet: mobileView(), desktop: desktopView());
  }

  Widget mobileView() {
    return Scaffold(
      backgroundColor: appCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // ── Mobile Header & Segmented Tab Switcher ──
            Container(
              padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 12),
              color: appSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Aurora3DStarBadge(size: 26),
                      const SizedBox(width: 10),
                      Text('Points Management', style: AppTypography.titleLarge(context).apply(fontWeightDelta: 2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: appSurfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMobileTab = 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedMobileTab == 0 ? appSurface : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedMobileTab == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 18,
                                    color: _selectedMobileTab == 0 ? secondaryColor : appInkMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Record Payment',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedMobileTab == 0 ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedMobileTab == 0 ? secondaryColor : appInkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMobileTab = 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedMobileTab == 1 ? appSurface : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedMobileTab == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 18,
                                    color: _selectedMobileTab == 1 ? const Color(0xFF2ECC40) : appInkMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Points History',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedMobileTab == 1 ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedMobileTab == 1 ? const Color(0xFF2ECC40) : appInkSecondary,
                                    ),
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
            const Divider(height: 1),

            // ── Tab Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenPadding),
                child: _selectedMobileTab == 0
                    ? _recordPaymentPanel(isMobileLayout: true)
                    : _pointsHistoryPanel(isMobileLayout: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget desktopView() {
    return Scaffold(
      backgroundColor: appCanvas,
      body: SizedBox(
        height: screenHeight(100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AppPadding.vertical(),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 3, child: SizedBox(child: _recordPaymentPanel())),
                  Expanded(flex: 2, child: _pointsHistoryPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LEFT PANEL — Record Payment
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _recordPaymentPanel({bool isMobileLayout = false}) {
    return CardContainer(
      SingleChildScrollView(
        padding: EdgeInsets.all(screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Elevated Terminal Header ──
            _buildTerminalHeader(),
            const SizedBox(height: 18),

            // ── Step 1: Find Patient ──
            _sectionHeader(
              '1',
              'Identify Patient',
              'Search patient by Mobile Number or MyKad to link transaction.',
              Icons.person_search_outlined,
            ),
            const SizedBox(height: 10),

            // Mode Selector Pills: [ Mobile Number ] [ IC Number ]
            _buildSearchModePills(),
            const SizedBox(height: 10),

            // Recent patients quick-select strip
            _recentPatientsStrip(),

            // Search input field with integrated action
            _buildSearchInputField(),

            // Selected Patient Hero Card OR Results List OR Empty placeholder
            Consumer<UserController>(
              builder: (context, snapshot, _) {
                final patients = snapshot.userAllResponse ?? [];

                if (_selectedPatient != null) {
                  return _selectedPatientHeroCard();
                }

                if (patients.length > 1) {
                  return _multiplePatientsList(patients);
                }

                return _emptyPatientPlaceholder();
              },
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 14),

            // ── Step 2: Payment & Clinical Scan Billing ──
            _buildStep2PaymentSection(),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // ── Step 3: Award Action CTA ──
            _awardPointsButton(),
            const SizedBox(height: 8),
          ],
        ),
      ),
      margin: isMobileLayout
          ? EdgeInsets.zero
          : (isMobile
              ? EdgeInsets.all(screenPadding)
              : EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding / 2, screenPadding)),
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: appIsDarkMode
              ? [const Color(0xFF1E1728), const Color(0xFF111B22)]
              : [const Color(0xFFFBF4F8), const Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: appIsDarkMode ? const Color(0xFF33253B) : const Color(0xFFF3E8F0),
        ),
      ),
      child: Row(
        children: [
          const Aurora3DStarBadge(size: 38),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Frontdesk Points POS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: appInkPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 11, color: Color(0xFF10B981)),
                          SizedBox(width: 2),
                          Text(
                            'LIVE TERMINAL',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Record walk-in scans & payments to reward loyalty points in real-time.',
                  style: TextStyle(fontSize: 12, color: appInkMuted),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _showTermsAndConditions,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: appSurface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: appBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: appInkMuted),
                  const SizedBox(width: 6),
                  Text(
                    'RM 1 = 1 pt',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: appInkSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String number, String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [secondaryColor, const Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: secondaryColor.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: appInkPrimary),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11.5, color: appInkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInputField() {
    final isPhone = _searchType == PatientSearchType.phone;
    final hint = isPhone ? 'Enter mobile number (e.g. 0123456789)...' : 'Enter MyKad number (e.g. 950101-10-1234)...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: appSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: appBorderStrong),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                isPhone ? Icons.phone_android_rounded : Icons.badge_outlined,
                size: 18,
                color: appInkMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 13.5, color: appInkPrimary, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(fontSize: 12.5, color: appInkMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 16, color: appInkMuted),
                  splashRadius: 16,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchError = null;
                    });
                  },
                ),
              const SizedBox(width: 4),
              EmilPressable(
                onTap: _handleSearch,
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondaryColor, const Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Find Patient',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 13, color: errorColor),
                const SizedBox(width: 4),
                Text(
                  _searchError!,
                  style: TextStyle(color: errorColor, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _selectedPatientHeroCard() {
    final item = _selectedPatient!;
    final currentPoints = item.totalPoint ?? 0;
    final pendingEarn = _calculateTotalPoints(_amount.controller.text);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: appIsDarkMode
              ? [const Color(0xFF16202C), const Color(0xFF0F171F)]
              : [const Color(0xFFF0FDF4), const Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: appIsDarkMode ? const Color(0xFF1F3A4D) : const Color(0xFFBBF7D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top header strip
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with glowing ring
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6AD1E3), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6AD1E3).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(item.userFullname),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.userFullname ?? 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: appInkPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _infoPill(Icons.phone_rounded, item.userPhone ?? 'No Phone'),
                          _infoPill(Icons.badge_rounded, item.userNric ?? 'No IC'),
                        ],
                      ),
                    ],
                  ),
                ),
                EmilPressable(
                  onTap: () => setState(() => _selectedPatient = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: appSurfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: appBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 14, color: appInkSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Change',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: appInkSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Vault Spotlight Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: appIsDarkMode ? const Color(0xFF101B24) : const Color(0xFFECFDF5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
              border: Border(
                top: BorderSide(
                  color: appIsDarkMode ? const Color(0xFF1A2C3A) : const Color(0xFFD1FAE5),
                ),
              ),
            ),
            child: Row(
              children: [
                const Aurora3DStarBadge(size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOYALTY VAULT BALANCE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: appIsDarkMode ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                        letterSpacing: 0.6,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$currentPoints',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const Text(
                          ' pts',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          EligibleRewardsPanel(
            userId: item.userId ?? '',
            patientName: item.userFullname ?? 'Patient',
            currentPoints: currentPoints,
            projectedPoints: currentPoints + pendingEarn,
            onPointsUpdated: (newTotal) {
              setState(() {
                _selectedPatient?.totalPoint = newTotal;
                for (final p in _recentPatients) {
                  if (p.userId == item.userId) {
                    p.totalPoint = newTotal;
                  }
                }
              });
              filtering(enableDebounce: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2PaymentSection() {
    final amountText = _amount.controller.text;
    final totalPoints = _calculateTotalPoints(amountText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          '2',
          'Payment & Bill Amount',
          'Enter bill amount or tap a quick preset.',
          Icons.payments_outlined,
        ),
        const SizedBox(height: 12),

        // Monetary Input Box with integrated Live Points Counter
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: appSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: totalPoints > 0 ? secondaryColor.withValues(alpha: 0.6) : appBorderStrong,
              width: totalPoints > 0 ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'RM',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: appInkSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amount.controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}(\.\d{0,2})?')),
                  ],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: appInkPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: appInkMuted.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (_amount.errorMessage != null) _amount.errorMessage = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Dynamic Points badge embedded inside amount box
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: totalPoints > 0
                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                        : [appSurfaceSubtle, appSurfaceSubtle],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: totalPoints > 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: totalPoints > 0 ? Colors.white : appInkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      totalPoints > 0 ? '+$totalPoints pts' : '0 pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: totalPoints > 0 ? Colors.white : appInkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick Scan Presets (Tactile Clinical Ultrasound Chips)
        _quickAmountPresets(),

        const SizedBox(height: 14),
        _buildModifiersSection(),

        if (_selectedPatient != null && totalPoints > 0) ...[
          const SizedBox(height: 14),
          _liveBalancePreviewCard(),
        ],
      ],
    );
  }

  Widget _buildSearchModePills() {
    return Container(
      decoration: BoxDecoration(
        color: appSurfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _searchPillItem(
            type: PatientSearchType.phone,
            label: 'Mobile Number',
            icon: Icons.phone_android_rounded,
          ),
          const SizedBox(width: 4),
          _searchPillItem(
            type: PatientSearchType.ic,
            label: 'IC / MyKad Number',
            icon: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }

  Widget _searchPillItem({
    required PatientSearchType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _searchType == type;

    return GestureDetector(
      onTap: () {
        if (_searchType != type) {
          setState(() {
            _searchType = type;
            _searchError = null;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? appSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? secondaryColor : appInkMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? secondaryColor : appInkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: appSurfaceSubtle,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: appInkMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10.5, color: appInkSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _multiplePatientsList(List<UserResponse> patients) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Text(
              '${patients.length} matching patients found. Select one to award points:',
              style: TextStyle(fontSize: 11.5, color: appInkMuted, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: patients.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = patients[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: secondaryColor.withValues(alpha: appIsDarkMode ? 0.35 : 0.15),
                    child: Text(
                      _getInitials(item.userFullname),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: appIsDarkMode ? Colors.white : tertiaryColor,
                      ),
                    ),
                  ),
                  title: Text(item.userFullname ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                  subtitle: Text(
                    '${item.userPhone ?? ''}  ·  IC: ${item.userNric ?? 'N/A'}  ·  ${item.totalPoint ?? 0} pts',
                    style: TextStyle(fontSize: 11, color: appInkMuted),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedPatient = item;
                      });
                      _addRecentPatient(item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Select', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPatientPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appSurfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: appInkMuted, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search patient by Mobile Number or IC above to view balance and award points.',
              style: TextStyle(fontSize: 11, color: appInkMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifiersSection() {
    if (_availableModifiers.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Qualifying Items (Bonus Points)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appInkSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _availableModifiers.map((modifier) {
            final isSelected = _selectedModifiers.contains(modifier.id);
            return FilterChip(
              label: Text(
                '${modifier.itemName} (${modifier.summary})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? secondaryColor : appInkSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: secondaryColor.withAlpha(30),
              checkmarkColor: secondaryColor,
              backgroundColor: appSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? secondaryColor : appBorder,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedModifiers.add(modifier.id);
                  } else {
                    _selectedModifiers.remove(modifier.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _awardPointsButton() {
    final amountText = _amount.controller.text;
    final amount = double.tryParse(amountText) ?? 0.0;
    final totalPoints = _calculateTotalPoints(amountText);
    final isReady = _selectedPatient != null && amount > 0 && totalPoints > 0;

    String buttonLabel;
    if (_selectedPatient == null) {
      buttonLabel = '1. Select Patient to Award Points';
    } else if (amount <= 0) {
      buttonLabel = '2. Enter Amount or Tap Scan Preset';
    } else {
      buttonLabel = 'Award $totalPoints Points & Send WhatsApp Receipt';
    }

    return EmilPressable(
      enabled: isReady,
      onTap: isReady ? () => _confirmAwardPoints(_selectedPatient!, totalPoints) : null,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: isReady
              ? const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isReady ? null : appBorder,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReady ? Icons.stars_rounded : Icons.lock_outline_rounded,
              size: 20,
              color: isReady ? Colors.white : appInkMuted,
            ),
            const SizedBox(width: 8),
            Text(
              buttonLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: isReady ? Colors.white : appInkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addRecentPatient(UserResponse patient) {
    setState(() {
      _recentPatients.removeWhere((p) => p.userId == patient.userId);
      _recentPatients.insert(0, patient);
      if (_recentPatients.length > 5) {
        _recentPatients.removeLast();
      }
    });
  }

  Widget _recentPatientsStrip() {
    if (_recentPatients.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 13, color: appInkMuted),
              const SizedBox(width: 4),
              Text(
                'Recent Patients (Quick Select):',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: appInkMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _recentPatients.map((p) {
                final isSelected = _selectedPatient?.userId == p.userId;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedPatient = p;
                        _searchError = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? secondaryColor.withValues(alpha: 0.15) : appSurfaceSubtle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? secondaryColor : appBorder,
                          width: isSelected ? 1.2 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: secondaryColor.withValues(alpha: appIsDarkMode ? 0.35 : 0.2),
                            child: Text(
                              _getInitials(p.userFullname),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: appIsDarkMode ? Colors.white : tertiaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.userFullname ?? 'Patient',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? secondaryColor : appInkPrimary,
                            ),
                          ),
                          if (p.totalPoint != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${p.totalPoint} pts)',
                              style: TextStyle(fontSize: 10, color: appInkMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAmountPresets() {
    final presets = [50, 80, 100, 150, 200, 250];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((val) {
        final currentVal = double.tryParse(_amount.controller.text) ?? 0.0;
        final isMatch = (currentVal - val).abs() < 0.01;

        return EmilPressable(
          onTap: () {
            setState(() {
              _amount.controller.text = val.toString();
              if (_amount.errorMessage != null) _amount.errorMessage = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isMatch ? secondaryColor.withValues(alpha: 0.15) : appSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMatch ? secondaryColor : appBorderStrong,
                width: isMatch ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMatch) ...[
                  Icon(Icons.check_rounded, size: 13, color: secondaryColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  'RM $val',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isMatch ? FontWeight.w700 : FontWeight.w600,
                    color: isMatch ? secondaryColor : appInkPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _liveBalancePreviewCard() {
    final patient = _selectedPatient!;
    final currentPoints = patient.totalPoint ?? 0;
    final earned = _calculateTotalPoints(_amount.controller.text);
    final newTotal = currentPoints + earned;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appInfoSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accessibleAccent(const Color(0xFF6366F1)).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Aurora3DStarBadge(size: 20),
              const SizedBox(width: 8),
              Text(
                'Live Points Balance Preview',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: appInfoText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _balanceStepTile(
                  label: 'Current',
                  value: '$currentPoints pts',
                  color: appInkSecondary,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 16, color: appInkMuted),
              Expanded(
                child: _balanceStepTile(
                  label: 'This Payment',
                  value: '+$earned pts',
                  color: const Color(0xFF10B981),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 16, color: appInkMuted),
              Expanded(
                child: _balanceStepTile(
                  label: 'New Balance',
                  value: '$newTotal pts',
                  color: accessibleAccent(const Color(0xFF4F46E5)),
                  bold: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: appSurface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 13, color: appInkMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Points redeem for Rewards Catalog items (100 pts ≈ RM 1 of reward value).',
                    style: TextStyle(fontSize: 11, color: appInkMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceStepTile({
    required String label,
    required String value,
    required Color color,
    bool bold = false,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: appInkMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 13 : 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _sendWhatsAppPointsReceipt({
    required UserResponse patient,
    required int earnedPoints,
    required double paymentAmount,
    required int newTotalPoints,
  }) async {
    final rawPhone = (patient.userPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (rawPhone.isEmpty) {
      showDialogError(context, 'Patient has no phone number recorded.');
      return;
    }
    final formattedPhone = rawPhone.startsWith('60')
        ? rawPhone
        : (rawPhone.startsWith('0') ? '6$rawPhone' : '60$rawPhone');
    final patientName = patient.userFullname ?? 'Pelanggan';

    final text = '''
*KLINIK AURORA — PENYATA MATA GANJARAN (AURORA REWARDS)* 🌟

Assalamualaikum & Salam Sejahtera *$patientName*,

Mata ganjaran kesetiaan anda telah berjaya dikreditkan ke akaun Klinik Aurora anda:

💵 *Jumlah Bayaran:* RM ${paymentAmount.toStringAsFixed(2)}
⭐ *Mata Diperoleh:* +$earnedPoints pts
🏆 *Jumlah Terkini:* $newTotalPoints pts

_Tebus mata ganjaran anda untuk diskaun rawatan, konsultasi & imbasan seterusnya di mana-mana cawangan Klinik Aurora._

Layari aplikasi Klinik Aurora untuk semakan baki dan temujanji anda.
Terima kasih kerana mempercayai Klinik Aurora! 🌸
''';

    final uri = Uri.parse('https://api.whatsapp.com/send?phone=$formattedPhone&text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showDialogError(context, 'Could not open WhatsApp.');
    }
  }

  void _showAwardSuccessDialog({
    required UserResponse patient,
    required int earnedPoints,
    required double paymentAmount,
    required int newTotalPoints,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: appSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Aurora3DStarBadge(size: 52),
                const SizedBox(height: 14),
                Text(
                  'Points Awarded Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: appInkPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Awarded +$earnedPoints pts to ${patient.userFullname}',
                  style: TextStyle(fontSize: 13, color: appInkSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC40).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2ECC40).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'NEW TOTAL BALANCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _successInk,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$newTotalPoints pts',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _successInk),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 1-Tap WhatsApp Button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _sendWhatsAppPointsReceipt(
                        patient: patient,
                        earnedPoints: earnedPoints,
                        paymentAmount: paymentAmount,
                        newTotalPoints: newTotalPoints,
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      '1-Tap WhatsApp Receipt to Patient',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: appInkPrimary,
                      side: BorderSide(color: appBorderStrong),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final d = DateTime.tryParse(dateStr);
      if (d != null) {
        final now = DateTime.now();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }
    } catch (_) {}
    return false;
  }

  String _getInitials(String? fullname) {
    if (fullname == null || fullname.trim().isEmpty) return 'P';
    final parts = fullname.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _cleanStaffOrBranch(String? text) {
    if (text == null || text.trim().isEmpty) return 'Staff';
    return text
        .replaceAll('Klinik Aurora ', '')
        .replaceAll('Klinik Aurora', '')
        .replaceAll('KLINIK AURORA ', '')
        .replaceAll('KLINIK AURORA', '')
        .trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RIGHT PANEL — Points History Feed
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pointsHistoryPanel({bool isMobileLayout = false}) {
    return CardContainer(
      Consumer<PointManagementController>(
        builder: (context, snapshot, _) {
          final allItems = snapshot.userPointsResponse?.data ?? [];
          final todayItems = allItems.where((it) => _isToday(it.createdDate)).toList();
          final items = _filterTodayOnly ? todayItems : allItems;
          final todayCount = todayItems.length;
          final todayPoints = todayItems.fold<int>(0, (sum, it) => sum + (it.totalPoint ?? 0));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: isMobileLayout ? MainAxisSize.min : MainAxisSize.max,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC40).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history_rounded, color: Color(0xFF2ECC40), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Points Activity Log', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 2)),
                    const Spacer(),
                    if (allItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: appSurfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_totalCount total',
                          style: TextStyle(fontSize: 11, color: appInkMuted, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      color: appInkMuted,
                      tooltip: 'Refresh Log',
                      onPressed: () => runFiltering(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Segmented Shift Switcher: [ All History ] [ Today's Shift ]
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenPadding),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _filterTodayOnly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: !_filterTodayOnly ? secondaryColor.withValues(alpha: 0.15) : appSurfaceSubtle,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: !_filterTodayOnly ? secondaryColor : appBorder),
                        ),
                        child: Text(
                          'All History ($_totalCount)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: !_filterTodayOnly ? FontWeight.w700 : FontWeight.w500,
                            color: !_filterTodayOnly ? secondaryColor : appInkSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _filterTodayOnly = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _filterTodayOnly ? const Color(0xFF2ECC40).withValues(alpha: 0.15) : appSurfaceSubtle,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _filterTodayOnly ? const Color(0xFF2ECC40) : appBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.today_rounded,
                              size: 13,
                              color: _filterTodayOnly ? const Color(0xFF2ECC40) : appInkMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Today's Shift ($todayCount)",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _filterTodayOnly ? FontWeight.w700 : FontWeight.w500,
                                color: _filterTodayOnly ? const Color(0xFF2ECC40) : appInkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_filterTodayOnly) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenPadding),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC40).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2ECC40).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF2ECC40)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$todayCount patients rewarded · $todayPoints pts issued today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _successInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1),

              // History list
              isMobileLayout
                  ? (items.isEmpty
                      ? SizedBox(height: 200, child: _emptyHistoryState())
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 2),
                          itemBuilder: (_, index) => _historyCard(items[index]),
                        ))
                  : Expanded(
                      child: items.isEmpty
                          ? _emptyHistoryState()
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 2),
                              itemBuilder: (_, index) => _historyCard(items[index]),
                            ),
                    ),

              // Bottom conversion formula badge
              _conversionInfoPill(),

              // Pagination
              const Divider(height: 1),
              paginationWidget(),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
      margin: isMobileLayout
          ? EdgeInsets.zero
          : (isMobile
              ? EdgeInsets.all(screenPadding)
              : EdgeInsets.fromLTRB(screenPadding / 2, screenPadding, screenPadding, screenPadding)),
    );
  }

  Widget _emptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 44, color: appBorderStrong),
          const SizedBox(height: 10),
          Text(
            'No points activity yet',
            style: TextStyle(color: appInkMuted, fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text('Record a payment to award points.', style: TextStyle(color: appInkMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _historyCard(user_model.Data item) {
    final isPositive = (item.totalPoint ?? 0) > 0;
    final accentColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: appIsDarkMode ? const Color(0xFF131D26) : appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: appIsDarkMode ? const Color(0xFF1E2D3A) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Sleek 3.5px rounded indicator
            Container(
              width: 3.5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: accentColor.withValues(alpha: 0.12),
                      child: Text(
                        _getInitials(item.username),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accentColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.username ?? 'Patient',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: appInkPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.pointDescription != null && item.pointDescription!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.pointDescription!,
                              style: TextStyle(fontSize: 11, color: appInkSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 11, color: appInkMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${dateConverter(item.createdDate) ?? 'N/A'}  ·  by ${_cleanStaffOrBranch(item.createdByFullname)}',
                                  style: TextStyle(fontSize: 10.5, color: appInkMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.add_rounded : Icons.remove_rounded,
                            size: 13,
                            color: accentColor,
                          ),
                          Text(
                            '${(item.totalPoint ?? 0).abs()}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'pts',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversionInfoPill() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appSurfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Aurora3DStarBadge(size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'RM 1 = 1 pt  ·  100 pts ≈ RM 1 reward value  ·  12-month expiry',
              style: TextStyle(fontSize: 11, color: appInkMuted, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ACTIONS & SEARCH
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchError = _searchType == PatientSearchType.phone
            ? 'Please enter patient mobile number'
            : 'Please enter patient IC number';
      });
      return;
    }

    setState(() {
      _searchError = null;
      _selectedPatient = null;
    });

    showLoading();
    final isPhone = _searchType == PatientSearchType.phone;
    final searchFuture = isPhone
        ? UserController.getAll(context, 1, 20, userPhone: query)
        : UserController.getAll(context, 1, 20, userNric: query);

    searchFuture.then((value) async {
      dismissLoading();
      if (responseCode(value.code)) {
        final results = value.data?.data ?? [];
        context.read<UserController>().userAllResponse = results;
        if (results.isEmpty) {
          showDialogError(context, 'No patient found matching "$query".');
        } else if (results.length == 1) {
          setState(() {
            _selectedPatient = results.first;
          });
          _addRecentPatient(results.first);
        }
      } else {
        showDialogError(context, 'No patient found matching "$query".');
      }
    }).catchError((e) {
      dismissLoading();
      showDialogError(context, e.toString());
    });
  }

  Future<void> _confirmAwardPoints(UserResponse item, int totalPoint) async {
    final selected = _availableModifiers.where((m) => _selectedModifiers.contains(m.id)).toList();
    final bonusLine = selected.isEmpty ? '' : '\n\nBonuses: ${selected.map((m) => m.itemName).join(', ')}';
    final paymentAmount = double.tryParse(_amount.controller.text) ?? 0.0;

    if (await showConfirmDialog(
      context,
      'Award $totalPoint point${totalPoint == 1 ? '' : 's'} to ${item.userFullname} for RM ${_amount.controller.text} payment?$bonusLine',
    )) {
      showLoading();
      PointManagementController.create(
        context,
        CreatePointRequest(
          userId: item.userId,
          totalPoint: totalPoint,
          amount: paymentAmount,
          modifierIds: selected.map((m) => m.id).toList(),
          pointDescription:
              'Earned $totalPoint point${totalPoint == 1 ? '' : 's'} for RM ${_amount.controller.text} payment${selected.isNotEmpty ? ' (Includes bonuses)' : ''}',
        ),
      ).then((value) {
        dismissLoading();
        if (responseCode(value.code)) {
          final newTotal = (item.totalPoint ?? 0) + totalPoint;
          setState(() {
            // Live update patient balance in hero card!
            item.totalPoint = newTotal;
            _amount.controller.text = '';
            _selectedModifiers.clear();
          });
          _addRecentPatient(item);
          runFiltering();
          _showAwardSuccessDialog(
            patient: item,
            earnedPoints: totalPoint,
            paymentAmount: paymentAmount,
            newTotalPoints: newTotal,
          );
        } else {
          showDialogError(context, value.message ?? value.data?.message ?? 'error'.tr(gender: 'err-7'));
        }
      }).catchError((e) {
        dismissLoading();
        showDialogError(context, e.toString());
      });
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: screenHeightByBreakpoint(90, 60, 42),
            padding: EdgeInsets.all(screenPadding * 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Aurora3DStarBadge(size: 32),
                    const SizedBox(width: 12),
                    Text('How Points Work', style: AppTypography.bodyLarge(context).apply(fontWeightDelta: 2)),
                    const Spacer(),
                    IconButton(
  tooltip: 'Tutup',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                _tcSection('Earning Points', Icons.trending_up_rounded, [
                  'For every RM 1 spent, patients earn 1 point.',
                  'Each transaction earns a minimum of 1 and a maximum of 10,000 points.',
                  'Earn extra points on special occasions and during promotional events.',
                ]),
                const SizedBox(height: 16),
                _tcSection('Redeeming Points', Icons.card_giftcard_rounded, [
                  'Points can be redeemed for discounts or exclusive rewards at Klinik Aurora.',
                  'Rewards are redeemed at their Rewards Catalog point price (100 points ≈ RM 1 of reward value).',
                ]),
                const SizedBox(height: 16),
                _tcSection('Expiry', Icons.timer_outlined, ['Points expire after 12 months of inactivity.']),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tcSection(String title, IconData icon, List<String> bullets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: secondaryColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        for (final bullet in bullets)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: Colors.grey)),
                Expanded(
                  child: Text(bullet, style: TextStyle(fontSize: 13, color: appInkSecondary, height: 1.4)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PAGINATION (unchanged logic, cleaned up widget)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget paginationWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [Expanded(child: pagination())]),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMobile && !isTablet)
                    const Flexible(child: Text('Items per page: ', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  perPage(),
                ],
              ),
            ),
            if (!isMobile && !isTablet)
              Text(
                '${((_page) * _pageSize) - _pageSize + 1} – ${((_page) * _pageSize < _totalCount) ? ((_page) * _pageSize) : _totalCount} of $_totalCount',
              ),
          ],
        ),
      ],
    );
  }

  Widget perPage() {
    return PerPageWidget(
      _pageSize.toString(),
      DropdownAttributeList(
        [],
        onChanged: (selected) {
          DropdownAttribute item = selected as DropdownAttribute;
          _pageSize = int.parse(item.key);
          filtering(enableDebounce: false);
        },
      ),
    );
  }

  Widget pagination() {
    return Pagination(
      numOfPages: _totalPage,
      selectedPage: _page,
      pagesVisible: 3,
      spacing: 10,
      onPageChanged: (page) {
        _movePage(page);
      },
    );
  }

  void _movePage(int page) {
    filtering(page: page, enableDebounce: false);
  }

  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce
        ? _debouncer.run(() {
            runFiltering(page: page);
          })
        : runFiltering(page: page);
  }

  void runFiltering({bool enableDebounce = true, int? page}) {
    showLoading();
    if (page != null) {
      _page = page;
    }

    PointManagementController.get(context, _page).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<PointManagementController>().userPointsResponse = value.data;
        _totalCount = value.data?.totalCount ?? 0;
        _totalPage = value.data?.totalPage ?? ((value.data?.data?.length ?? 0) / _pageSize).ceil();
      } else {
        showDialogError(context, value.message ?? value.data?.message ?? 'error'.tr(gender: 'generic'));
      }
    }).catchError((e) {
      dismissLoading();
    });
  }
}
