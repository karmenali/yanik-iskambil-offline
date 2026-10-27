// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Yanik Rummy';

  @override
  String get homeTitle => 'YANIK RUMMY';

  @override
  String get defaultPlayerName => 'Player';

  @override
  String get homePlayButton => 'PLAY';

  @override
  String get homeAssistedMode => 'Assisted Mode';

  @override
  String get homeUnassistedMode => 'Unassisted Mode';

  @override
  String get homeNewGameDialogTitle => 'Start New Game?';

  @override
  String get homeNewGameDialogContent =>
      'You have an ongoing game. Starting a new game will reset your current progress and scores.';

  @override
  String get homeNewGameDialogCancel => 'Cancel';

  @override
  String get homeNewGameDialogConfirm => 'Start New Game';

  @override
  String get homeTooltipRules => 'Rules';

  @override
  String get homeTooltipSettings => 'Settings';

  @override
  String get settingsTitle => 'Game Settings';

  @override
  String get settingsClose => 'Close';

  @override
  String get settingsLanguageSection => '🌐 DİL SEÇİMİ / LANGUAGE';

  @override
  String get settingsLanguageTr => 'Türkçe';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsGameModeSection => '🎮 GAME MODE';

  @override
  String get settingsAssistedTitle => '✨ Assisted Mode (Recommended)';

  @override
  String get settingsAssistedDesc =>
      'Valid melds (✓) and real-time deadwood penalties are shown automatically.';

  @override
  String get settingsUnassistedTitle => '🔥 Unassisted Expert Mode';

  @override
  String get settingsUnassistedDesc =>
      'No meld or penalty hints. Pure skill and focus. An invalid declaration triggers an instant 101 penalty.';

  @override
  String get settingsSoundSection => '🔊 SOUND & HAPTICS';

  @override
  String get settingsSoundEffects => 'Card & Game Sounds';

  @override
  String get settingsVibration => 'Haptic Vibrations';

  @override
  String get settingsProfileSection => '👤 PLAYER PROFILE';

  @override
  String get settingsPlayerNameLabel => 'Player Name';

  @override
  String get settingsSaveButton => 'SAVE & RETURN';

  @override
  String get rulesTitle => 'How to Play (Rules)';

  @override
  String get rulesClose => 'Close';

  @override
  String get rulesUnderstandButton => 'GOT IT';

  @override
  String get rulesSection1Title => '🃏 1. Deck, Deal & Drawing';

  @override
  String get rulesSection1Body =>
      '• Played with 106 cards: 2 full standard decks (104 cards) + 2 Printed Jokers.\n• Each player is dealt 10 cards.\n• Drawing is ONLY allowed from the closed stock pile. Drawing from the discard pile is not permitted.';

  @override
  String get rulesSection2Title => '👑 2. Jokers (Indicator & Printed Jokers)';

  @override
  String get rulesSection2Body =>
      '• The Indicator card revealed after dealing determines the \"Wild Joker\" rank for the round.\n• All 8 cards of that rank across both decks + 2 Printed Jokers create 10 total jokers.\n• Jokers can represent any missing card in sets and runs.\n• 3 or more Jokers can form an independent valid meld on their own.\n• ATTENTION: Any unmelded Joker left in hand at round end incurs a heavy 25-point penalty!';

  @override
  String get rulesSection3Title => '📐 3. Valid Melds (Sets and Runs)';

  @override
  String get rulesSection3Body =>
      'Cards are grouped into melds of at least 3 cards:\n• Set (Group): At least 3 or 4 cards of the SAME rank in DIFFERENT suits (e.g. ♠K, ♦K, ♣K). Duplicate suits in the same set are invalid.\n• Run (Sequence): At least 3 consecutive cards of the SAME suit (e.g. ♥7, ♥8, ♥9, ♥10).\n• Ace (A): May be used low (A-2-3) or high (J-Q-K-A); round-the-corner sequences (K-A-2) are invalid.';

  @override
  String get rulesSection4Title => '🏆 4. Declaring and Going Out';

  @override
  String get rulesSection4Body =>
      '• On your turn, draw 1 card to hold 11 cards.\n• Arrange your 10 cards into valid melds and discard your 11th card to declare and win the round.\n• The player who declares a valid hand scores 0 PENALTY points.\n• Other players receive penalty points equal to the total value of their unmelded deadwood cards.';

  @override
  String get rulesSection5Title => '💡 5. Example Winning Hand';

  @override
  String get rulesSection5Body =>
      '10 melded cards + 1 discard card:\n• Rack Row 1: [♠8, ♥8, ♦8] (3-Card Set)\n• Rack Row 2: [♣4, ♣5, ♣6, ♣7] (4-Card Run)\n• Rack Row 3: [♥J, ♥Q, ♥K] (3-Card Run)\n• Discard Card: [♦2] (11th leftover card discarded to table)\nResult: 10 cards fully melded, 11th card discarded to finish successfully!';

  @override
  String get rulesSection6Title => '✨ 6. Assisted Mode vs 🔥 Expert Mode';

  @override
  String get rulesSection6Body =>
      '• Assisted Mode: Valid melds are marked with green badges (✓ MELD) and deadwood penalty points are calculated in real time. Winning discard candidates are suggested.\n• Expert Mode: No meld or penalty hints! You must arrange your rack manually.\n• WARNING (False Finish): Declaring an invalid hand in Expert Mode instantly burns you with a 101 PENALTY, while all other players receive 0 penalty!';

  @override
  String get rulesSection7Title => '🔢 7. Penalties and the 101 Threshold';

  @override
  String get rulesSection7Body =>
      'Penalty values for unmelded deadwood cards:\n• Ace (A) = 10 points\n• Face cards (K, Q, J) = 10 points\n• Number cards (2..10) = Face value\n• Joker = 25 points\n• Reaching 101 or more cumulative penalty points ELIMINATES (busts) the player from the table.';

  @override
  String get rulesSection8Title => '🔄 8. Stock Exhaustion (Draw)';

  @override
  String get rulesSection8Body =>
      '• If the 106-card stock pile is exhausted and nobody has declared, the round ends in a draw.\n• All players receive penalty points for their unmelded cards.';

  @override
  String get rulesSection9Title => '🥇 9. Table Champion';

  @override
  String get rulesSection9Body =>
      '• Yanık is a survival game. Opponents are eliminated as they bust past 101 penalty points.\n• The last remaining player standing below 101 points is crowned the TABLE CHAMPION!';

  @override
  String get tableTooltipLeave => 'Leave Table';

  @override
  String get tableTooltipScoresheet => '101 Scoresheet';

  @override
  String get tableTooltipSettings => 'Settings';

  @override
  String tableRoundBadge(int roundNumber) {
    return 'Round $roundNumber';
  }

  @override
  String get tableModeAssisted => 'Assisted';

  @override
  String get tableModeUnassisted => 'Expert';

  @override
  String get tableIndicator => 'INDICATOR';

  @override
  String tableDeckCount(int count) {
    return 'DECK $count';
  }

  @override
  String tableDrawNow(int count) {
    return '👇 DRAW ($count)';
  }

  @override
  String get tableDiscardLabel => 'DISCARD';

  @override
  String get tableDiscardPile => 'DISCARD PILE';

  @override
  String get tableBtnDraw => 'DRAW\nCARD';

  @override
  String get tableBtnAutoMeld => 'AUTO\nSORT';

  @override
  String get tableBtnSortRank => 'SORT BY\nRANK';

  @override
  String get tableBtnDiscard => 'DISCARD\nCARD';

  @override
  String get tableBtnDeclareFinish => 'DECLARE\nFINISH';

  @override
  String get tableRackUnassisted => '🔥 Unassisted';

  @override
  String get tableRackReadyToFinish => '✨ Ready to Finish';

  @override
  String tableRackPenaltyPoints(int points) {
    return 'Penalty: $points Pts';
  }

  @override
  String tableRackSelected(String card) {
    return 'Selected: $card';
  }

  @override
  String get tableCardBadgeFinish => 'FINISH';

  @override
  String get tablePlayerYouSuffix => ' (You)';

  @override
  String get tablePlayerWon => 'WON';

  @override
  String tablePlayerBust(int score) {
    return 'BUST ($score)';
  }

  @override
  String tablePlayerPenalty(int score) {
    return 'Penalty: $score';
  }

  @override
  String get tableLeaveDialogTitle => 'Leave Table?';

  @override
  String get tableLeaveDialogContent =>
      'The current game will end and you will return to the main menu.';

  @override
  String get tableLeaveDialogCancel => 'CANCEL';

  @override
  String get tableLeaveDialogConfirm => 'LEAVE';

  @override
  String get tableFalseFinishDialogTitle => 'Invalid Declaration Warning';

  @override
  String get tableFalseFinishDialogContent =>
      'Declaring an invalid hand incurs a 101 penalty. Do you wish to proceed?';

  @override
  String get tableFalseFinishDialogCancel => 'Cancel';

  @override
  String get tableFalseFinishDialogConfirm => 'Proceed';

  @override
  String get tableNotReadySnackBar => 'Your hand is not ready to finish yet.';

  @override
  String get tableDiscardSheetTitle => 'Select Card to Discard';

  @override
  String get tableDiscardSheetDesc =>
      'Select the card to discard to declare and finish your hand:';

  @override
  String get tableDiscardSheetCancel => 'Cancel';

  @override
  String get tableRecentDiscardsTitle => '🗑️ Recent Discards';

  @override
  String get tableRecentDiscardsEmpty =>
      'No cards have been discarded in this round yet.';

  @override
  String get tableScoresheetTitle => '📝 SCORESHEET (101 PENALTY TABLE)';

  @override
  String tableScoresheetSubtitle(int roundNumber, String mode) {
    return 'Round #$roundNumber • $mode';
  }

  @override
  String get tableScoresheetColRound => 'RND';

  @override
  String get tableScoresheetEmpty =>
      'No rounds completed yet. Penalties will be recorded here after each round.';

  @override
  String tableScoresheetRoundLabel(int roundNumber) {
    return 'Round $roundNumber';
  }

  @override
  String get tableScoresheetDeclared => 'OUT';

  @override
  String get tableScoresheetTotal => 'TOTAL';

  @override
  String get tableScoresheetBust => 'BUST';

  @override
  String get summaryTitleGameOver => '🏆 GAME OVER';

  @override
  String summaryTitleRoundResult(int roundNumber) {
    return '📊 ROUND $roundNumber RESULTS';
  }

  @override
  String get summaryPlayerDeclared => '✨ Declared Hand (0 Penalty)';

  @override
  String get summaryPlayerFalseFinish => '❌ Invalid Declaration (101 Penalty)';

  @override
  String summaryPlayerUnmeldedCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deadwood: $count cards',
      one: 'Deadwood: 1 card',
    );
    return '$_temp0';
  }

  @override
  String summaryPlayerBust(int score) {
    return '🔥 BUST ($score)';
  }

  @override
  String summaryPlayerTotalScore(int score) {
    return 'Total: $score / 101';
  }

  @override
  String summaryMeldBadge(int meldNumber) {
    return 'MELD $meldNumber';
  }

  @override
  String summaryDeadwoodBadge(int count) {
    return 'DEADWOOD ($count)';
  }

  @override
  String get summaryBtnMainMenu => 'MAIN MENU';

  @override
  String get summaryBtnPlayAgain => 'PLAY AGAIN 🏆';

  @override
  String get summaryBtnContinue => 'CONTINUE ➜';

  @override
  String get celebrationTableChampion => 'TABLE CHAMPION';

  @override
  String get celebrationRoundWinner => 'ROUND WINNER';

  @override
  String celebrationBotFinished(String winnerName) {
    return '$winnerName FINISHED';
  }

  @override
  String get celebrationChampionDesc =>
      'Congratulations! You Won the Table Championship!';

  @override
  String get celebrationHumanRoundDesc => 'Brilliant Hand! 0 Penalty Points';

  @override
  String celebrationBotRoundDesc(String winnerName) {
    return '$winnerName Won the Round with 0 Penalty';
  }

  @override
  String get celebrationTapToSkip => 'Tap anywhere to skip';

  @override
  String get gameOverTitleChampion => '🏆 CHAMPION! 🏆';

  @override
  String get gameOverTitleBust => '🔥 GAME OVER';

  @override
  String get championHumanMessage =>
      'Congratulations! You Finished as Table Champion! 🏆';

  @override
  String championBotMessage(String name) {
    return '$name Became the Champion!';
  }
}
