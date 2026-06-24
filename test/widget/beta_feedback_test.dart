import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/ui/beta_feedback_sheet.dart';

void main() {
  testWidgets('beta feedback sheet submits rating + comment (P4-7)', (
    tester,
  ) async {
    int? gotRating;
    String? gotComment;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BetaFeedbackSheet(
            onSubmit: (rating, comment) {
              gotRating = rating;
              gotComment = comment;
            },
          ),
        ),
      ),
    );

    // Submit is disabled until a rating is chosen.
    final submit = find.byKey(const Key('beta-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.byKey(const Key('beta-star-4')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('beta-comment')),
      '  love the cozy vibe  ',
    );
    await tester.tap(submit);
    await tester.pump();

    expect(gotRating, 4);
    expect(gotComment, 'love the cozy vibe'); // trimmed
  });

  testWidgets('an empty comment submits as null', (tester) async {
    int? gotRating;
    String? gotComment = 'sentinel';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BetaFeedbackSheet(
            onSubmit: (rating, comment) {
              gotRating = rating;
              gotComment = comment;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('beta-star-5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('beta-submit')));
    await tester.pump();
    expect(gotRating, 5);
    expect(gotComment, isNull);
  });
}
