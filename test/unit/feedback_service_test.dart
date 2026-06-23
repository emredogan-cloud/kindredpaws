import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/backend_service.dart';
import 'package:kindredpaws/services/feedback_service.dart';

/// A backend whose append always throws — proves submit() swallows it.
class _ThrowingBackend extends InMemoryBackendService {
  @override
  Future<void> append(String stream, Map<String, dynamic> entry) async =>
      throw StateError('offline');
}

void main() {
  group('BetaFeedback normalization (PII-minimized by construction)', () {
    test('rating is clamped to 1–5', () {
      expect(BetaFeedback(rating: 9).rating, 5);
      expect(BetaFeedback(rating: 0).rating, 1);
      expect(BetaFeedback(rating: 3).rating, 3);
    });

    test('comment is trimmed, blank ⇒ null, and length-capped', () {
      expect(BetaFeedback(rating: 5, comment: '  ').comment, isNull);
      expect(BetaFeedback(rating: 5).comment, isNull);
      expect(BetaFeedback(rating: 5, comment: '  love it ').comment, 'love it');
      final long = 'x' * 500;
      expect(
        BetaFeedback(rating: 5, comment: long).comment!.length,
        BetaFeedback.maxCommentLength,
      );
    });

    test('toJson carries only rating + (present) comment — no identifiers', () {
      expect(BetaFeedback(rating: 4).toJson(), {'rating': 4});
      expect(BetaFeedback(rating: 4, comment: 'nice').toJson(), {
        'rating': 4,
        'comment': 'nice',
      });
    });
  });

  group('FeedbackService implementations', () {
    test('Noop accepts feedback and does nothing', () async {
      await const NoopFeedbackService().submit(BetaFeedback(rating: 5));
    });

    test('Backend appends to the beta_feedback stream', () async {
      final backend = InMemoryBackendService();
      final svc = BackendFeedbackService(backend);
      await svc.submit(BetaFeedback(rating: 4, comment: 'good'));

      final entries = backend.entriesOf(BackendFeedbackService.stream);
      expect(entries, hasLength(1));
      expect(entries.single['rating'], 4);
      expect(entries.single['comment'], 'good');
    });

    test('Backend submit swallows a backend error (best-effort)', () async {
      final svc = BackendFeedbackService(_ThrowingBackend());
      await svc.submit(BetaFeedback(rating: 1)); // must not throw
    });
  });
}
