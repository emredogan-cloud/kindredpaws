import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/sentiment.dart';

void main() {
  group('tagSentiment — rating as the prior', () {
    test('no comment ⇒ the stars decide', () {
      expect(tagSentiment(null, rating: 5), Sentiment.positive);
      expect(tagSentiment('', rating: 4), Sentiment.positive);
      expect(tagSentiment('   ', rating: 3), Sentiment.neutral);
      expect(tagSentiment(null, rating: 2), Sentiment.negative);
      expect(tagSentiment(null, rating: 1), Sentiment.negative);
    });
  });

  group('tagSentiment — lexicon lean', () {
    test('positive words ⇒ positive (even if the rating is middling)', () {
      expect(
        tagSentiment('I absolutely love this cozy little game', rating: 3),
        Sentiment.positive,
      );
    });

    test('negative words ⇒ negative (even at a generous rating)', () {
      expect(
        tagSentiment('it keeps crashing and feels so buggy', rating: 4),
        Sentiment.negative,
      );
    });

    test('both polarities present ⇒ mixed', () {
      expect(
        tagSentiment('so cute but it crashes constantly', rating: 3),
        Sentiment.mixed,
      );
    });

    test('churn-signal words (repetition / guilt) read negative', () {
      expect(
        tagSentiment('the dialogue is repetitive', rating: 3),
        Sentiment.negative,
      );
      expect(
        tagSentiment('it made me feel guilty for leaving', rating: 3),
        Sentiment.negative,
      );
    });

    test('no signal words ⇒ falls back to the rating', () {
      expect(
        tagSentiment('the thing with the stuff', rating: 5),
        Sentiment.positive,
      );
      expect(
        tagSentiment('played it on the bus', rating: 1),
        Sentiment.negative,
      );
    });

    test('matching is case-insensitive + punctuation-tolerant', () {
      expect(tagSentiment('LOVE it!!!', rating: 3), Sentiment.positive);
    });
  });
}
