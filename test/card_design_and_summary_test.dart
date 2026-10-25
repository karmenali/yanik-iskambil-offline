import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanik_offline/engine/card_model.dart';
import 'package:yanik_offline/widgets/playing_card_widget.dart';
import 'package:yanik_offline/widgets/round_summary_dialog.dart';

CardModel _card(String id, String suit, int rank, {bool isPhysicalJoker = false}) {
  return CardModel(
    id: id,
    suit: suit,
    rank: rank,
    deckIndex: 0,
    isPhysicalJoker: isPhysicalJoker,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vector Card Renderer & PlayingCardWidget Tests', () {
    testWidgets('Renders number cards 2..10 across suits without error', (tester) async {
      final suits = ['S', 'H', 'D', 'C'];
      for (final s in suits) {
        for (int r = 2; r <= 10; r++) {
          final card = _card('$s$r', s, r);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PlayingCardWidget(card: card, wildRank: 5),
              ),
            ),
          );
          expect(find.byType(PlayingCardWidget), findsOneWidget);
          expect(find.byType(CustomPaint), findsWidgets);
        }
      }
    });

    testWidgets('Renders Ace of Spades (ornate) and other Aces', (tester) async {
      for (final s in ['S', 'H', 'D', 'C']) {
        final card = _card('${s}1', s, 1);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayingCardWidget(card: card, wildRank: 0),
            ),
          ),
        );
        expect(find.byType(PlayingCardWidget), findsOneWidget);
      }
    });

    testWidgets('Renders Court cards Jack, Queen, King (11, 12, 13) across suits', (tester) async {
      for (final s in ['S', 'H', 'D', 'C']) {
        for (final r in [11, 12, 13]) {
          final card = _card('$s$r', s, r);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PlayingCardWidget(card: card, wildRank: 7),
              ),
            ),
          );
          expect(find.byType(PlayingCardWidget), findsOneWidget);
        }
      }
    });

    testWidgets('Renders Physical Original Joker with jester art', (tester) async {
      final joker = _card('joker_1', 'J', 0, isPhysicalJoker: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayingCardWidget(card: joker, wildRank: 7),
          ),
        ),
      );
      expect(find.byType(PlayingCardWidget), findsOneWidget);
    });

    testWidgets('Fake Joker (indicator wild) displays compact JOKER micro-badge in assisted mode', (tester) async {
      // 7 of Diamonds when wildRank is 7
      final fakeJoker = _card('D7', 'D', 7);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayingCardWidget(
              card: fakeJoker,
              wildRank: 7,
              showWildHints: true,
              width: 62,
              height: 90,
            ),
          ),
        ),
      );

      // In assisted mode, the sleek micro JOKER badge is visible in top right
      expect(find.text('JOKER'), findsOneWidget);
    });

    testWidgets('Indicator reference card on table (isIndicator: true) NEVER displays JOKER badge', (tester) async {
      // Gösterge referans kartı (masadaki gösterge) rank == wildRank olsa bile temiz kalır
      final indicatorCard = _card('D7', 'D', 7);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayingCardWidget(
              card: indicatorCard,
              wildRank: 7,
              showWildHints: true,
              isIndicator: true,
              width: 52,
              height: 74,
            ),
          ),
        ),
      );

      // Gösterge referans kartında JOKER etiketi ASLA yer almaz; kartın kendi yüzü 100% temiz kalır
      expect(find.text('JOKER'), findsNothing);
      expect(find.text('★ JOKER'), findsNothing);
    });

    testWidgets('Fake Joker appears natural (no hint badge) in unassisted mode', (tester) async {
      // 7 of Diamonds when wildRank is 7, unassisted mode
      final fakeJoker = _card('D7', 'D', 7);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayingCardWidget(
              card: fakeJoker,
              wildRank: 7,
              showWildHints: false,
              width: 62,
              height: 90,
            ),
          ),
        ),
      );

      // In unassisted mode, no wild badge should be shown!
      expect(find.text('JOKER'), findsNothing);
      expect(find.text('★ JOKER'), findsNothing);
    });

    testWidgets('Renders cards at summary scale (40x58 dp)', (tester) async {
      final card = _card('H12', 'H', 12);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayingCardWidget(
              card: card,
              wildRank: 4,
              width: 40,
              height: 58,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(PlayingCardWidget));
      expect(size.width, equals(40));
      expect(size.height, equals(58));
    });
  });

  group('Round Summary Dialog Redesign Tests', () {
    List<ShowdownPlayerResult> createMockResults({bool withWinner = false}) {
      return [
        ShowdownPlayerResult(
          userId: 'user_me',
          username: 'Karmen',
          avatar: 'lion',
          seatIndex: 0,
          isFinisher: true,
          isFalseDeclarer: false,
          melds: [
            [
              _card('H7', 'H', 7),
              _card('H8', 'H', 8),
              _card('H9', 'H', 9),
            ],
            [
              _card('S10', 'S', 10),
              _card('S11', 'S', 11),
              _card('S12', 'S', 12),
            ],
            [
              _card('D5', 'D', 5),
              _card('C5', 'C', 5),
              _card('S5', 'S', 5),
            ],
          ],
          unmelded: [],
          roundPenalty: 0,
          previousScore: 15,
          newTotalScore: 15,
          burnedThisRound: false,
        ),
        ShowdownPlayerResult(
          userId: 'bot_1',
          username: 'Ahmet (Bot)',
          avatar: 'bear',
          seatIndex: 1,
          isFinisher: false,
          isFalseDeclarer: false,
          melds: [
            [
              _card('D10', 'D', 10),
              _card('D11', 'D', 11),
              _card('D12', 'D', 12),
            ],
          ],
          unmelded: [
            _card('C2', 'C', 2),
            _card('S3', 'S', 3),
            _card('H13', 'H', 13),
          ],
          roundPenalty: 15,
          previousScore: 30,
          newTotalScore: 45,
          burnedThisRound: false,
        ),
        ShowdownPlayerResult(
          userId: 'bot_2',
          username: 'Mehmet (Bot)',
          avatar: 'eagle',
          seatIndex: 2,
          isFinisher: false,
          isFalseDeclarer: true, // Hatalı bitiş!
          melds: [],
          unmelded: [
            _card('S1', 'S', 1),
            _card('D13', 'D', 13),
          ],
          roundPenalty: 101,
          previousScore: 10,
          newTotalScore: 111,
          burnedThisRound: true,
        ),
        ShowdownPlayerResult(
          userId: 'bot_3',
          username: 'Ayşe (Bot)',
          avatar: 'cat',
          seatIndex: 3,
          isFinisher: false,
          isFalseDeclarer: false,
          melds: [],
          unmelded: [
            _card('H4', 'H', 4),
            _card('C6', 'C', 6),
          ],
          roundPenalty: 10,
          previousScore: 40,
          newTotalScore: 50,
          burnedThisRound: false,
        ),
      ];
    }

    testWidgets('Shows distinct meld capsules and deadwood panel in summary dialog', (tester) async {
      final results = createMockResults();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoundSummaryDialog(
              results: results,
              roundNumber: 2,
              wildRank: 8,
              onContinue: () {},
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('📊 TUR 2 SONUCU'), findsOneWidget);

      // Verify meld capsule tags
      expect(find.text('PER 1'), findsWidgets);
      expect(find.text('PER 2'), findsWidgets);
      expect(find.text('PER 3'), findsWidgets);

      // Verify deadwood tags
      expect(find.text('BOŞTA (3)'), findsOneWidget);
      expect(find.text('BOŞTA (2)'), findsWidgets);

      // Verify human player badge
      expect(find.textContaining('(Sen)'), findsOneWidget);

      // Verify action button
      expect(find.text('DEVAM ET ➜'), findsOneWidget);

      // Verify cards are rendered at 40x58 dp
      final cards = tester.widgetList<PlayingCardWidget>(find.byType(PlayingCardWidget));
      expect(cards, isNotEmpty);
      for (final c in cards) {
        expect(c.width, equals(40.0));
        expect(c.height, equals(58.0));
      }
    });

    testWidgets('Game over mode shows winner banner and calls onMainMenu', (tester) async {
      final results = createMockResults(withWinner: true);
      bool mainMenuClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => RoundSummaryDialog(
                  results: results,
                  roundNumber: 5,
                  wildRank: 3,
                  winnerMessage: '🏆 Karmen Şampiyon Oldu!',
                  onContinue: () {},
                  onMainMenu: () => mainMenuClicked = true,
                ),
              ),
              child: const Text('OPEN'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('🏆 OYUN BİTTİ'), findsOneWidget);
      expect(find.text('🏆 Karmen Şampiyon Oldu!'), findsOneWidget);
      expect(find.text('ANA MENÜ'), findsOneWidget);

      await tester.tap(find.text('ANA MENÜ'));
      await tester.pumpAndSettle();
      expect(mainMenuClicked, isTrue);
    });

    testWidgets('Game over mode calls onPlayAgain', (tester) async {
      final results = createMockResults(withWinner: true);
      bool playAgainClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => RoundSummaryDialog(
                  results: results,
                  roundNumber: 5,
                  wildRank: 3,
                  winnerMessage: '🏆 Karmen Şampiyon Oldu!',
                  onContinue: () {},
                  onPlayAgain: () => playAgainClicked = true,
                ),
              ),
              child: const Text('OPEN'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('TEKRAR OYNA 🏆'), findsOneWidget);

      await tester.tap(find.text('TEKRAR OYNA 🏆'));
      await tester.pumpAndSettle();
      expect(playAgainClicked, isTrue);
    });

    final testScreenSizes = [
      const Size(320, 568), // Ultra compact phone (iPhone SE 1st gen / 4-inch Android)
      const Size(360, 640), // Standard compact
      const Size(390, 844), // Modern standard
      const Size(412, 915), // Tall aspect ratio
    ];

    for (final size in testScreenSizes) {
      testWidgets('Summary dialog renders without overflow on ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final results = createMockResults();

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: Scaffold(
                body: RoundSummaryDialog(
                  results: results,
                  roundNumber: 3,
                  wildRank: 9,
                  onContinue: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Summary dialog handles large text scaler without crashing', (tester) async {
      const size = Size(360, 640);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final results = createMockResults();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: RoundSummaryDialog(
                results: results,
                roundNumber: 4,
                wildRank: 6,
                onContinue: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(RoundSummaryDialog), findsOneWidget);
    });
  });
}
