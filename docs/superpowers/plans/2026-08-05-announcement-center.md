# Announcement Center Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the portal's single-form announcement dialog with a tabbed Announcement Center (3-step wizard with live preview + send-history view), eliminating the null-channel crash.

**Architecture:** `NotificationHomepage` becomes a dialog-local stateful container with a segmented Compose | History control. Compose runs a 3-step wizard (channel → compose → review) built from small focused widgets; step gating (disabled Next/Send buttons) replaces the `_channel!` null-assertion. History fetches the existing `GET admin/notification` endpoint via a new controller method + model. No provider plumbing, no new routes/permissions — entry point (`homepage.dart` bell/menu) is unchanged.

**Tech Stack:** Flutter 3.44.6 (fvm), Dart 3, existing portal widgets (`Button`, `InputField`, `CardContainer`, `AppTypography`), `flutter_screenutil`, `intl`, `flutter_test`.

**Design spec:** `docs/superpowers/specs/2026-08-05-announcement-center-design.md`

---

## File Structure

| File                                                        | Action  | Responsibility                                                                                                 |
| ----------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------- |
| `lib/models/notification/notification_history.dart`         | Create  | `NotificationHistoryResponse` + `NotificationHistoryItem` (parses the API's `notificationDesciption` typo key) |
| `lib/controllers/notification/notification_controller.dart` | Modify  | Add static `fetchHistory(context)` next to existing `send()`                                                   |
| `lib/views/notification/notification_preview.dart`          | Create  | Phone-style notification mockup (shared by steps 2 & 3)                                                        |
| `lib/views/notification/notification_channel_step.dart`     | Create  | Step 1: two selectable channel cards                                                                           |
| `lib/views/notification/notification_compose_step.dart`     | Create  | Step 2: title/content fields, char counters, live preview                                                      |
| `lib/views/notification/notification_review_step.dart`      | Create  | Step 3: summary + preview                                                                                      |
| `lib/views/notification/notification_history_tab.dart`      | Create  | History list with loading/empty/error states (injected fetch for testability)                                  |
| `lib/views/notification/notification_homepage.dart`         | Rewrite | Tabbed container, wizard state, step gating, send flow                                                         |
| `test/notification/notification_history_model_test.dart`    | Create  | Model parse tests                                                                                              |
| `test/notification/notification_preview_test.dart`          | Create  | Preview render tests                                                                                           |
| `test/notification/notification_channel_step_test.dart`     | Create  | Channel selection callback tests                                                                               |
| `test/notification/notification_compose_step_test.dart`     | Create  | Counter + onChanged tests                                                                                      |
| `test/notification/notification_review_step_test.dart`      | Create  | Summary render tests                                                                                           |
| `test/notification/notification_history_tab_test.dart`      | Create  | Empty / items / error+retry tests                                                                              |
| `test/notification/announcement_wizard_test.dart`           | Create  | Wizard step-gating tests                                                                                       |

Run all new tests with: `fvm flutter test test/notification`

> Note: `test/widget_test.dart` is a pre-existing broken counter test (fails before this work started — verified). It is out of scope; do not touch it, and never run the whole `fvm flutter test` suite as a pass gate. `fvm flutter analyze` reports "No issues found!" on the current tree.

---

### Task 1: History model + controller fetch

**Files:**

- Create: `lib/models/notification/notification_history.dart`
- Create: `test/notification/notification_history_model_test.dart`
- Modify: `lib/controllers/notification/notification_controller.dart`

- [ ] **Step 1: Write the failing test**

`test/notification/notification_history_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/models/notification/notification_history.dart';

void main() {
  test('parses history item including the API typo key', () {
    final item = NotificationHistoryItem.fromJson({
      'notificationId': 'abc-123',
      'notificationTitle': 'Maintenance',
      'notificationDesciption': 'Clinic closed today',
      'createdDate': '2026-08-05T12:00:00.000Z',
    });
    expect(item.notificationId, 'abc-123');
    expect(item.title, 'Maintenance');
    expect(item.description, 'Clinic closed today');
    expect(item.createdDate, '2026-08-05T12:00:00.000Z');
  });

  test('parses response with empty data list', () {
    final response = NotificationHistoryResponse.fromJson({'data': <dynamic>[]});
    expect(response.items, isEmpty);
  });

  test('tolerates missing data key', () {
    final response = NotificationHistoryResponse.fromJson({'message': 'ok'});
    expect(response.items, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/notification/notification_history_model_test.dart`
Expected: FAIL — compile error, `notification_history.dart` not found.

- [ ] **Step 3: Implement the model**

Create `lib/models/notification/notification_history.dart`:

```dart
class NotificationHistoryResponse {
  final List<NotificationHistoryItem> items;

  NotificationHistoryResponse({required this.items});

  factory NotificationHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) return NotificationHistoryResponse(items: const []);
    return NotificationHistoryResponse(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(NotificationHistoryItem.fromJson)
          .toList(),
    );
  }
}

class NotificationHistoryItem {
  final String? notificationId;
  final String? title;
  final String? description;
  final String? createdDate;

  NotificationHistoryItem({this.notificationId, this.title, this.description, this.createdDate});

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      notificationId: json['notificationId'] as String?,
      title: json['notificationTitle'] as String?,
      // NOTE: the API aliases notification_description as notificationDesciption (typo, missing "r").
      description: json['notificationDesciption'] as String?,
      createdDate: json['createdDate'] as String?,
    );
  }
}
```

- [ ] **Step 4: Add `fetchHistory` to the controller**

Modify `lib/controllers/notification/notification_controller.dart`:

Add the import at the top:

```dart
import 'package:klinik_aurora_portal/models/notification/notification_history.dart';
```

Add this method after the existing `send` method:

```dart
  static Future<ApiResponse<NotificationHistoryResponse>> fetchHistory(BuildContext context) {
    return ApiController()
        .call(context, method: Method.get, endpoint: 'admin/notification')
        .then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: NotificationHistoryResponse.fromJson(value.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(code: 400, message: e.toString());
      }
    });
  }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `fvm flutter test test/notification/notification_history_model_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/models/notification/notification_history.dart lib/controllers/notification/notification_controller.dart test/notification/notification_history_model_test.dart
git commit -m "feat: add notification history model and fetch controller"
```

---

### Task 2: Phone-style preview widget

**Files:**

- Create: `lib/views/notification/notification_preview.dart`
- Create: `test/notification/notification_preview_test.dart`

- [ ] **Step 1: Write the failing test**

`test/notification/notification_preview_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/notification/notification_preview.dart';

void main() {
  testWidgets('renders title and body', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: NotificationPreview(title: 'Test Title', body: 'Test Body')),
    ));
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Body'), findsOneWidget);
    expect(find.text('Klinik Aurora'), findsOneWidget);
  });

  testWidgets('shows placeholders when empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: NotificationPreview(title: '', body: '')),
    ));
    expect(find.text('Notification title'), findsOneWidget);
    expect(find.text('Notification content preview'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/notification/notification_preview_test.dart`
Expected: FAIL — `notification_preview.dart` not found.

- [ ] **Step 3: Implement the widget**

Create `lib/views/notification/notification_preview.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// Phone-style mockup of the push notification a subscriber will receive.
class NotificationPreview extends StatelessWidget {
  final String title;
  final String body;
  final double width;

  const NotificationPreview({super.key, required this.title, required this.body, this.width = 240});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: tertiaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '9:41',
                  style: AppTypography.bodyMedium(context).apply(color: Colors.white, fontSizeDelta: -6),
                ),
                const Icon(Icons.battery_full, color: Colors.white, size: 12),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: primaryColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Klinik Aurora',
                            style: AppTypography.bodyMedium(context)
                                .apply(fontWeightDelta: 2, fontSizeDelta: -1),
                          ),
                          Text(
                            'now',
                            style: AppTypography.bodyMedium(context)
                                .apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title.isEmpty ? 'Notification title' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body.isEmpty ? 'Notification content preview' : body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium(context)
                            .apply(color: const Color(0xFF6B7280), fontSizeDelta: -1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/notification/notification_preview_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/views/notification/notification_preview.dart test/notification/notification_preview_test.dart
git commit -m "feat: add phone-style notification preview widget"
```

---

### Task 3: Channel step widget

**Files:**

- Create: `lib/views/notification/notification_channel_step.dart`
- Create: `test/notification/notification_channel_step_test.dart`

- [ ] **Step 1: Write the failing test**

`test/notification/notification_channel_step_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/views/notification/notification_channel_step.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';

void main() {
  testWidgets('tapping a channel reports the selected key', (tester) async {
    DropdownAttribute? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationChannelStep(
          channels: notificationChannel,
          selected: null,
          onSelected: (channel) => picked = channel,
        ),
      ),
    ));

    await tester.tap(find.text('All Users'));
    expect(picked?.key, 'general');

    await tester.tap(find.text('Signed In Users'));
    expect(picked?.key, 'authorised-user-announcements');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/notification/notification_channel_step_test.dart`
Expected: FAIL — `notification_channel_step.dart` not found.

- [ ] **Step 3: Implement the widget**

Create `lib/views/notification/notification_channel_step.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class NotificationChannelStep extends StatelessWidget {
  final List<DropdownAttribute> channels;
  final DropdownAttribute? selected;
  final ValueChanged<DropdownAttribute> onSelected;

  const NotificationChannelStep({
    super.key,
    required this.channels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final channel in channels) ...[
          _ChannelCard(
            channel: channel,
            isSelected: selected?.key == channel.key,
            onTap: () => onSelected(channel),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        Text(
          'Subscribers receive this as a push notification on their phone.',
          style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -2),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final DropdownAttribute channel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelCard({required this.channel, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFFAFC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? secondaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: primaryColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                channel.key == 'general' ? Icons.group_rounded : Icons.person_pin_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(channel.name, style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
                  const SizedBox(height: 2),
                  Text(
                    channel.key == 'general'
                        ? 'Everyone who has the app installed'
                        : 'Users who are signed in',
                    style: AppTypography.bodyMedium(context)
                        .apply(color: const Color(0xFF6B7280), fontSizeDelta: -1),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: secondaryColor, size: 22),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/notification/notification_channel_step_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/views/notification/notification_channel_step.dart test/notification/notification_channel_step_test.dart
git commit -m "feat: add announcement channel step widget"
```

---

### Task 4: Compose step widget

**Files:**

- Create: `lib/views/notification/notification_compose_step.dart`
- Create: `test/notification/notification_compose_step_test.dart`

- [ ] **Step 1: Write the failing test**

`test/notification/notification_compose_step_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/notification/notification_compose_step.dart';

void main() {
  testWidgets('typing updates counters and preview via onChanged', (tester) async {
    final title = TextEditingController();
    final content = TextEditingController();
    var changed = 0;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationComposeStep(
              titleController: title,
              contentController: content,
              onChanged: () => changed++,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Test');
    expect(changed, greaterThan(0));
    await tester.pump();
    expect(find.text('4/60'), findsOneWidget);
    expect(find.text('Test'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/notification/notification_compose_step_test.dart`
Expected: FAIL — `notification_compose_step.dart` not found.

- [ ] **Step 3: Implement the widget**

Create `lib/views/notification/notification_compose_step.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/notification/notification_preview.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class NotificationComposeStep extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onChanged;

  const NotificationComposeStep({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final formWidth = isMobile ? constraints.maxWidth : math.max(constraints.maxWidth - 272, 200);
        final preview = NotificationPreview(
          title: titleController.text,
          body: contentController.text,
          width: isMobile ? constraints.maxWidth : 240,
        );
        final form = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
            const SizedBox(height: 8),
            InputField(
              field: InputFieldAttribute(
                controller: titleController,
                hintText: 'e.g. Exciting Updates Coming Soon!',
                isEditableColor: const Color(0xFFEEF3F7),
                maxCharacter: 60,
                onChanged: (_) => onChanged(),
              ),
              width: formWidth,
            ),
            const SizedBox(height: 6),
            Text(
              '${titleController.text.length}/60',
              style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -3),
            ),
            const SizedBox(height: 16),
            Text('Content', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
            const SizedBox(height: 8),
            InputField(
              field: InputFieldAttribute(
                controller: contentController,
                hintText: 'Write your announcement…',
                isEditableColor: const Color(0xFFEEF3F7),
                lineNumber: 3,
                maxCharacter: 200,
                onChanged: (_) => onChanged(),
              ),
              width: formWidth,
            ),
            const SizedBox(height: 6),
            Text(
              '${contentController.text.length}/200',
              style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -3),
            ),
          ],
        );

        return isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [form, const SizedBox(height: 16), preview])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const SizedBox(width: 32),
                  preview,
                ],
              );
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/notification/notification_compose_step_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/views/notification/notification_compose_step.dart test/notification/notification_compose_step_test.dart
git commit -m "feat: add announcement compose step widget"
```

---

### Task 5: Review step widget

**Files:**

- Create: `lib/views/notification/notification_review_step.dart`
- Create: `test/notification/notification_review_step_test.dart`

- [ ] **Step 1: Write the failing test**

`test/notification/notification_review_step_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/notification/notification_review_step.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';

void main() {
  testWidgets('renders channel, title and body summary', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationReviewStep(
              channel: const DropdownAttribute('general', 'All Users'),
              title: 'Maintenance',
              body: 'Clinic closed today',
            ),
          ),
        ),
      ),
    );

    expect(find.text('All Users'), findsOneWidget);
    expect(find.text('Maintenance'), findsWidgets);
    expect(find.text('Clinic closed today'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/notification/notification_review_step_test.dart`
Expected: FAIL — `notification_review_step.dart` not found.

- [ ] **Step 3: Implement the widget**

Create `lib/views/notification/notification_review_step.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/notification/notification_preview.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class NotificationReviewStep extends StatelessWidget {
  final DropdownAttribute channel;
  final String title;
  final String body;

  const NotificationReviewStep({
    super.key,
    required this.channel,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final summaryWidth = isMobile ? constraints.maxWidth : math.max(constraints.maxWidth - 272, 200);
        final preview = NotificationPreview(
          title: title,
          body: body,
          width: isMobile ? constraints.maxWidth : 240,
        );
        final summary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(label: 'Channel', value: channel.name),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Title', value: title),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Content', value: body.isEmpty ? '—' : body, maxLines: 6),
          ],
        );

        return SizedBox(
          width: summaryWidth,
          child: isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [summary, const SizedBox(height: 16), preview])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 32),
                    preview,
                  ],
                ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final int? maxLines;

  const _SummaryRow({required this.label, required this.value, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF), fontWeightDelta: -1),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
            style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 2),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/notification/notification_review_step_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/views/notification/notification_review_step.dart test/notification/notification_review_step_test.dart
git commit -m "feat: add announcement review step widget"
```

---

### Task 6: History tab

**Files:**

- Create: `lib/views/notification/notification_history_tab.dart`
- Create: `test/notification/notification_history_tab_test.dart`

- [ ] **Step 1: Write the failing test**

`test/notification/notification_history_tab_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/models/notification/notification_history.dart';
import 'package:klinik_aurora_portal/views/notification/notification_history_tab.dart';

void main() {
  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationHistoryTab(
          fetch: () async => ApiResponse(code: 200, data: NotificationHistoryResponse(items: const [])),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No announcements sent yet.'), findsOneWidget);
  });

  testWidgets('shows history items', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationHistoryTab(
          fetch: () async => ApiResponse(
            code: 200,
            data: NotificationHistoryResponse(
              items: [
                NotificationHistoryItem(
                  title: 'Maintenance',
                  description: 'Clinic closed today',
                  createdDate: '2026-08-05T12:00:00.000Z',
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('Clinic closed today'), findsOneWidget);
  });

  testWidgets('shows error state and retries', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationHistoryTab(
          fetch: () async {
            calls++;
            if (calls == 1) return ApiResponse(code: 500);
            return ApiResponse(code: 200, data: NotificationHistoryResponse(items: const []));
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load announcements.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No announcements sent yet.'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/notification/notification_history_tab_test.dart`
Expected: FAIL — `notification_history_tab.dart` not found.

- [ ] **Step 3: Implement the widget**

Create `lib/views/notification/notification_history_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/models/notification/notification_history.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// The injected [fetch] returns the backend future; the widget re-fetches on
/// init and on Refresh/Retry. This keeps the tab testable without a network.
class NotificationHistoryTab extends StatefulWidget {
  final Future<ApiResponse<NotificationHistoryResponse>> Function() fetch;

  const NotificationHistoryTab({super.key, required this.fetch});

  @override
  State<NotificationHistoryTab> createState() => _NotificationHistoryTabState();
}

class _NotificationHistoryTabState extends State<NotificationHistoryTab> {
  late Future<ApiResponse<NotificationHistoryResponse>> _future = widget.fetch();

  void _refresh() {
    setState(() {
      _future = widget.fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Previously sent', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, color: secondaryColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<ApiResponse<NotificationHistoryResponse>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: secondaryColor));
              }
              if (snapshot.hasError || !responseCode(snapshot.data?.code)) {
                return _ErrorState(onRetry: _refresh);
              }
              final items = snapshot.data?.data?.items ?? const <NotificationHistoryItem>[];
              if (items.isEmpty) {
                return const Center(child: Text('No announcements sent yet.'));
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title ?? 'Untitled',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(item.createdDate),
                              style: AppTypography.bodyMedium(context)
                                  .apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium(context)
                              .apply(color: const Color(0xFF6B7280), fontSizeDelta: -1),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String? createdDate) {
    if (createdDate == null || createdDate.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(createdDate).toLocal());
    } catch (_) {
      return createdDate;
    }
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFF9CA3AF), size: 40),
          const SizedBox(height: 8),
          Text('Unable to load announcements.', style: AppTypography.bodyMedium(context)),
          const SizedBox(height: 12),
          Button(onRetry, actionText: 'Retry', color: secondaryColor),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/notification/notification_history_tab_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/views/notification/notification_history_tab.dart test/notification/notification_history_tab_test.dart
git commit -m "feat: add announcement history tab"
```

---

### Task 7: Wizard container rewrite (tabs, gating, send flow)

**Files:**

- Modify: `lib/views/notification/notification_homepage.dart` (full rewrite)
- Create: `test/notification/announcement_wizard_test.dart`

- [ ] **Step 1: Write the failing test**

`test/notification/announcement_wizard_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/notification/notification_homepage.dart';

ElevatedButton _nextButton(WidgetTester tester) => tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('Next'), matching: find.byType(ElevatedButton)),
    );

Future<void> _pumpAnnouncementCenter(WidgetTester tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(1728, 829),
      child: const MaterialApp(home: Scaffold(body: NotificationHomepage())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Next is disabled until a channel is selected', (tester) async {
    await _pumpAnnouncementCenter(tester);
    expect(_nextButton(tester).onPressed, isNull);

    await tester.tap(find.text('All Users'));
    await tester.pump();
    expect(_nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('Next at compose step requires a title', (tester) async {
    await _pumpAnnouncementCenter(tester);

    await tester.tap(find.text('All Users'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(_nextButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Hello');
    await tester.pump();
    expect(_nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('switching to History tab shows the history view', (tester) async {
    await _pumpAnnouncementCenter(tester);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Previously sent'), findsOneWidget);
    expect(find.text('No announcements sent yet.'), findsOneWidget);
  });
}
```

> The third test exercises the real `NotificationController.fetchHistory` → `ApiController` path. In `flutter test` the HTTP layer is blocked, so the fetch fails and the tab shows its error state — not the empty state. Adjust the third assertion after running: if the tab shows `Unable to load announcements.` instead, change `find.text('No announcements sent yet.')` to `find.text('Unable to load announcements.')`. (Step 2 below reflects the pre-implementation failure; step 4 documents the final behavior to match.)

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/notification/announcement_wizard_test.dart`
Expected: FAIL — the old single-form dialog has no `Next` button / `All Users` text.

- [ ] **Step 3: Rewrite the container**

Replace the entire contents of `lib/views/notification/notification_homepage.dart` with:

```dart
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/notification/notification_controller.dart';
import 'package:klinik_aurora_portal/views/notification/notification_channel_step.dart';
import 'package:klinik_aurora_portal/views/notification/notification_compose_step.dart';
import 'package:klinik_aurora_portal/views/notification/notification_history_tab.dart';
import 'package:klinik_aurora_portal/views/notification/notification_review_step.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class NotificationHomepage extends StatefulWidget {
  const NotificationHomepage({super.key});

  @override
  State<NotificationHomepage> createState() => _NotificationHomepageState();
}

class _NotificationHomepageState extends State<NotificationHomepage> {
  int _step = 1;
  bool _showHistory = false;
  bool _sending = false;
  DropdownAttribute? _channel;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _titleController.text = 'Exciting Updates Coming Soon!';
      _contentController.text =
          'We will be launching new updates soon. Stay tuned for a better and smoother experience with Klinik Aurora.';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_step == 1) return _channel != null;
    if (_step == 2) return _titleController.text.trim().isNotEmpty;
    return true;
  }

  void _next() {
    setState(() => _step += 1);
  }

  void _resetWizard() {
    setState(() {
      _step = 1;
      _channel = null;
      _titleController.clear();
      _contentController.clear();
    });
  }

  Future<void> _send() async {
    final channel = _channel;
    if (channel == null) return;

    setState(() => _sending = true);
    final confirmed = await showConfirmDialog(
      context,
      'Are you sure you want to send this notification to ${channel.name}? This action cannot be undone.',
    );
    if (!confirmed) {
      if (mounted) setState(() => _sending = false);
      return;
    }

    final value = await NotificationController.send(
      context,
      topic: channel.key,
      title: _titleController.text.trim(),
      body: _contentController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (responseCode(value.code)) {
      showDialogSuccess(
        context,
        'Notification successfully sent to ${channel.name}. They should receive it within a few minutes.',
      );
      _resetWizard();
    } else {
      final message = value.message ?? '';
      showDialogError(
        context,
        message.isNotEmpty && message != 'An Error Occurred.'
            ? message
            : 'Unable to send the notification at the moment. Please try again later. If the issue persists, contact the app developer.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogWidth = math.min(760.0, MediaQuery.of(context).size.width * 0.92);
    final minDialogWidth = math.min(560.0, maxDialogWidth);

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          minWidth: minDialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: CardContainer(
          Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Announcement Center', style: AppTypography.displayMedium(context)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF637381),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SegmentedControl(
                  selected: _showHistory ? 1 : 0,
                  onChanged: (index) => setState(() => _showHistory = index == 1),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _showHistory
                      ? NotificationHistoryTab(fetch: () => NotificationController.fetchHistory(context))
                      : _buildWizard(context),
                ),
                if (!_showHistory) ...[
                  const SizedBox(height: 16),
                  _buildFooter(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWizard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: _step),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_step) {
                1 => NotificationChannelStep(
                    key: const ValueKey('step-1'),
                    channels: notificationChannel,
                    selected: _channel,
                    onSelected: (channel) => setState(() => _channel = channel),
                  ),
                2 => NotificationComposeStep(
                    key: const ValueKey('step-2'),
                    titleController: _titleController,
                    contentController: _contentController,
                    onChanged: () => setState(() {}),
                  ),
                _ => NotificationReviewStep(
                    key: const ValueKey('step-3'),
                    channel: _channel ?? notificationChannel.first,
                    title: _titleController.text,
                    body: _contentController.text,
                  ),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step > 1)
          TextButton(
            onPressed: _sending ? null : () => setState(() => _step -= 1),
            child: const Text('Back'),
          )
        else
          const SizedBox.shrink(),
        if (_step < 3)
          Button(
            _canProceed && !_sending ? _next : null,
            actionText: 'Next',
            color: secondaryColor,
          )
        else
          Button(
            _sending ? null : _send,
            actionText: _sending ? 'Sending…' : 'Send Announcement',
            color: secondaryColor,
          ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;

  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const steps = ['Channel', 'Compose', 'Review'];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 8),
            Container(width: 24, height: 1, color: const Color(0xFFE5E7EB)),
            const SizedBox(width: 8),
          ],
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i + 1 <= current ? secondaryColor : const Color(0xFFE5E7EB),
                ),
                alignment: Alignment.center,
                child: i + 1 < current
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        '${i + 1}',
                        style: AppTypography.bodyMedium(context).apply(
                          color: i + 1 <= current ? Colors.white : const Color(0xFF9CA3AF),
                          fontSizeDelta: -3,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[i],
                style: AppTypography.bodyMedium(context).apply(
                  color: i + 1 <= current ? textPrimaryColor : const Color(0xFF9CA3AF),
                  fontWeightDelta: i + 1 == current ? 3 : 0,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(label: 'Compose', isSelected: selected == 0, onTap: () => onChanged(0)),
          const SizedBox(width: 4),
          _Segment(label: 'History', isSelected: selected == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Segment({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium(context).apply(
            color: isSelected ? textPrimaryColor : const Color(0xFF637381),
            fontWeightDelta: isSelected ? 3 : 0,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests and fix the History assertion to match reality**

Run: `fvm flutter test test/notification/announcement_wizard_test.dart`
Expected: first two tests PASS. The third test either passes or shows the error state (blocked HTTP in tests). If it shows `Unable to load announcements.`, update the third test's final assertion to `find.text('Unable to load announcements.')` and re-run until green. Do not delete the test — it documents that History degrades to an inline error state without a network.

- [ ] **Step 5: Run the full notification suite**

Run: `fvm flutter test test/notification`
Expected: ALL PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/views/notification/notification_homepage.dart test/notification/announcement_wizard_test.dart
git commit -m "feat: rebuild announcement center as tabbed wizard"
```

---

### Task 8: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Analyze**

Run: `fvm flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Run the notification tests once more**

Run: `fvm flutter test test/notification`
Expected: ALL PASS.

- [ ] **Step 3: Manual QA checklist (staging)**

1. Open Announcement Center from the top-bar bell and from the Announcement menu item.
2. Step 1: Next is greyed until a channel card is selected; tap each card and confirm the check highlight.
3. Step 2: type a title — counter `n/60` updates, phone preview updates live, Next enables only when title is non-empty; content counter `n/200` caps at 200.
4. Step 3: review shows channel/title/content; Back returns to step 2 preserving text.
5. Send to "All Users" — confirm dialog, then success dialog; wizard resets to step 1 with cleared fields.
6. Send with no title (should be impossible — gating) and confirm no null-crash occurs on any path.
7. History tab: lists previously sent announcements newest-first, empty state when none, error state + Retry when offline.
8. Mobile-width window: preview stacks below the form; dialog scrolls without overflow.

- [ ] **Step 4: Commit any QA fixups**

If QA found issues, fix them, re-run steps 1-2, then commit:

```bash
git add -A lib/views/notification test/notification
git commit -m "fix: announcement center QA fixes"
```
