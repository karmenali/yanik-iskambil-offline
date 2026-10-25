import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/engine/offline_table_controller.dart';
import 'package:yanik_offline/screens/offline_table_screen.dart';
import 'package:yanik_offline/services/settings_service.dart';
import 'package:yanik_offline/widgets/playing_card_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    final ctrl = OfflineTableController.instance;
    ctrl.initMatch();
  });

  tearDown(() {
    OfflineTableController.instance.stopGame();
  });

  final testResolutions = [
    const Size(320, 568), // Ultra compact phone (iPhone SE 1st gen / 4-inch Android)
    const Size(360, 640), // Standard Android compact
    const Size(390, 844), // Typical modern smartphone
    const Size(412, 915), // Tall aspect ratio (e.g. Pixel 7 / Galaxy S21)
  ];

  for (final size in testResolutions) {
    testWidgets('OfflineTableScreen renders without overflow on ${size.width.toInt()}x${size.height.toInt()}',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(top: 24, bottom: 16),
            ),
            child: const OfflineTableScreen(),
          ),
        ),
      );

      // Render frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check no Flutter error or overflow caught
      expect(tester.takeException(), isNull,
          reason: 'No overflow or rendering exceptions should occur on ${size.width}x${size.height}');

      // Verify human rack and buttons are present
      expect(find.byType(OfflineTableScreen), findsOneWidget);
    });
  }

  group('Meld separation and layout math tests', () {
    test('findMeldEndIndices identifies boundary between two melds on the same row', () {
      // Row with 2 melds: (Hearts 7,8,9) and (Diamonds 5, Clubs 5, Spades 5)
      final rowCards = [
        const CardModel(id: 'c1', suit: 'H', rank: 7, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c2', suit: 'H', rank: 8, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c3', suit: 'H', rank: 9, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c4', suit: 'D', rank: 5, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c5', suit: 'C', rank: 5, deckIndex: 0, isPhysicalJoker: false),
        const CardModel(id: 'c6', suit: 'S', rank: 5, deckIndex: 0, isPhysicalJoker: false),
      ];

      final gaps = OfflineTableScreen.findMeldEndIndices(rowCards, 0);
      // Index 2 is the end of the first meld (Hearts 9), separating it from the second meld
      expect(gaps.contains(2), isTrue);
    });

    test('calculateCardLefts provides 12-16 dp gap without exceeding usable row width', () {
      final gaps = [2]; // Gap after card index 2
      const double maxW = 360.0;
      const double cardW = 60.0;
      const int count = 6;

      final lefts = OfflineTableScreen.calculateCardLefts(count, maxW, cardW, gaps);
      expect(lefts.length, equals(6));

      // Normal step between card 0 and 1
      final normalStep = lefts[1] - lefts[0];
      // Step between card 2 and 3 (across the meld boundary)
      final meldBoundaryStep = lefts[3] - lefts[2];
      final gapDifference = meldBoundaryStep - normalStep;

      // Gap difference must be within the 12-16 dp requirement (target is 14 dp)
      expect(gapDifference, inInclusiveRange(12.0, 16.0));

      // Rightmost edge of the last card must not exceed maxW
      expect(lefts.last + cardW, lessThanOrEqualTo(maxW));
    });

    test('calculateCardLefts preserves bounds under tight screen constraints', () {
      final gaps = [2, 5];
      const double tightMaxW = 280.0;
      const double cardW = 55.0;
      const int count = 8;

      final lefts = OfflineTableScreen.calculateCardLefts(count, tightMaxW, cardW, gaps);
      expect(lefts.length, equals(8));
      expect(lefts.last + cardW, lessThanOrEqualTo(tightMaxW));
    });
  });

  group('Indicator Area & Joker UI Tests', () {
    testWidgets('GÖSTERGE text is fully rendered and table indicator card has NO JOKER badge',
        (WidgetTester tester) async {
      const size = Size(360, 640);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.4), // Test with 1.4x large accessibility text
            ),
            child: const OfflineTableScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. GÖSTERGE metni tamamen mevcuttur
      expect(find.text('GÖSTERGE'), findsOneWidget);

      // 2. Masadaki gösterge kartında JOKER etiketi bulunmaz (kartın yüzü temizdir)
      final indicatorFinder = find.byWidgetPredicate(
        (widget) => widget is PlayingCardWidget && widget.isIndicator == true,
      );
      expect(indicatorFinder, findsOneWidget);

      final indicatorWidget = tester.widget<PlayingCardWidget>(indicatorFinder);
      expect(indicatorWidget.showWildHints, isFalse);
      expect(indicatorWidget.isIndicator, isTrue);

      // 3. Hiçbir taşma hatası meydana gelmemiştir
      expect(tester.takeException(), isNull);
    });
  });
}
