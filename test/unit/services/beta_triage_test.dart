import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/beta_triage.dart';
import 'package:kindredpaws/services/sentiment.dart';

void main() {
  group('triageFeedback — worst-first routing', () {
    test(
      'a crashed session is always P1 crashReport (rating cannot override)',
      () {
        final t = triageFeedback(
          rating: 5,
          sentiment: Sentiment.positive,
          hadCrash: true,
          hasComment: true,
        );
        expect(t.category, TriageCategory.crashReport);
        expect(t.severity, TriageSeverity.p1);
      },
    );

    test('low stars ⇒ P2 detractor', () {
      final t = triageFeedback(
        rating: 1,
        sentiment: Sentiment.neutral,
        hadCrash: false,
        hasComment: false,
      );
      expect(t.category, TriageCategory.detractor);
      expect(t.severity, TriageSeverity.p2);
    });

    test('negative sentiment ⇒ P2 detractor even at a middling rating', () {
      final t = triageFeedback(
        rating: 3,
        sentiment: Sentiment.negative,
        hadCrash: false,
        hasComment: true,
      );
      expect(t.category, TriageCategory.detractor);
      expect(t.severity, TriageSeverity.p2);
    });

    test('mixed sentiment at a fine rating ⇒ a lower-severity detractor', () {
      final t = triageFeedback(
        rating: 4,
        sentiment: Sentiment.mixed,
        hadCrash: false,
        hasComment: true,
      );
      expect(t.category, TriageCategory.detractor);
      expect(t.severity, TriageSeverity.p3);
    });

    test('happy feedback ⇒ praise', () {
      final t = triageFeedback(
        rating: 5,
        sentiment: Sentiment.positive,
        hadCrash: false,
        hasComment: false,
      );
      expect(t.category, TriageCategory.praise);
    });

    test('a neutral player with a note ⇒ suggestion', () {
      final t = triageFeedback(
        rating: 3,
        sentiment: Sentiment.neutral,
        hadCrash: false,
        hasComment: true,
      );
      expect(t.category, TriageCategory.suggestion);
    });

    test('a neutral player with no note ⇒ neutral', () {
      final t = triageFeedback(
        rating: 3,
        sentiment: Sentiment.neutral,
        hadCrash: false,
        hasComment: false,
      );
      expect(t.category, TriageCategory.neutral);
    });
  });
}
