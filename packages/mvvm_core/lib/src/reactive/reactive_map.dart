import 'dart:collection';

import 'package:mvvm_core/src/reactive/reactive_property.dart';

/// A reactive map that automatically notifies listeners when modified.
///
/// [ReactiveMap] wraps a standard Dart [Map] and implements the full [Map]
/// interface, while automatically notifying listeners of any changes. This
/// makes it ideal for managing key-value data in your ViewModels.
///
/// ## Basic Usage
///
/// ```dart
/// class SettingsViewModel extends ViewModel {
///   final settings = ReactiveMap<String, dynamic>({
///     'theme': 'dark',
///     'fontSize': 14,
///     'notifications': true,
///   });
///
///   void updateTheme(String theme) {
///     settings['theme'] = theme;
///   }
///
///   void toggleNotifications() {
///     settings['notifications'] = !settings['notifications'];
///   }
/// }
///
/// // In the view:
/// vm.settings.listen(
///   builder: (context, settings, _) => Column(
///     children: [
///       Text('Theme: ${settings['theme']}'),
///       Switch(
///         value: settings['notifications'],
///         onChanged: (_) => vm.toggleNotifications(),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ## Creating ReactiveMap
///
/// ```dart
/// // Empty map
/// final map = ReactiveMap<String, int>();
///
/// // With initial values
/// final settings = ReactiveMap<String, dynamic>({
///   'key1': 'value1',
///   'key2': 42,
/// });
///
/// // From existing map
/// final copy = ReactiveMap<String, String>(existingMap);
/// ```
///
/// ## Standard Map Operations
///
/// All standard map operations work and trigger notifications:
///
/// ```dart
/// final map = ReactiveMap<String, int>();
///
/// // Add/update entries
/// map['key'] = 100;
/// map.addAll({'a': 1, 'b': 2});
/// map.putIfAbsent('c', () => 3);
///
/// // Access operations
/// print(map['key']);        // 100
/// print(map.length);        // 4
/// print(map.containsKey('a')); // true
///
/// // Update operations
/// map.update('key', (v) => v + 1);
/// map.updateAll((k, v) => v * 2);
///
/// // Remove operations
/// map.remove('key');
/// map.removeWhere((k, v) => v < 5);
/// map.clear();
/// ```
///
/// ## Batch Operations
///
/// Use [batch] to perform multiple operations with a single notification:
///
/// ```dart
/// // Without batch: triggers 3 notifications
/// settings['theme'] = 'light';
/// settings['fontSize'] = 16;
/// settings['language'] = 'en';
///
/// // With batch: triggers 1 notification
/// settings.batch((map) {
///   map['theme'] = 'light';
///   map['fontSize'] = 16;
///   map['language'] = 'en';
/// });
/// ```
///
/// ## Silent Updates
///
/// Use [silent] to update without notifications, then call [refresh]:
///
/// ```dart
/// // Prepare multiple changes
/// settings.silent((map) {
///   map['theme'] = computeTheme();
///   map['colors'] = computeColors();
///   map.remove('deprecatedKey');
/// });
///
/// // Single notification when ready
/// settings.refresh();
/// ```
///
/// ## Replace All Entries
///
/// Use [replaceAll] to efficiently replace all entries:
///
/// ```dart
/// // Clear and add in one operation
/// settings.replaceAll({
///   'theme': 'system',
///   'fontSize': 14,
///   'language': 'en',
/// });
/// ```
///
/// ## Immutable Access
///
/// The [value] getter returns an unmodifiable view:
///
/// ```dart
/// Map<String, int> snapshot = map.value;
/// snapshot['key'] = 1; // Throws error - can't modify
/// ```
///
/// ## Common Use Cases
///
/// ### User Preferences
/// ```dart
/// class PreferencesViewModel extends ViewModel {
///   final prefs = ReactiveMap<String, dynamic>();
///
///   Future<void> load() async {
///     final data = await storage.loadPreferences();
///     prefs.replaceAll(data);
///   }
///
///   void set(String key, dynamic value) {
///     prefs[key] = value;
///     storage.save(prefs.value);
///   }
/// }
/// ```
///
/// ### Form Data
/// ```dart
/// class FormViewModel extends ViewModel {
///   final formData = ReactiveMap<String, String>();
///   final errors = ReactiveMap<String, String>();
///
///   void updateField(String field, String value) {
///     formData[field] = value;
///     validateField(field);
///   }
///
///   void validateField(String field) {
///     final error = validator.validate(field, formData[field]);
///     if (error != null) {
///       errors[field] = error;
///     } else {
///       errors.remove(field);
///     }
///   }
/// }
/// ```
///
/// ### Cache Management
/// ```dart
/// class CacheViewModel extends ViewModel {
///   final cache = ReactiveMap<String, CachedItem>();
///
///   T? get<T>(String key) => cache[key]?.value as T?;
///
///   void set<T>(String key, T value, {Duration? ttl}) {
///     cache[key] = CachedItem(value, ttl);
///   }
///
///   void invalidate(String key) => cache.remove(key);
///
///   void clearExpired() {
///     cache.removeWhere((_, item) => item.isExpired);
///   }
/// }
/// ```
///
/// ## Performance Optimization
///
/// Listen to specific values to avoid unnecessary rebuilds:
///
/// ```dart
/// // Only rebuild when theme changes
/// vm.settings.select(
///   selector: (map) => map['theme'],
///   builder: (context, theme) => ThemeDisplay(theme: theme),
/// )
///
/// // Only rebuild when map size changes
/// vm.items.select(
///   selector: (map) => map.length,
///   builder: (context, count) => Text('$count items'),
/// )
/// ```
///
/// ## Iterating Over Entries
///
/// ```dart
/// // Using forEach
/// settings.forEach((key, value) {
///   print('$key: $value');
/// });
///
/// // Using entries
/// for (final entry in settings.entries) {
///   print('${entry.key}: ${entry.value}');
/// }
///
/// // Using keys and values
/// for (final key in settings.keys) {
///   print('$key: ${settings[key]}');
/// }
/// ```
///
/// See also:
///
/// * [ReactiveList], for reactive ordered collections.
/// * [ReactiveSet], for reactive unordered unique collections.
/// * [Reactive], for simple reactive values.
class ReactiveMap<K, V> extends ReactiveProperty<Map<K, V>>
    implements Map<K, V> {
  /// Creates a [ReactiveMap] with optional initial entries.
  ///
  /// If [initial] is provided, the map is initialized with a copy of those
  /// entries. Otherwise, an empty map is created.
  ///
  /// Example:
  /// ```dart
  /// final empty = ReactiveMap<String, int>();
  /// final withData = ReactiveMap<String, int>({'a': 1, 'b': 2});
  /// ```
  ReactiveMap([Map<K, V>? initial]) : _map = Map<K, V>.from(initial ?? {});

  final Map<K, V> _map;

  /// Returns an unmodifiable view of the current map.
  ///
  /// This prevents external code from modifying the map without triggering
  /// notifications. To modify the map, use the mutation methods directly
  /// on the [ReactiveMap] instance.
  ///
  /// Example:
  /// ```dart
  /// final snapshot = map.value;
  /// // snapshot is Map<K, V> but modifications will throw
  /// ```
  @override
  Map<K, V> get value => UnmodifiableMapView(_map);

  // --- Core operations ---

  /// Returns the value for the given [key], or `null` if not present.
  ///
  /// This is a read operation and doesn't trigger notifications.
  ///
  /// Example:
  /// ```dart
  /// final theme = settings['theme'];
  /// ```
  @override
  V? operator [](Object? key) => _map[key];

  /// Sets the [value] for the given [key] and notifies listeners.
  ///
  /// If the key already exists, its value is updated.
  /// If the key doesn't exist, a new entry is created.
  ///
  /// Example:
  /// ```dart
  /// settings['theme'] = 'dark';
  /// settings['newKey'] = 'newValue';
  /// ```
  @override
  void operator []=(K key, V value) {
    _map[key] = value;
    notifyListeners();
  }

  /// Returns all keys in the map.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  Iterable<K> get keys => _map.keys;

  /// Removes the entry for [key] and notifies listeners if it existed.
  ///
  /// Returns the removed value, or `null` if the key wasn't present.
  /// Only notifies listeners if an entry was actually removed.
  ///
  /// Example:
  /// ```dart
  /// final removed = settings.remove('oldKey');
  /// ```
  @override
  V? remove(Object? key) {
    if (!_map.containsKey(key)) return null;
    final result = _map.remove(key);
    notifyListeners();
    return result;
  }

  /// Removes all entries from the map and notifies listeners if it wasn't empty.
  ///
  /// Example:
  /// ```dart
  /// settings.clear();
  /// ```
  @override
  void clear() {
    if (_map.isEmpty) return;
    _map.clear();
    notifyListeners();
  }

  // --- Add/Update operations ---

  /// Adds all entries from [other] to this map and notifies listeners.
  ///
  /// If a key in [other] already exists in this map, its value is overwritten.
  /// Only notifies if [other] is not empty.
  ///
  /// Example:
  /// ```dart
  /// settings.addAll({'theme': 'dark', 'language': 'en'});
  /// ```
  @override
  void addAll(Map<K, V> other) {
    if (other.isEmpty) return;
    _map.addAll(other);
    notifyListeners();
  }

  /// Adds all [newEntries] to the map and notifies listeners if any were added.
  ///
  /// Example:
  /// ```dart
  /// settings.addEntries([
  ///   MapEntry('key1', 'value1'),
  ///   MapEntry('key2', 'value2'),
  /// ]);
  /// ```
  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    final lengthBefore = _map.length;
    _map.addEntries(newEntries);
    if (_map.length != lengthBefore) notifyListeners();
  }

  /// Looks up [key] or adds a new entry if absent, and notifies listeners if added.
  ///
  /// Returns the value associated with [key]. If the key doesn't exist,
  /// calls [ifAbsent] to get the value, adds it to the map, and returns it.
  ///
  /// Example:
  /// ```dart
  /// final count = stats.putIfAbsent('visits', () => 0);
  /// ```
  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (_map.containsKey(key)) return _map[key] as V;
    final value = ifAbsent();
    _map[key] = value;
    notifyListeners();
    return value;
  }

  /// Updates the value for [key] using [update] and notifies listeners.
  ///
  /// If [key] doesn't exist and [ifAbsent] is provided, adds a new entry.
  /// Throws [ArgumentError] if [key] doesn't exist and [ifAbsent] is not provided.
  ///
  /// Example:
  /// ```dart
  /// // Increment a counter
  /// stats.update('count', (v) => v + 1, ifAbsent: () => 1);
  /// ```
  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    final result = _map.update(key, update, ifAbsent: ifAbsent);
    notifyListeners();
    return result;
  }

  /// Updates all values using [update] and notifies listeners.
  ///
  /// Only notifies if the map is not empty.
  ///
  /// Example:
  /// ```dart
  /// // Double all numeric values
  /// numbers.updateAll((key, value) => value * 2);
  /// ```
  @override
  void updateAll(V Function(K key, V value) update) {
    if (_map.isEmpty) return;
    _map.updateAll(update);
    notifyListeners();
  }

  /// Removes all entries that satisfy [test] and notifies listeners if any were removed.
  ///
  /// Example:
  /// ```dart
  /// // Remove all entries with null values
  /// settings.removeWhere((key, value) => value == null);
  ///
  /// // Remove entries with keys starting with 'temp_'
  /// cache.removeWhere((key, _) => key.startsWith('temp_'));
  /// ```
  @override
  void removeWhere(bool Function(K key, V value) test) {
    final lengthBefore = _map.length;
    _map.removeWhere(test);
    if (_map.length != lengthBefore) notifyListeners();
  }

  // --- Read operations ---

  /// Returns all values in the map.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  Iterable<V> get values => _map.values;

  /// Returns all entries in the map.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  /// The number of entries in the map.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  int get length => _map.length;

  /// Whether the map has no entries.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  bool get isEmpty => _map.isEmpty;

  /// Whether the map has at least one entry.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  bool get isNotEmpty => _map.isNotEmpty;

  /// Whether the map contains an entry with the given [key].
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  /// Whether the map contains an entry with the given [value].
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  bool containsValue(Object? value) => _map.containsValue(value);

  /// Applies [action] to each key-value pair.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  void forEach(void Function(K key, V value) action) => _map.forEach(action);

  /// Creates a new map with transformed entries.
  ///
  /// This returns a new regular [Map], not a [ReactiveMap].
  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) =>
      _map.map(convert);

  @override
  Map<RK, RV> cast<RK, RV>() => _map.cast<RK, RV>();

  // --- Custom reactive methods ---

  /// Replaces all entries with [map] and notifies listeners once.
  ///
  /// This is more efficient than calling [clear] and [addAll] separately,
  /// as it triggers only a single notification.
  ///
  /// Example:
  /// ```dart
  /// settings.replaceAll({
  ///   'theme': 'dark',
  ///   'language': 'en',
  /// });
  /// ```
  void replaceAll(Map<K, V> map) {
    _map
      ..clear()
      ..addAll(map);
    notifyListeners();
  }

  /// Performs multiple operations with a single notification at the end.
  ///
  /// Use this to group multiple map modifications together, triggering
  /// only one rebuild instead of multiple.
  ///
  /// Example:
  /// ```dart
  /// settings.batch((map) {
  ///   map['theme'] = 'light';
  ///   map['fontSize'] = 16;
  ///   map.remove('deprecated');
  /// });
  /// // Only one notification sent after all operations
  /// ```
  void batch(void Function(Map<K, V> map) action) {
    action(_map);
    notifyListeners();
  }

  /// Updates the map without notifying listeners.
  ///
  /// After making changes with [silent], you must manually call [refresh]
  /// to notify listeners. This is useful for preparing multiple changes
  /// before triggering a single notification.
  ///
  /// Example:
  /// ```dart
  /// settings.silent((map) {
  ///   map['computed1'] = compute1();
  ///   map['computed2'] = compute2();
  ///   map.removeWhere((k, _) => k.startsWith('old_'));
  /// });
  /// settings.refresh(); // Now notify listeners
  /// ```
  void silent(void Function(Map<K, V> map) action) {
    action(_map);
  }

  /// Forces a notification to all listeners without changing the map.
  ///
  /// Use this after [silent] operations or when you've modified values
  /// in place and need to trigger a rebuild.
  ///
  /// Example:
  /// ```dart
  /// // After silent modifications
  /// settings.silent((map) => map['key'] = 'value');
  /// settings.refresh();
  ///
  /// // After in-place value modification
  /// settings['user'].name = 'Updated';
  /// settings.refresh(); // Notify that value changed
  /// ```
  void refresh() => notifyListeners();
}
