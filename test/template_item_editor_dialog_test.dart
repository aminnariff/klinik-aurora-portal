import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/widgets/template_item_editor_dialog.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('TemplateItemEditorDialog', () {
    testWidgets('renders all fields and default state in create mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          TemplateItemEditorDialog(
            categoryKey: 'baju',
            onSave: (data) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tambah Item Templat'), findsOneWidget);
      expect(find.text('Tetapkan spesifikasi barangan dan panduan Dr. Aurora'), findsOneWidget);
      expect(find.text('Maklumat Item & Kategori'), findsOneWidget);
      expect(find.text('Nama Barangan *'), findsOneWidget);
      expect(find.text('Cadangan Kuantiti'), findsOneWidget);
      expect(find.text('Item WAJIB'), findsOneWidget);
      expect(find.text('Keperluan asas yang disyorkan'), findsOneWidget);
      expect(find.text('Beg Hospital'), findsOneWidget);
      expect(find.text('Perlu dibawa semasa bersalin'), findsOneWidget);
      expect(find.text('💖 Panduan Klinikal Dr. Aurora'), findsOneWidget);
      expect(find.text('Spesifikasi (Pilihan Fabrik & Saiz)'), findsOneWidget);
      expect(find.text('Keselamatan (Nasihat Pediatrik)'), findsOneWidget);
      expect(find.text('Tip Penjimatan (Smart Budgeting)'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Tambah Item'), findsOneWidget);
    });

    testWidgets('toggles Item WAJIB and Beg Hospital cards', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Map<String, dynamic>? savedData;

      await tester.pumpWidget(
        buildTestWidget(
          TemplateItemEditorDialog(
            categoryKey: 'baju',
            onSave: (data) async {
              savedData = data;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap WAJIB card to turn it off (defaults to true)
      await tester.tap(find.text('Item WAJIB'));
      await tester.pumpAndSettle();

      // Tap Beg Hospital card to turn it on (defaults to false for baju)
      await tester.tap(find.text('Beg Hospital'));
      await tester.pumpAndSettle();

      // Enter title to make form valid
      final titleField = find.widgetWithText(TextFormField, 'Nama Barangan *');
      await tester.enterText(titleField, 'Kain Bedung');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Tambah Item'));
      await tester.pumpAndSettle();

      expect(savedData, isNotNull);
      expect(savedData!['isWajib'], false);
      expect(savedData!['isHospitalBag'], true);
      expect(savedData!['title'], 'Kain Bedung');
    });

    testWidgets('shows validation error when title is empty', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool onSaveCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          TemplateItemEditorDialog(
            onSave: (data) async {
              onSaveCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah Item'));
      await tester.pumpAndSettle();

      expect(find.text('Sila masukkan nama barangan'), findsOneWidget);
      expect(onSaveCalled, isFalse);
    });

    testWidgets('submits all fields correctly in create mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Map<String, dynamic>? savedData;

      await tester.pumpWidget(
        buildTestWidget(
          TemplateItemEditorDialog(
            categoryKey: 'mandi',
            onSave: (data) async {
              savedData = data;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Nama Barangan *'), 'Besen Mandi Bayi');
      await tester.enterText(find.widgetWithText(TextFormField, 'Cadangan Kuantiti'), '1 unit');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Spesifikasi (Pilihan Fabrik & Saiz)'),
        'Ergonomik dengan penyokong leher',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Keselamatan (Nasihat Pediatrik)'),
        'Permukaan tidak licin elak tergelincir',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tip Penjimatan (Smart Budgeting)'),
        'Beli jenis boleh lipat untuk jimat ruang',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah Item'));
      await tester.pumpAndSettle();

      expect(savedData, isNotNull);
      expect(savedData!['title'], 'Besen Mandi Bayi');
      expect(savedData!['quantity'], '1 unit');
      expect(savedData!['categoryKey'], 'mandi');
      expect(savedData!['isWajib'], true);
      expect(savedData!['isHospitalBag'], false);
      expect(savedData!['specs'], 'Ergonomik dengan penyokong leher');
      expect(savedData!['safety'], 'Permukaan tidak licin elak tergelincir');
      expect(savedData!['savingTip'], 'Beli jenis boleh lipat untuk jimat ruang');
    });

    testWidgets('populates fields in edit mode and submits updated data', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Map<String, dynamic>? savedData;

      final existingItem = {
        'templateId': 'tmpl_123',
        'title': 'Baju Lengan Pendek',
        'quantity': '4 helai',
        'categoryKey': 'baju',
        'isWajib': true,
        'isHospitalBag': false,
        'drAuroraAdvice': {
          'specs': 'Kain kapas organik',
          'safety': 'Butang tekan depan',
          'savingTip': 'Beli pek combo 3-in-1',
        },
      };

      await tester.pumpWidget(
        buildTestWidget(
          TemplateItemEditorDialog(
            item: existingItem,
            onSave: (data) async {
              savedData = data;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kemaskini Item Templat'), findsOneWidget);
      expect(find.text('Kemaskini'), findsOneWidget);
      expect(find.text('Baju Lengan Pendek'), findsOneWidget);
      expect(find.text('4 helai'), findsOneWidget);
      expect(find.text('Kain kapas organik'), findsOneWidget);

      // Modify quantity
      await tester.enterText(find.widgetWithText(TextFormField, 'Cadangan Kuantiti'), '6 helai');
      // Toggle Beg Hospital
      await tester.tap(find.text('Beg Hospital'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kemaskini'));
      await tester.pumpAndSettle();

      expect(savedData, isNotNull);
      expect(savedData!['title'], 'Baju Lengan Pendek');
      expect(savedData!['quantity'], '6 helai');
      expect(savedData!['isHospitalBag'], true);
      expect(savedData!['isWajib'], true);
      expect(savedData!['specs'], 'Kain kapas organik');
    });

    testWidgets('TemplateItemEditorDialog.show opens the dialog', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    TemplateItemEditorDialog.show(
                      context,
                      categoryKey: 'penyusuan',
                      onSave: (data) async {},
                    );
                  },
                  child: const Text('Buka Dialog'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Item Templat'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Item Templat'), findsNothing);
    });

    testWidgets('renders cleanly on narrow mobile screen without overflows', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          TemplateItemEditorDialog(
            categoryKey: 'baju',
            onSave: (data) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tambah Item Templat'), findsOneWidget);
      expect(find.text('💖 Panduan Klinikal Dr. Aurora'), findsOneWidget);
    });
  });
}
