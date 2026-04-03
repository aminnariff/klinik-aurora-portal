import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/promotion/promotion_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/promotion/create_promotion_request.dart';
import 'package:klinik_aurora_portal/models/promotion/promotion_all_response.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/promotion/promotion_detail.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/checkbox/checkbox.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/table/data_per_page.dart';
import 'package:klinik_aurora_portal/views/widgets/table/pagination.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:klinik_aurora_portal/views/widgets/upload_document/upload_document.dart';
import 'package:provider/provider.dart';

class PromotionHomepage extends StatefulWidget {
  static const routeName = '/promotion';
  static const displayName = 'Promotions';
  final String? orderReference;
  const PromotionHomepage({super.key, this.orderReference});

  @override
  State<PromotionHomepage> createState() => _PromotionHomepageState();
}

class _PromotionHomepageState extends State<PromotionHomepage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  final TextEditingController _searchController = TextEditingController();
  // null = All, '1' = Active, '0' = Inactive
  String? _statusFilter;

  // Create form controllers
  final TextEditingController _promotionName = TextEditingController();
  final TextEditingController _promotionDescription = TextEditingController();
  final TextEditingController _promotionTnc = TextEditingController();
  final TextEditingController _startDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();
  final ValueNotifier<bool> _showOnStart = ValueNotifier(false);
  StreamController<DateTime> rebuild = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  List<FileAttribute> selectedFiles = [];

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(
        PromotionHomepage.displayName,
      );
    });
    filtering();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: _buildBody(), tablet: _buildBody(), desktop: _buildBody());
  }

  Widget _buildBody() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(),
          Expanded(
            child: Consumer<PromotionController>(
              builder: (context, controller, _) {
                final items = controller.promotionAllResponse?.data?.data ?? [];
                final isLoading = controller.promotionAllResponse == null;

                if (isLoading) {
                  return const Center(child: CircularProgressIndicator(color: secondaryColor));
                }

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding, screenPadding / 2),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    crossAxisSpacing: screenPadding,
                    mainAxisSpacing: screenPadding,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _PromotionCard(
                    promotion: items[index],
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => PromotionDetail(promotion: items[index]),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  int get _crossAxisCount {
    final w = screenWidth(100);
    if (w > 1400) return 5;
    if (w > 1000) return 4;
    if (w > 640) return 3;
    return 2;
  }

  Widget _buildToolbar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding * 0.6),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 8),
                    _buildNewButton(),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStatusChips(),
              ],
            )
          : Row(
              children: [
                SizedBox(width: screenWidthByBreakpoint(90, 60, 26), child: _buildSearchField()),
                const SizedBox(width: 16),
                _buildStatusChips(),
                const Spacer(),
                _buildNewButton(),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => filtering(page: 1),
      onSubmitted: (_) => filtering(enableDebounce: false, page: 1),
      style: AppTypography.bodyMedium(context),
      decoration: InputDecoration(
        hintText: 'Search promotions…',
        hintStyle: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF9CA3AF)),
                onPressed: () {
                  _searchController.clear();
                  filtering(enableDebounce: false, page: 1);
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: secondaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    final options = <String?, String>{null: 'All', '1': 'Active', '0': 'Inactive'};
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.entries.map((e) {
        final selected = _statusFilter == e.key;
        Color chipColor = const Color(0xFF2196F3);
        if (e.key == '1') chipColor = const Color(0xFF059669);
        if (e.key == '0') chipColor = const Color(0xFFEF4444);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() => _statusFilter = e.key);
              filtering(enableDebounce: false, page: 1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? chipColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? chipColor : const Color(0xFFE5E7EB)),
              ),
              child: Text(
                e.value,
                style: AppTypography.bodyMedium(
                  context,
                ).apply(color: selected ? Colors.white : const Color(0xFF6B7280), fontWeightDelta: selected ? 1 : 0),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewButton() {
    return ElevatedButton.icon(
      onPressed: _openCreateDialog,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: isMobile ? const SizedBox() : const Text('New Promotion'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: primary.withAlpha(25), shape: BoxShape.circle),
            child: const Icon(Icons.local_offer_outlined, size: 36, color: primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No promotions found',
            style: AppTypography.displayMedium(context).apply(color: const Color(0xFF374151)),
          ),
          const SizedBox(height: 6),
          Text(
            _searchController.text.isNotEmpty || _statusFilter != null
                ? 'Try adjusting your filters'
                : 'Create your first promotion to get started',
            style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 24),
          if (_searchController.text.isNotEmpty || _statusFilter != null)
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _statusFilter = null);
                filtering(enableDebounce: false, page: 1);
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(color: primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    return StreamBuilder<DateTime>(
      stream: rebuild.stream,
      builder: (context, _) {
        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Pagination(
                  numOfPages: _totalPage,
                  selectedPage: _page,
                  pagesVisible: 5,
                  spacing: 8,
                  onPageChanged: (page) => filtering(page: page, enableDebounce: false),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMobile)
                    Text('Rows: ', style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280))),
                  PerPageWidget(
                    _pageSize.toString(),
                    DropdownAttributeList(
                      [],
                      onChanged: (selected) {
                        _pageSize = int.parse(selected!.key);
                        filtering(enableDebounce: false);
                      },
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${((_page) * _pageSize) - _pageSize + 1}–${(_page * _pageSize < _totalCount) ? _page * _pageSize : _totalCount} of $_totalCount',
                      style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCreateDialog() {
    _promotionName.clear();
    _promotionDescription.clear();
    _promotionTnc.clear();
    _startDate.clear();
    _endDate.clear();
    _showOnStart.value = false;
    selectedFiles.clear();

    showDialog(
      context: context,
      builder: (BuildContext ctx) => _PromotionFormDialog(
        title: 'New Promotion',
        promotionName: _promotionName,
        promotionDescription: _promotionDescription,
        promotionTnc: _promotionTnc,
        startDate: _startDate,
        endDate: _endDate,
        showOnStart: _showOnStart,
        fileRebuild: fileRebuild,
        selectedFiles: selectedFiles,
        onSave: () {
          if (_validateForm(ctx)) {
            showLoading();
            PromotionController.create(
              ctx,
              CreatePromotionRequest(
                promotionName: _promotionName.text,
                promotionDescription: _promotionDescription.text,
                promotionTnc: _promotionTnc.text,
                promotionStartDate: convertStringToDate(_startDate.text),
                promotionEndDate: convertStringToDate(_endDate.text),
                showOnStart: _showOnStart.value,
              ),
            ).then((value) {
              dismissLoading();
              if (responseCode(value.code)) {
                if (value.data?.id != null) {
                  showLoading();
                  PromotionController.upload(ctx, value.data!.id!, selectedFiles).then((uploadValue) {
                    dismissLoading();
                    if (responseCode(uploadValue.code)) {
                      filtering();
                      Navigator.of(ctx).pop();
                      showDialogSuccess(context, 'Promotion created successfully!');
                    } else {
                      showDialogError(ctx, uploadValue.message ?? 'Upload failed');
                    }
                  });
                }
              } else {
                showDialogError(ctx, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
              }
            });
          }
        },
      ),
    );
  }

  bool _validateForm(BuildContext ctx) {
    if (_promotionName.text.isEmpty) {
      showDialogError(ctx, ErrorMessage.required(field: 'Name'));
      return false;
    }
    if (_promotionDescription.text.isEmpty) {
      showDialogError(ctx, ErrorMessage.required(field: 'Description'));
      return false;
    }
    if (_startDate.text.isEmpty) {
      showDialogError(ctx, ErrorMessage.required(field: 'promotionPage'.tr(gender: 'startDate')));
      return false;
    }
    if (_endDate.text.isEmpty) {
      showDialogError(ctx, ErrorMessage.required(field: 'promotionPage'.tr(gender: 'endDate')));
      return false;
    }
    return true;
  }

  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce ? _debouncer.run(() => _runFiltering(page: page)) : _runFiltering(page: page);
  }

  void _runFiltering({int? page}) {
    showLoading();
    if (page != null) _page = page;
    PromotionController.getAll(
      context,
      _page,
      _pageSize,
      promotionName: _searchController.text,
      promotionStatus: _statusFilter != null ? int.parse(_statusFilter!) : null,
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        _totalCount = value.data?.totalCount ?? 0;
        _totalPage = value.data?.totalPage ?? ((_totalCount / _pageSize).ceil());
        context.read<PromotionController>().promotionAllResponse = value;
        rebuild.add(DateTime.now());
      }
    });
  }

  double bytesToMB(int bytes) => bytes / 1048576.0;
}

class _PromotionCard extends StatefulWidget {
  final Data promotion;
  final VoidCallback onTap;
  const _PromotionCard({required this.promotion, required this.onTap});

  @override
  State<_PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<_PromotionCard> {
  bool _hovered = false;

  bool get _isActive {
    return widget.promotion.promotionStatus == 1 && checkEndDate(widget.promotion.promotionEndDate);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scaleByDouble(_hovered ? 1.025 : 1.0, _hovered ? 1.025 : 1.0, 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_hovered ? 30 : 12),
                blurRadius: _hovered ? 20 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildImageSection()),
                _buildInfoSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final images = widget.promotion.promotionImage;
    final hasImage = images != null && images.isNotEmpty && images.first.path != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image or placeholder
        hasImage
            ? Image.network(
                '${Environment.imageUrl}${images.first.path}',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _buildPlaceholder(loading: true);
                },
              )
            : _buildPlaceholder(),

        // Gradient overlay at bottom
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.4, 1.0],
                colors: [Colors.transparent, Colors.black.withAlpha(160)],
              ),
            ),
          ),
        ),

        // Status badge — top left
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isActive ? const Color(0xFF059669) : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isActive ? 'Active' : 'Inactive',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // Show on Start badge — top right
        if (widget.promotion.showOnStart == 1)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withAlpha(140), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 11),
                  SizedBox(width: 3),
                  Text(
                    'Featured',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder({bool loading = false}) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: loading
            ? const CircularProgressIndicator(color: primary, strokeWidth: 2)
            : const Icon(Icons.local_offer_outlined, size: 40, color: Color(0xFFD1D5DB)),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final startDate = dateConverter(widget.promotion.promotionStartDate, format: 'dd MMM yyyy');
    final endDate = dateConverter(widget.promotion.promotionEndDate, format: 'dd MMM yyyy');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.promotion.promotionName ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  startDate != null && endDate != null ? '$startDate – $endDate' : endDate ?? '—',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionFormDialog extends StatelessWidget {
  final String title;
  final TextEditingController promotionName;
  final TextEditingController promotionDescription;
  final TextEditingController promotionTnc;
  final TextEditingController startDate;
  final TextEditingController endDate;
  final ValueNotifier<bool> showOnStart;
  final StreamController<DateTime> fileRebuild;
  final List<FileAttribute> selectedFiles;
  final VoidCallback onSave;

  const _PromotionFormDialog({
    required this.title,
    required this.promotionName,
    required this.promotionDescription,
    required this.promotionTnc,
    required this.startDate,
    required this.endDate,
    required this.showOnStart,
    required this.fileRebuild,
    required this.selectedFiles,
    required this.onSave,
  });

  double bytesToMB(int bytes) => bytes / 1048576.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: isMobile ? 24 : 40),
      child: SizedBox(
        width: isMobile ? double.infinity : 820,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildDialogHeader(context),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenPadding),
                child: isMobile ? _buildMobileForm(context) : _buildDesktopForm(context),
              ),
            ),
            // Footer
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _buildDialogFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: primary.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_offer_rounded, color: primary, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title, style: AppTypography.bodyLarge(context)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Cancel', style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280))),
          ),
          const SizedBox(width: 12),
          Button(
            onSave,
            actionText: title == 'New Promotion' ? 'button'.tr(gender: 'create') : 'button'.tr(gender: 'update'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopForm(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildLeftColumn(context)),
        const SizedBox(width: 24),
        Expanded(child: _buildRightColumn(context)),
      ],
    );
  }

  Widget _buildMobileForm(BuildContext context) {
    return Column(
      children: [
        ..._buildLeftColumn(context).children,
        const SizedBox(height: 16),
        ..._buildRightColumn(context).children,
      ],
    );
  }

  Column _buildLeftColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'Promotion Details'),
        const SizedBox(height: 12),
        InputField(
          field: InputFieldAttribute(controller: promotionName, labelText: 'Name'),
        ),
        AppPadding.vertical(denominator: 2),
        TextField(
          maxLines: 4,
          style: Theme.of(context).textTheme.bodyMedium,
          controller: promotionDescription,
          decoration: appInputDecoration(context, 'Description'),
        ),
        AppPadding.vertical(denominator: 2),
        TextField(
          maxLines: 4,
          style: Theme.of(context).textTheme.bodyMedium,
          controller: promotionTnc,
          decoration: appInputDecoration(context, 'Terms & Conditions'),
        ),
      ],
    );
  }

  Column _buildRightColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'Images & Schedule'),
        const SizedBox(height: 12),
        StreamBuilder<DateTime>(
          stream: fileRebuild.stream,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedFiles.length < 3)
                  UploadDocumentsField(
                    title: 'promotionPage'.tr(gender: 'browseFile'),
                    fieldTitle: 'promotionPage'.tr(gender: 'promotionImage'),
                    action: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        PlatformFile file = result.files.first;
                        if (supportedExtensions.contains(file.extension)) {
                          if (bytesToMB(file.size) < 1.0) {
                            selectedFiles.add(FileAttribute(name: file.name, value: result.files.first.bytes));
                            fileRebuild.add(DateTime.now());
                          } else {
                            showDialogError(
                              context,
                              'error'.tr(gender: 'err-21', args: [fileSizeLimit.toStringAsFixed(0)]),
                            );
                          }
                        } else {
                          showDialogError(
                            context,
                            'error'.tr(gender: 'err-22', args: [fileSizeLimit.toStringAsFixed(0)]),
                          );
                        }
                      }
                    },
                    cancelAction: () {},
                  ),
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...List.generate(selectedFiles.length, (index) {
                    return _buildFileItem(context, index);
                  }),
                ],
              ],
            );
          },
        ),
        AppPadding.vertical(),
        GestureDetector(
          onTap: () async {
            final results = await showCalendarDatePicker2Dialog(
              context: context,
              config: CalendarDatePicker2WithActionButtonsConfig(),
              dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
              borderRadius: BorderRadius.circular(15),
            );
            startDate.text = dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
          },
          child: ReadOnly(
            InputField(
              field: InputFieldAttribute(
                controller: startDate,
                isEditable: false,
                labelText: 'promotionPage'.tr(gender: 'startDate'),
                suffixWidget: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF9CA3AF))],
                ),
              ),
            ),
            isEditable: false,
          ),
        ),
        AppPadding.vertical(denominator: 2),
        GestureDetector(
          onTap: () async {
            final results = await showCalendarDatePicker2Dialog(
              context: context,
              config: CalendarDatePicker2WithActionButtonsConfig(firstDate: DateTime.now()),
              dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
              borderRadius: BorderRadius.circular(15),
            );
            endDate.text = dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
          },
          child: ReadOnly(
            InputField(
              field: InputFieldAttribute(
                controller: endDate,
                isEditable: false,
                labelText: 'promotionPage'.tr(gender: 'endDate'),
                suffixWidget: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF9CA3AF))],
                ),
              ),
            ),
            isEditable: false,
          ),
        ),
        AppPadding.vertical(denominator: 2),
        ValueListenableBuilder<bool>(
          valueListenable: showOnStart,
          builder: (context, value, _) {
            return GestureDetector(
              onTap: () => showOnStart.value = !value,
              child: Row(
                children: [
                  CheckBoxWidget((p0) => showOnStart.value = !value, value: value),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('promotionPage'.tr(gender: 'showOnStart'), style: AppTypography.bodyMedium(context)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFileItem(BuildContext context, int index) {
    final file = selectedFiles[index];
    final hasPreview = file.value != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          if (hasPreview)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(file.value!, width: 36, height: 36, fit: BoxFit.cover),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: primary.withAlpha(25), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.image_rounded, size: 18, color: primary),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.name ?? 'Image ${index + 1}',
              style: AppTypography.bodyMedium(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: const Color(0xFFEF4444),
            tooltip: 'Remove',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: () {
              selectedFiles.removeAt(index);
              fileRebuild.add(DateTime.now());
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
    );
  }
}
