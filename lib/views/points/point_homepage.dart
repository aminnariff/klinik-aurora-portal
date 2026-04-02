import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_management_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/point_management/create_point_request.dart';
import 'package:klinik_aurora_portal/models/point_management/user_points_response.dart' as user_model;
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/mobile_view/mobile_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
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
  final InputFieldAttribute _msisdn = InputFieldAttribute(
    controller: TextEditingController(text: kDebugMode ? '012' : ''),
    labelText: 'Patient Contact Number',
  );
  bool _showHowItWorks = false;

  @override
  void initState() {
    super.initState();
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(PointHomepage.displayName);
      runFiltering();
      context.read<UserController>().userAllResponse = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: const MobileView(), desktop: desktopView());
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

  Widget _recordPaymentPanel() {
    return CardContainer(
      Padding(
        padding: EdgeInsets.all(screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: secondaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Record Payment', style: AppTypography.bodyLarge(context).apply(fontWeightDelta: 2)),
              ],
            ),
            const SizedBox(height: 16),

            // ── How it works banner ──
            _howItWorksBanner(),
            const SizedBox(height: 20),

            // ── Step 1: Amount ──
            _stepHeader(1, 'Enter Payment Amount', Icons.payments_outlined),
            const SizedBox(height: 8),
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
            const SizedBox(height: 16),

            // ── Step 2: Search Patient ──
            _stepHeader(2, 'Search Patient', Icons.person_search_outlined),
            const SizedBox(height: 8),
            InputField(
              field: InputFieldAttribute(
                controller: _msisdn.controller,
                labelText: _msisdn.labelText,
                maxCharacter: 12,
                suffixWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _handleSearch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Search',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Step 3: Patient results ──
            Consumer<UserController>(
              builder: (context, snapshot, _) {
                final patients = snapshot.userAllResponse ?? [];
                if (patients.isEmpty) return const SizedBox();

                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _stepHeader(3, 'Select Patient to Award Points', Icons.how_to_reg_outlined),
                      const SizedBox(height: 4),
                      Text(
                        '${patients.length} patient${patients.length == 1 ? '' : 's'} found',
                        style: AppTypography.bodyMedium(context).apply(color: Colors.grey.shade600, fontSizeDelta: -1),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8ECF1)),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: patients.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, index) {
                              final item = patients[index];
                              return _patientTile(item);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      margin: EdgeInsets.fromLTRB(screenPadding, screenPadding, 0, screenPadding),
    );
  }

  Widget _stepHeader(int step, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(7)),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
      ],
    );
  }

  Widget _pointsPreviewChip() {
    final amount = _amount.controller.text;
    final points = amount.isNotEmpty ? calculateCustomerPoints(amount) : 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: points > 0
              ? [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)]
              : [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: points > 0 ? Colors.amber.shade300 : const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 20, color: points > 0 ? Colors.amber.shade700 : Colors.grey),
          const SizedBox(width: 6),
          Text(
            points > 0 ? '$points pts' : '0 pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: points > 0 ? Colors.amber.shade800 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientTile(UserResponse item) {
    final int previewPoints = calculateCustomerPoints(_amount.controller.text);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _confirmAwardPoints(item, previewPoints),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: secondaryColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_outline_rounded, color: secondaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.userFullname ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '${item.userPhone ?? 'N/A'}  ·  ${item.totalPoint ?? 0} points',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: secondaryColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: secondaryColor.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, color: secondaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Award $previewPoints pts',
                      style: const TextStyle(color: secondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
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

  // ── How It Works Banner ───────────────────────────────────────────────────

  Widget _howItWorksBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [secondaryColor.withAlpha(15), primary.withAlpha(10)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: secondaryColor.withAlpha(40)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _showHowItWorks = !_showHowItWorks),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('How Points Work', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  // Quick conversion pills always visible
                  _conversionPill('RM 100', '10 pts'),
                  const SizedBox(width: 8),
                  _conversionPill('10 pts', 'RM 1'),
                  const SizedBox(width: 8),
                  Icon(_showHowItWorks ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade600, size: 22),
                ],
              ),
            ),
          ),
          if (_showHowItWorks) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patients earn points with every payment at Klinik Aurora.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  _infoBullet('For every RM 10 spent, patients earn 1 point.'),
                  _infoBullet('Each transaction earns a minimum of 1 and a maximum of 1,000 points.'),
                  _infoBullet('Points expire after 12 months of inactivity.'),
                  _infoBullet('Points can be redeemed for discounts or exclusive rewards.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _showTermsAndConditions,
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('View Terms & Conditions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryColor,
                      side: const BorderSide(color: secondaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _conversionPill(String from, String to) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(from, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward, size: 10, color: Colors.grey),
          ),
          Text(
            to,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
          ),
        ],
      ),
    );
  }

  Widget _infoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RIGHT PANEL — Points History
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pointsHistoryPanel() {
    return CardContainer(
      Consumer<PointManagementController>(
        builder: (context, snapshot, _) {
          final items = snapshot.userPointsResponse?.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
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
                    Text('Points History', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 2)),
                    const Spacer(),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_totalCount total',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              // ── History list ──
              Expanded(
                child: items.isEmpty
                    ? _emptyHistoryState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (_, index) => _historyCard(items[index]),
                      ),
              ),

              // ── Pagination ──
              const Divider(height: 1),
              paginationWidget(),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No points activity yet',
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text('Record a payment to get started.', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _historyCard(user_model.Data item) {
    final isPositive = (item.totalPoint ?? 0) > 0;
    final accentColor = isPositive ? const Color(0xFF2ECC40) : errorColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.username ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.pointDescription != null) ...[
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
                            'Recorded by ${item.createdByFullname ?? 'N/A'}  ·  ${dateConverter(item.createdDate) ?? 'N/A'}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Points badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPositive ? '+${item.totalPoint}' : '${item.totalPoint}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor),
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  ACTIONS & DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleSearch() {
    if (_amount.controller.text.isEmpty) {
      setState(() {
        _amount.errorMessage = ErrorMessage.required(field: _amount.labelText);
      });
      return;
    }

    if (calculateCustomerPoints(_amount.controller.text) <= 0) {
      setState(() {
        _amount.errorMessage = 'Please enter a valid amount (minimum RM 1)';
      });
      return;
    }

    showLoading();
    UserController.getAll(context, 1, 20, userPhone: _msisdn.controller.text).then((value) async {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<UserController>().userAllResponse = value.data?.data;
      } else {
        showDialogError(context, 'No patients found. Please check the contact number and try again.');
      }
    });
  }

  Future<void> _confirmAwardPoints(UserResponse item, int totalPoint) async {
    if (await showConfirmDialog(
      context,
      'Award $totalPoint point${totalPoint == 1 ? '' : 's'} to ${item.userFullname} for RM ${_amount.controller.text} payment?',
    )) {
      PointManagementController.create(
        context,
        CreatePointRequest(
          userId: item.userId,
          totalPoint: totalPoint,
          pointDescription:
              'Earned $totalPoint point${totalPoint == 1 ? '' : 's'} for RM ${_amount.controller.text} payment',
        ),
      ).then((value) {
        dismissLoading();
        if (responseCode(value.code)) {
          showDialogSuccess(
            context,
            'Successfully awarded $totalPoint point${totalPoint == 1 ? '' : 's'} to ${item.userFullname}.',
          );
          _amount.controller.text = '';
          _msisdn.controller.text = '';
          context.read<UserController>().userAllResponse = null;
          runFiltering();
        } else {
          showDialogError(context, value.data?.message ?? 'error'.tr(gender: 'err-7'));
        }
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
    });
  }
}
