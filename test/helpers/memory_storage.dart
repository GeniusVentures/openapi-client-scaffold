import 'package:hydrated_bloc/hydrated_bloc.dart';

/// In-memory [Storage] for widget tests.
///
/// Hive-backed [HydratedStorage] performs real file I/O whose async writes do
/// not cooperate with `flutter_test`'s fake-async clock — a `hydrate()` write
/// from one test leaks a pending future that deadlocks subsequent tests in the
/// same file. This synchronous in-memory implementation avoids that entirely,
/// so the generated composites' hydrated cubits can be constructed safely under
/// `flutter_test`.
class MemoryStorage implements Storage {
  final Map<String, dynamic> _box = <String, dynamic>{};

  @override
  dynamic read(String key) => _box[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _box[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _box.remove(key);
  }

  @override
  Future<void> clear() async {
    _box.clear();
  }

  @override
  Future<void> close() async {}
}
