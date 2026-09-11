import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
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
    return LayoutWidget(mobile: mobileView(), desktop: desktopView());
  }

  Widget mobileView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Mobile Header & Segmented Tab Switcher ──
            Container(
              padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Points Management', style: AppTypography.titleLarge(context).apply(fontWeightDelta: 2)),
                  const SizedBox(height: 12),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
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
                                color: _selectedMobileTab == 0 ? Colors.white : Colors.transparent,
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
                                    color: _selectedMobileTab == 0 ? secondaryColor : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Record Payment',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedMobileTab == 0 ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedMobileTab == 0 ? secondaryColor : Colors.grey.shade700,
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
                                color: _selectedMobileTab == 1 ? Colors.white : Colors.transparent,
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
                                    color: _selectedMobileTab == 1 ? const Color(0xFF7C3AED) : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Points History',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedMobileTab == 1 ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedMobileTab == 1 ? const Color(0xFF7C3AED) : Colors.grey.shade700,
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
      backgroundColor: const Color(0xFFF5F6FA),
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
            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Record Payment & Award Points',
                          style: AppTypography.bodyLarge(context).apply(fontWeightDelta: 2)),
                      Text(
                        'Search patient by Mobile or IC to award walk-in points.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.help_outline_rounded, color: Colors.grey.shade600, size: 20),
                  tooltip: 'How Points Work',
                  onPressed: _showTermsAndConditions,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Step 1: Find Patient ──
            _sectionHeader('1', 'Find Patient', Icons.person_search_outlined),
            const SizedBox(height: 10),

            // Mode Selector Pills: [ Mobile Number ] [ IC Number ]
            _buildSearchModePills(),
            const SizedBox(height: 10),

            // Search input field with search button suffix
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

            // ── Step 2: Payment & Bonus Items ──
            _sectionHeader('2', 'Payment & Bonus Items', Icons.payments_outlined),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InputField(
                    field: InputFieldAttribute(
                      controller: _amount.controller,
                      labelText: _amount.labelText,
                      prefixText: _amount.prefixText,
                      errorMessage: _amount.errorMessage,
                      isCurrency: true,
                      maxCharacter: 9,
                      isEditable: true,
                      onChanged: (value) {
                        setState(() {
                          if (_amount.errorMessage != null) {
                            _amount.errorMessage = null;
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _pointsPreviewChip(),
              ],
            ),
            const SizedBox(height: 10),

            _buildModifiersSection(),

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

  Widget _sectionHeader(String number, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 17, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
      ],
    );
  }

  Widget _buildSearchModePills() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
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
          color: isSelected ? Colors.white : Colors.transparent,
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
              color: isSelected ? const Color(0xFF0284C7) : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0284C7) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInputField() {
    final isPhone = _searchType == PatientSearchType.phone;
    final hint = isPhone ? 'Enter mobile number (e.g. 0123456789)' : 'Enter 12-digit IC (e.g. 950101-10-1234)';
    final label = isPhone ? 'Patient Mobile Number' : 'Patient IC Number';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    isPhone ? Icons.phone_android_rounded : Icons.badge_outlined,
                    size: 19,
                    color: Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                onSubmitted: (_) => _handleSearch(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _handleSearch,
              icon: const Icon(Icons.search, size: 17),
              label: const Text('Search', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _searchError!,
              style: const TextStyle(color: errorColor, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _selectedPatientHeroCard() {
    final item = _selectedPatient!;
    final currentPoints = item.totalPoint ?? 0;
    final rmValue = (currentPoints / 10).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0284C7).withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getInitials(item.userFullname),
                    style: const TextStyle(
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.bold,
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 10, color: Color(0xFF059669)),
                              SizedBox(width: 3),
                              Text(
                                'Verified Member',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _infoPill(Icons.phone_outlined, item.userPhone ?? 'No Phone'),
                        _infoPill(Icons.badge_outlined, item.userNric ?? 'No IC'),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPatient = null;
                  });
                },
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current balance spotlight container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Current Balance:',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 6),
                Text(
                  '$currentPoints pts',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
                const Spacer(),
                Text(
                  '≈ RM $rmValue redemption value',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _multiplePatientsList(List<UserResponse> patients) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Text(
              '${patients.length} matching patients found. Select one to award points:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: patients.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = patients[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF0284C7).withAlpha(25),
                    child: Text(
                      _getInitials(item.userFullname),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                  title: Text(item.userFullname ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(
                    '${item.userPhone ?? ''}  ·  IC: ${item.userNric ?? 'N/A'}  ·  ${item.totalPoint ?? 0} pts',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedPatient = item;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.grey.shade500, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search patient by Mobile Number or IC above to view balance and award points.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
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
                  color: isSelected ? const Color(0xFF0284C7) : Colors.grey.shade700,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF0284C7).withAlpha(30),
              checkmarkColor: const Color(0xFF0284C7),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
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

  Widget _pointsPreviewChip() {
    final amount = _amount.controller.text;
    final points = amount.isNotEmpty ? _calculateTotalPoints(amount) : 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: points > 0
              ? [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)]
              : [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: points > 0 ? Colors.amber.shade300 : const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 18, color: points > 0 ? Colors.amber.shade700 : Colors.grey),
          const SizedBox(width: 6),
          Text(
            points > 0 ? '+$points pts' : '0 pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: points > 0 ? Colors.amber.shade800 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _awardPointsButton() {
    final amountText = _amount.controller.text;
    final amount = double.tryParse(amountText) ?? 0.0;
    final totalPoints = _calculateTotalPoints(amountText);
    final isReady = _selectedPatient != null && amount > 0 && totalPoints > 0;

    String buttonLabel;
    if (_selectedPatient == null) {
      buttonLabel = 'Select Patient to Award Points';
    } else if (amount <= 0) {
      buttonLabel = 'Enter Payment Amount to Award Points';
    } else {
      buttonLabel = 'Award $totalPoints Points to ${_selectedPatient!.userFullname}';
    }

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: isReady ? () => _confirmAwardPoints(_selectedPatient!, totalPoints) : null,
        icon: const Icon(Icons.stars_rounded, size: 19),
        label: Text(
          buttonLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade500,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: isReady ? 1 : 0,
        ),
      ),
    );
  }

  String _getInitials(String? fullname) {
    if (fullname == null || fullname.trim().isEmpty) return 'P';
    final parts = fullname.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RIGHT PANEL — Points History Feed
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pointsHistoryPanel({bool isMobileLayout = false}) {
    return CardContainer(
      Consumer<PointManagementController>(
        builder: (context, snapshot, _) {
          final items = snapshot.userPointsResponse?.data ?? [];

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
                        color: const Color(0xFF7C3AED).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history_rounded, color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Points Activity Log', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 2)),
                    const Spacer(),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_totalCount total',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      color: Colors.grey.shade600,
                      tooltip: 'Refresh Log',
                      onPressed: () => runFiltering(),
                    ),
                  ],
                ),
              ),
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
          Icon(Icons.receipt_long_outlined, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            'No points activity yet',
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text('Record a payment to award points.', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _historyCard(user_model.Data item) {
    final isPositive = (item.totalPoint ?? 0) > 0;
    final badgeBg = isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final badgeText = isPositive ? const Color(0xFF059669) : errorColor;
    final badgeBorder = isPositive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                  size: 17,
                  color: badgeText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.username ?? 'Patient',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.pointDescription != null && item.pointDescription!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.pointDescription!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Recorded by ${item.createdByFullname ?? 'Staff'}  ·  ${dateConverter(item.createdDate) ?? 'N/A'}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeBorder),
              ),
              child: Text(
                isPositive ? '+${item.totalPoint}' : '${item.totalPoint}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: badgeText),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'RM 10 = 1 pt  ·  10 pts = RM 1 discount  ·  12-month expiry',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
          amount: double.tryParse(_amount.controller.text),
          modifierIds: selected.map((m) => m.id).toList(),
          pointDescription:
              'Earned $totalPoint point${totalPoint == 1 ? '' : 's'} for RM ${_amount.controller.text} payment${selected.isNotEmpty ? ' (Includes bonuses)' : ''}',
        ),
      ).then((value) {
        dismissLoading();
        if (responseCode(value.code)) {
          showDialogSuccess(context, 'Points awarded to ${item.userFullname}.');
          setState(() {
            // Live update patient balance in hero card!
            item.totalPoint = (item.totalPoint ?? 0) + totalPoint;
            _amount.controller.text = '';
            _selectedModifiers.clear();
          });
          runFiltering();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: screenHeightByBreakpoint(90, 60, 42),
            padding: EdgeInsets.all(screenPadding * 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: secondaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gavel_rounded, color: secondaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Terms & Conditions', style: AppTypography.bodyLarge(context).apply(fontWeightDelta: 2)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                _tcSection('Earning Points', Icons.trending_up_rounded, [
                  'For every RM 10 spent, patients earn 1 point.',
                  'Each transaction earns a minimum of 1 and a maximum of 1,000 points.',
                  'Earn extra points on special occasions and during promotional events.',
                ]),
                const SizedBox(height: 16),
                _tcSection('Redeeming Points', Icons.card_giftcard_rounded, [
                  'Points can be redeemed for discounts or exclusive rewards at Klinik Aurora.',
                  '10 points = RM 1 redemption value.',
                ]),
                const SizedBox(height: 16),
                _tcSection('Expiry', Icons.timer_outlined, ['Points expire after 12 months of inactivity.']),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  child: Text(bullet, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
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
