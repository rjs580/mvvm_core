import 'dart:collection';

import 'package:mvvm_core/src/reactive/reactive_property.dart';

/// A reactive set that automatically notifies listeners when modified.
///
/// [ReactiveSet] wraps a standard Dart [Set] and implements the full [Set]
/// interface, while automatically notifying listeners of any changes. This
/// makes it ideal for managing unique collections of items in your ViewModels.
///
/// ## Basic Usage
///
/// ```dart
/// class TagViewModel extends ViewModel {
///   final selectedTags = ReactiveSet<String>();
///
///   void toggleTag(String tag) {
///     if (selectedTags.contains(tag)) {
///       selectedTags.remove(tag);
///     } else {
///       selectedTags.add(tag);
///     }
///   }
///
///   void clearTags() {
///     selectedTags.clear();
///   }
/// }
///
/// // In the view:
/// vm.selectedTags.listen(
///   builder: (context, tags, _) => Wrap(
///     children: tags.map((tag) => Chip(
///       label: Text(tag),
///       onDeleted: () => vm.toggleTag(tag),
///     )).toList(),
///   ),
/// )
/// ```
///
/// ## Creating ReactiveSet
///
/// ```dart
/// // Empty set
/// final set = ReactiveSet<String>();
///
/// // With initial values
/// final tags = ReactiveSet<String>({'flutter', 'dart', 'mvvm'});
///
/// // From existing set or iterable
/// final copy = ReactiveSet<int>(existingSet);
/// ```
///
/// ## Standard Set Operations
///
/// All standard set operations work and trigger notifications:
///
/// ```dart
/// final tags = ReactiveSet<String>();
///
/// // Add operations
/// tags.add('flutter');           // Returns true if added
/// tags.addAll(['dart', 'mvvm']); // Add multiple
///
/// // Check membership
/// print(tags.contains('flutter')); // true
/// print(tags.length);              // 3
///
/// // Remove operations
/// tags.remove('mvvm');           // Returns true if removed
/// tags.removeAll(['dart']);      // Remove multiple
/// tags.clear();                  // Remove all
/// ```
///
/// ## Uniqueness Guarantee
///
/// Like a regular [Set], duplicate values are automatically ignored:
///
/// ```dart
/// final tags = ReactiveSet<String>({'flutter'});
/// tags.add('flutter'); // Returns false, no notification
/// tags.add('dart');    // Returns true, notifies listeners
/// ```
///
/// ## Set Operations
///
/// Standard set theory operations return new regular [Set]s:
///
/// ```dart
/// final setA = ReactiveSet<int>({1, 2, 3});
/// final setB = {2, 3, 4};
///
/// final union = setA.union(setB);           // {1, 2, 3, 4}
/// final intersection = setA.intersection(setB); // {2, 3}
/// final difference = setA.difference(setB);     // {1}
/// ```
///
/// ## Batch Operations
///
/// Use [batch] to perform multiple operations with a single notification:
///
/// ```dart
/// // Without batch: may trigger multiple notifications
/// selectedIds.add(1);
/// selectedIds.add(2);
/// selectedIds.remove(3);
///
/// // With batch: triggers 1 notification
/// selectedIds.batch((set) {
///   set.add(1);
///   set.add(2);
///   set.remove(3);
/// });
/// ```
///
/// ## Silent Updates
///
/// Use [silent] to update without notifications, then call [refresh]:
///
/// ```dart
/// // Prepare multiple changes
/// tags.silent((set) {
///   set.clear();
///   set.addAll(fetchedTags);
/// });
///
/// // Single notification when ready
/// tags.refresh();
/// ```
///
/// ## Replace All Elements
///
/// Use [replaceAll] to efficiently replace all elements:
///
/// ```dart
/// // Clear and add in one operation
/// selectedTags.replaceAll(['new', 'tags', 'here']);
/// ```
///
/// ## Immutable Access
///
/// The [value] getter returns an unmodifiable view:
///
/// ```dart
/// Set<String> snapshot = tags.value;
/// snapshot.add('test'); // Throws error - can't modify
/// ```
///
/// ## Common Use Cases
///
/// ### Multi-Select
/// ```dart
/// class MultiSelectViewModel extends ViewModel {
///   final selected = ReactiveSet<String>();
///
///   void toggle(String id) {
///     if (selected.contains(id)) {
///       selected.remove(id);
///     } else {
///       selected.add(id);
///     }
///   }
///
///   void selectAll(List<String> ids) => selected.addAll(ids);
///   void clearSelection() => selected.clear();
///   bool isSelected(String id) => selected.contains(id);
/// }
/// ```
///
/// ### Filter Tags
/// ```dart
/// class FilterViewModel extends ViewModel {
///   final activeFilters = ReactiveSet<FilterType>();
///
///   void toggleFilter(FilterType filter) {
///     if (activeFilters.contains(filter)) {
///       activeFilters.remove(filter);
///     } else {
///       activeFilters.add(filter);
///     }
///   }
///
///   List<Item> get filteredItems => items.where((item) =>
///     activeFilters.isEmpty ||
///     activeFilters.contains(item.type)
///   ).toList();
/// }
/// ```
///
/// ### Favorite Items
/// ```dart
/// class FavoritesViewModel extends ViewModel {
///   final favoriteIds = ReactiveSet<String>();
///
///   void toggleFavorite(String id) {
///     if (favoriteIds.contains(id)) {
///       favoriteIds.remove(id);
///     } else {
///       favoriteIds.add(id);
///     }
///   }
///
///   bool isFavorite(String id) => favoriteIds.contains(id);
/// }
/// ```
///
/// ## Performance Optimization
///
/// Listen to specific properties to avoid unnecessary rebuilds:
///
/// ```dart
/// // Only rebuild when count changes
/// vm.selectedTags.select(
///   selector: (set) => set.length,
///   builder: (context, count) => Text('$count selected'),
/// )
///
/// // Only rebuild when empty state changes
/// vm.selectedTags.select(
///   selector: (set) => set.isEmpty,
///   builder: (context, isEmpty) => isEmpty
///     ? const Text('Nothing selected')
///     : SelectedTagsList(tags: vm.selectedTags.value),
/// )
/// ```
///
/// ## Filtering Elements
///
/// ```dart
/// // Remove specific tags
/// tags.removeWhere((tag) => tag.startsWith('temp_'));
///
/// // Keep only specific tags
/// tags.retainWhere((tag) => validTags.contains(tag));
///
/// // Retain only elements in another collection
/// tags.retainAll(allowedTags);
/// ```
///
/// See also:
///
/// * [ReactiveList], for reactive ordered collections.
/// * [ReactiveMap], for reactive key-value collections.
/// * [Reactive], for simple reactive values.
class ReactiveSet<E> extends ReactiveProperty<Set<E>> implements Set<E> {
  /// Creates a [ReactiveSet] with optional initial values.
  ///
  /// If [initial] is provided, the set is initialized with a copy of those
  /// elements. Otherwise, an empty set is created.
  ///
  /// Example:
  /// ```dart
  /// final empty = ReactiveSet<String>();
  /// final withData = ReactiveSet<int>({1, 2, 3});
  /// ```
  ReactiveSet([Set<E>? initial]) : _set = Set<E>.from(initial ?? {});

  final Set<E> _set;

  /// Returns an unmodifiable view of the current set.
  ///
  /// This prevents external code from modifying the set without triggering
  /// notifications. To modify the set, use the mutation methods directly
  /// on the [ReactiveSet] instance.
  ///
  /// Example:
  /// ```dart
  /// final snapshot = tags.value;
  /// // snapshot is Set<E> but modifications will throw
  /// ```
  @override
  Set<E> get value => UnmodifiableSetView(_set);

  // --- Core operations ---

  /// The number of elements in the set.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  int get length => _set.length;

  /// Whether the set has no elements.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  bool get isEmpty => _set.isEmpty;

  /// Whether the set has at least one element.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  bool get isNotEmpty => _set.isNotEmpty;

  /// An iterator over the elements of the set.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  Iterator<E> get iterator => _set.iterator;

  /// Whether [element] is in the set.
  ///
  /// This is a read operation and doesn't trigger notifications.
  ///
  /// Example:
  /// ```dart
  /// if (tags.contains('flutter')) {
  ///   print('Flutter tag is selected');
  /// }
  /// ```
  @override
  bool contains(Object? element) => _set.contains(element);

  /// Returns the element equal to [element], if found.
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  E? lookup(Object? element) => _set.lookup(element);

  // --- Add operations ---

  /// Adds [value] to the set and notifies listeners if the element was added.
  ///
  /// Returns `true` if the element was added (wasn't already in the set).
  /// Returns `false` if the element was already present (no notification).
  ///
  /// Example:
  /// ```dart
  /// final added = tags.add('flutter');
  /// if (added) {
  ///   print('Tag was added');
  /// }
  /// ```
  @override
  bool add(E value) {
    final result = _set.add(value);
    if (result) notifyListeners();
    return result;
  }

  /// Adds all [elements] to the set and notifies listeners if any were added.
  ///
  /// Only notifies if at least one new element was added.
  ///
  /// Example:
  /// ```dart
  /// tags.addAll(['flutter', 'dart', 'mvvm']);
  /// ```
  @override
  void addAll(Iterable<E> elements) {
    final lengthBefore = _set.length;
    _set.addAll(elements);
    if (_set.length != lengthBefore) notifyListeners();
  }

  // --- Remove operations ---

  /// Removes [value] from the set and notifies listeners if it was present.
  ///
  /// Returns `true` if the element was removed.
  /// Returns `false` if the element wasn't found (no notification).
  ///
  /// Example:
  /// ```dart
  /// final removed = tags.remove('flutter');
  /// ```
  @override
  bool remove(Object? value) {
    final result = _set.remove(value);
    if (result) notifyListeners();
    return result;
  }

  /// Removes all [elements] from the set and notifies listeners if any were removed.
  ///
  /// Only notifies if at least one element was removed.
  ///
  /// Example:
  /// ```dart
  /// tags.removeAll(['temp1', 'temp2', 'temp3']);
  /// ```
  @override
  void removeAll(Iterable<Object?> elements) {
    final lengthBefore = _set.length;
    _set.removeAll(elements);
    if (_set.length != lengthBefore) notifyListeners();
  }

  /// Removes all elements that satisfy [test] and notifies listeners if any were removed.
  ///
  /// Example:
  /// ```dart
  /// // Remove all temporary tags
  /// tags.removeWhere((tag) => tag.startsWith('temp_'));
  /// ```
  @override
  void removeWhere(bool Function(E element) test) {
    final lengthBefore = _set.length;
    _set.removeWhere(test);
    if (_set.length != lengthBefore) notifyListeners();
  }

  /// Removes all elements not in [elements] and notifies listeners if any were removed.
  ///
  /// Example:
  /// ```dart
  /// // Keep only allowed tags
  /// tags.retainAll(allowedTags);
  /// ```
  @override
  void retainAll(Iterable<Object?> elements) {
    final lengthBefore = _set.length;
    _set.retainAll(elements);
    if (_set.length != lengthBefore) notifyListeners();
  }

  /// Removes all elements that don't satisfy [test] and notifies listeners if any were removed.
  ///
  /// Example:
  /// ```dart
  /// // Keep only valid tags
  /// tags.retainWhere((tag) => isValidTag(tag));
  /// ```
  @override
  void retainWhere(bool Function(E element) test) {
    final lengthBefore = _set.length;
    _set.retainWhere(test);
    if (_set.length != lengthBefore) notifyListeners();
  }

  /// Removes all elements from the set and notifies listeners if it wasn't empty.
  ///
  /// Example:
  /// ```dart
  /// tags.clear();
  /// ```
  @override
  void clear() {
    if (_set.isEmpty) return;
    _set.clear();
    notifyListeners();
  }

  // --- Set operations (return new sets, no notification) ---

  /// Returns a new set with all elements from this set and [other].
  ///
  /// Returns a regular [Set], not a [ReactiveSet]. Does not modify this set.
  ///
  /// Example:
  /// ```dart
  /// final combined = tagsA.union(tagsB);
  /// ```
  @override
  Set<E> union(Set<E> other) => _set.union(other);

  /// Returns a new set with elements that are in both this set and [other].
  ///
  /// Returns a regular [Set], not a [ReactiveSet]. Does not modify this set.
  ///
  /// Example:
  /// ```dart
  /// final common = selectedTags.intersection(availableTags);
  /// ```
  @override
  Set<E> intersection(Set<Object?> other) => _set.intersection(other);

  /// Returns a new set with elements in this set that are not in [other].
  ///
  /// Returns a regular [Set], not a [ReactiveSet]. Does not modify this set.
  ///
  /// Example:
  /// ```dart
  /// final unique = allTags.difference(usedTags);
  /// ```
  @override
  Set<E> difference(Set<Object?> other) => _set.difference(other);

  /// Creates a copy of this set as a regular [Set].
  ///
  /// Returns a regular [Set], not a [ReactiveSet].
  @override
  Set<E> toSet() => Set<E>.from(_set);

  @override
  Set<R> cast<R>() => _set.cast<R>();

  // --- Read operations ---

  /// The first element in the set.
  ///
  /// Throws [StateError] if the set is empty.
  @override
  E get first => _set.first;

  /// The last element in the set.
  ///
  /// Throws [StateError] if the set is empty.
  @override
  E get last => _set.last;

  /// The single element in the set.
  ///
  /// Throws [StateError] if the set doesn't have exactly one element.
  @override
  E get single => _set.single;

  @override
  bool any(bool Function(E element) test) => _set.any(test);

  @override
  bool every(bool Function(E element) test) => _set.every(test);

  @override
  E elementAt(int index) => _set.elementAt(index);

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _set.firstWhere(test, orElse: orElse);

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _set.lastWhere(test, orElse: orElse);

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _set.singleWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      _set.fold(initialValue, combine);

  @override
  E reduce(E Function(E value, E element) combine) => _set.reduce(combine);

  @override
  void forEach(void Function(E element) action) => _set.forEach(action);

  @override
  String join([String separator = '']) => _set.join(separator);

  @override
  List<E> toList({bool growable = true}) => _set.toList(growable: growable);

  @override
  Iterable<E> skip(int count) => _set.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) => _set.skipWhile(test);

  @override
  Iterable<E> take(int count) => _set.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) => _set.takeWhile(test);

  @override
  Iterable<E> where(bool Function(E element) test) => _set.where(test);

  @override
  Iterable<T> whereType<T>() => _set.whereType<T>();

  @override
  Iterable<E> followedBy(Iterable<E> other) => _set.followedBy(other);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) =>
      _set.expand(toElements);

  @override
  Iterable<T> map<T>(T Function(E element) toElement) => _set.map(toElement);

  /// Whether this set contains all elements in [other].
  ///
  /// This is a read operation and doesn't trigger notifications.
  @override
  bool containsAll(Iterable<Object?> other) => _set.containsAll(other);

  // --- Custom reactive methods ---

  /// Replaces all elements with [elements] and notifies listeners once.
  ///
  /// This is more efficient than calling [clear] and [addAll] separately,
  /// as it triggers only a single notification.
  ///
  /// Example:
  /// ```dart
  /// tags.replaceAll({'new', 'set', 'elements'});
  /// ```
  void replaceAll(Iterable<E> elements) {
    _set
      ..clear()
      ..addAll(elements);
    notifyListeners();
  }

  /// Performs multiple operations with a single notification at the end.
  ///
  /// Use this to group multiple set modifications together, triggering
  /// only one rebuild instead of multiple.
  ///
  /// Example:
  /// ```dart
  /// tags.batch((set) {
  ///   set.add('flutter');
  ///   set.add('dart');
  ///   set.remove('deprecated');
  /// });
  /// // Only one notification sent after all operations
  /// ```
  void batch(void Function(Set<E> set) action) {
    action(_set);
    notifyListeners();
  }

  /// Updates the set without notifying listeners.
  ///
  /// After making changes with [silent], you must manually call [refresh]
  /// to notify listeners. This is useful for preparing multiple changes
  /// before triggering a single notification.
  ///
  /// Example:
  /// ```dart
  /// tags.silent((set) {
  ///   set.clear();
  ///   set.addAll(fetchedTags);
  ///   set.removeWhere((t) => t.isEmpty);
  /// });
  /// tags.refresh(); // Now notify listeners
  /// ```
  void silent(void Function(Set<E> set) action) {
    action(_set);
  }

  /// Forces a notification to all listeners without changing the set.
  ///
  /// Use this after [silent] operations or when external state has changed
  /// and you need to trigger a rebuild.
  ///
  /// Example:
  /// ```dart
  /// // After silent modifications
  /// tags.silent((set) => set.addAll(newTags));
  /// tags.refresh();
  /// ```
  void refresh() => notifyListeners();
}
