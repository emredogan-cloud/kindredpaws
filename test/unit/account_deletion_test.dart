import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/result.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/services/backend_service.dart';

/// A LocalSaveStore whose [delete] throws — to prove deleteAccount surfaces the
/// failure as an [Err] instead of swallowing it.
class _ThrowingStore implements LocalSaveStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String json) async {}
  @override
  Future<void> delete() async => throw StateError('disk gone');
  @override
  Future<void> writeBackup(String blob) async {}
  @override
  Future<String?> readBackup() async => null;
}

void main() {
  const collection = 'saves';
  const petId = 'pet-123';

  group('SaveRepository.deleteAccount (right-to-be-forgotten, §8.3)', () {
    test(
      'wipes the local save, resets analytics id, deletes the cloud doc',
      () async {
        final store = InMemoryLocalSaveStore();
        final backend = InMemoryBackendService();
        await store.write('{"some":"save"}');
        await backend.writeDocument(collection, petId, {'some': 'save'});
        var resets = 0;

        final repo = SaveRepository(
          local: store,
          backend: backend,
          onIdentityReset: () async => resets++,
        );

        final result = await repo.deleteAccount(petId: petId);

        expect(result, isA<Ok<void>>());
        expect(await store.read(), isNull, reason: 'local save wiped');
        expect(resets, 1, reason: 'analytics identifiers reset');
        expect(
          await backend.readDocument(collection, petId),
          isNull,
          reason: 'cloud save deleted (triggers server-side cascade)',
        );
      },
    );

    test('works with no backend and no petId (guest, no cloud save)', () async {
      final store = InMemoryLocalSaveStore();
      await store.write('{"some":"save"}');
      var resets = 0;

      final repo = SaveRepository(
        local: store,
        onIdentityReset: () async => resets++,
      );

      final result = await repo.deleteAccount();

      expect(result, isA<Ok<void>>());
      expect(await store.read(), isNull);
      expect(resets, 1);
    });

    test('without a petId, the cloud doc is left untouched', () async {
      final store = InMemoryLocalSaveStore();
      final backend = InMemoryBackendService();
      await backend.writeDocument(collection, petId, {'some': 'save'});

      final repo = SaveRepository(local: store, backend: backend);
      await repo.deleteAccount(); // no petId ⇒ no cloud delete

      expect(await backend.readDocument(collection, petId), isNotNull);
    });

    test('is resilient when there is nothing to delete', () async {
      final repo = SaveRepository(local: InMemoryLocalSaveStore());
      final result = await repo.deleteAccount(petId: petId);
      expect(result, isA<Ok<void>>());
    });

    test('surfaces a failure as Err (does not swallow it)', () async {
      final repo = SaveRepository(local: _ThrowingStore());
      final result = await repo.deleteAccount();
      expect(result, isA<Err<void>>());
    });
  });

  group('InMemoryBackendService.deleteDocument', () {
    test('removes the doc; deleting a missing doc is a no-op', () async {
      final backend = InMemoryBackendService();
      await backend.writeDocument(collection, petId, {'a': 1});
      await backend.deleteDocument(collection, petId);
      expect(await backend.readDocument(collection, petId), isNull);
      // No throw on a missing collection/key.
      await backend.deleteDocument('nope', 'nope');
    });
  });
}
