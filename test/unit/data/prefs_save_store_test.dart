import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/prefs_save_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The production LocalSaveStore (used by main()). Covers the right-to-be-
  // forgotten on-device erase path (P3-8 audit: previously only the in-memory
  // store was tested).
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('write → read round-trips the save blob', () async {
    final store = PrefsSaveStore();
    expect(await store.read(), isNull);
    await store.write('{"pet":"Biscuit"}');
    expect(await store.read(), '{"pet":"Biscuit"}');
  });

  test('delete() erases the stored save (right-to-be-forgotten)', () async {
    final store = PrefsSaveStore();
    await store.write('{"pet":"Biscuit"}');
    await store.delete();
    expect(await store.read(), isNull);
  });

  test('delete() on an empty store is a no-op', () async {
    final store = PrefsSaveStore();
    await store.delete();
    expect(await store.read(), isNull);
  });

  test('uses an isolated prefs entry name', () async {
    SharedPreferences.setMockInitialValues({'unrelated': 'x'});
    final store = PrefsSaveStore();
    await store.write('blob');
    await store.delete(); // must only touch its own key
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('unrelated'), 'x');
  });
}
