import 'dart:collection';
import 'dart:math';
import 'package:mvvm_core/src/reactive/reactive_property.dart';

/// A reactive list that automatically notifies listeners when modified.
///
/// [ReactiveList] wraps a standard Dart [List] and implements the full [List]
/// interface, while automatically notifying listeners of any changes. This
/// makes it perfect for managing collections of items in your ViewModels.
///
/// ## Basic Usage
///
/// ```dart
/// class TodoViewModel extends ViewModel {
///   final todos = ReactiveList<Todo>([]);
///
///   void addTodo(String title) {
///     todos.add(Todo(title: title));
///   }
///
///   void removeTodo(Todo todo) {
///     todos.remove(todo);
///   }
///
///   void clearCompleted() {
///     todos.removeWhere((t) => t.isCompleted);
///   }
/// }
///
/// // In the view:
/// vm.todos.listen(
///   builder: (context, todos, _) => ListView.builder(
///     itemCount: todos.length,
///     itemBuilder: (_, i) => TodoItem(todo: todos[i]),
///   ),
/// )
/// ```
///
/// ## Creating ReactiveList
///
/// ```dart
/// // Empty list
/// final items = ReactiveList<String>();
///
/// // With initial values
/// final numbers = ReactiveList<int>([1, 2, 3]);
///
/// // From existing list
/// final copy = ReactiveList<String>(existingList);
/// ```
///
/// ## Standard List Operations
///
/// All standard list operations work and trigger notifications:
///
/// ```dart
/// final items = ReactiveList<String>();
///
/// // Add operations
/// items.add('apple');
/// items.addAll(['banana', 'cherry']);
/// items.insert(0, 'first');
///
/// // Access operations
/// print(items[0]);        // 'first'
/// print(items.length);    // 4
/// print(items.first);     // 'first'
/// print(items.last);      // 'cherry'
///
/// // Update operations
/// items[0] = 'updated';
/// items.sort();
/// items.shuffle();
///
/// // Remove operations
/// items.remove('banana');
/// items.removeAt(0);
/// items.clear();
/// ```
///
/// ## Batch Operations
///
/// Use [batch] to perform multiple operations with a single notification:
///
/// ```dart
/// // Without batch: triggers 3 notifications
/// items.add('a');
/// items.add('b');
/// items.add('c');
///
/// // With batch: triggers 1 notification
/// items.batch((list) {
///   list.add('a');
///   list.add('b');
///   list.add('c');
/// });
/// ```
///
/// ## Silent Updates
///
/// Use [silent] to update without triggering notifications, then call [refresh]:
///
/// ```dart
/// // Prepare multiple changes
/// items.silent((list) {
///   list.sort();
///   list.removeDuplicates();
///   list.addAll(newItems);
/// });
///
/// // Single notification when ready
/// items.refresh();
/// ```
///
/// ## Replace All Elements
///
/// Use [replaceAll] to efficiently replace the entire list:
///
/// ```dart
/// // Clear and add in one operation
/// items.replaceAll(['new', 'items', 'here']);
/// ```
///
/// ## Immutable Access
///
/// The [value] getter returns an unmodifiable view:
///
/// ```dart
/// List<String> snapshot = items.value;
/// snapshot.add('test'); // Throws error - can't modify
/// ```
///
/// ## Filtering and Transforming
///
/// ```dart
/// // Remove completed todos
/// todos.removeWhere((todo) => todo.isCompleted);
///
/// // Keep only active todos
/// todos.retainWhere((todo) => !todo.isCompleted);
///
/// // Find specific item
/// final found = todos.firstWhere(
///   (todo) => todo.id == targetId,
///   orElse: () => Todo.empty(),
/// );
/// ```
///
/// ## With ListView
///
/// ```dart
/// vm.items.listen(
///   builder: (context, items, _) => ListView.builder(
///     itemCount: items.length,
///     itemBuilder: (context, index) {
///       final item = items[index];
///       return ListTile(
///         title: Text(item.name),
///         onTap: () => vm.selectItem(index),
///       );
///     },
///   ),
/// )
/// ```
///
/// ## Performance Optimization
///
/// Listen to specific properties to avoid unnecessary rebuilds:
///
/// ```dart
/// // Only rebuild when length changes
/// vm.items.select(
///   selector: (list) => list.length,
///   builder: (context, count) => Text('$count items'),
/// )
///
/// // Only rebuild when isEmpty changes
/// vm.items.select(
///   selector: (list) => list.isEmpty,
///   builder: (context, isEmpty) => isEmpty
///     ? const EmptyState()
///     : ItemList(items: vm.items.value),
/// )
/// ```
///
/// ## Sorting
///
/// ```dart
/// // Sort alphabetically
/// items.sort();
///
/// // Custom sort
/// items.sort((a, b) => a.priority.compareTo(b.priority));
///
/// // Sort in batch
/// items.batch((list) {
///   list.sort((a, b) => a.date.compareTo(b.date));
/// });
/// ```
///
/// ## Common Patterns
///
/// ### Todo List
/// ```dart
/// class TodoListViewModel extends ViewModel {
///   final todos = ReactiveList<Todo>();
///
///   void addTodo(String title) => todos.add(Todo(title));
///   void toggleTodo(int index) => todos[index] = todos[index].toggle();
///   void deleteTodo(int index) => todos.removeAt(index);
///   void clearCompleted() => todos.removeWhere((t) => t.isCompleted);
/// }
/// ```
///
/// ### Shopping Cart
/// ```dart
/// class CartViewModel extends ViewModel {
///   final items = ReactiveList<CartItem>();
///
///   void addItem(Product product) {
///     final index = items.indexWhere((i) => i.product.id == product.id);
///     if (index >= 0) {
///       items[index] = items[index].incrementQuantity();
///     } else {
///       items.add(CartItem(product: product));
///     }
///   }
///
///   void removeItem(CartItem item) => items.remove(item);
///   void clear() => items.clear();
/// }
/// ```
///
/// See also:
///
/// * [ReactiveMap], for reactive key-value collections.
/// * [ReactiveSet], for reactive unordered collections.
/// * [Reactive], for simple reactive values.
class ReactiveList<E> extends ReactiveProperty<List<E>> implements List<E> {
  /// Creates a [ReactiveList] with optional initial values.
  ///
  /// If [initial] is provided, the list is initialized with a copy of those
  /// elements. Otherwise, an empty list is created.
  ///
  /// Example:
  /// ```dart
  /// final empty = ReactiveList<String>();
  /// final withData = ReactiveList<int>([1, 2, 3]);
  /// ```
  ReactiveList([List<E>? initial]) : _list = List<E>.from(initial ?? []);

  final List<E> _list;

  /// Returns an unmodifiable view of the current list.
  ///
  /// This prevents external code from modifying the list without triggering
  /// notifications. To modify the list, use the mutation methods directly
  /// on the [ReactiveList] instance.
  ///
  /// Example:
  /// ```dart
  /// final snapshot = items.value;
  /// // snapshot is List<E> but modifications will throw
  /// ```
  @override
  List<E> get value => UnmodifiableListView(_list);

  // --- Core operations ---

  /// The number of elements in the list.
  ///
  /// Getting the length is a read operation and doesn't trigger notifications.
  ///
  /// Example:
  /// ```dart
  /// print('List has ${items.length} items');
  /// ```
  @override
  int get length => _list.length;

  /// Changes the length of the list and notifies listeners.
  ///
  /// If [newLength] is greater than the current length, the list is extended
  /// with `null` values (for nullable types) or default values.
  /// If [newLength] is less than the current length, the list is truncated.
  ///
  /// Example:
  /// ```dart
  /// items.length = 10; // Extend or truncate to 10 elements
  /// ```
  @override
  set length(int newLength) {
    _list.length = newLength;
    notifyListeners();
  }

  /// Returns the element at the given [index].
  ///
  /// This is a read operation and doesn't trigger notifications.
  ///
  /// Throws a [RangeError] if [index] is out of bounds.
  @override
  E operator [](int index) => _list[index];

  /// Sets the element at the given [index] to [value] and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items[0] = 'updated';
  /// ```
  ///
  /// Throws a [RangeError] if [index] is out of bounds.
  @override
  void operator []=(int index, E value) {
    _list[index] = value;
    notifyListeners();
  }

  // --- Add operations ---

  /// Adds [element] to the end of the list and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items.add('new item');
  /// ```
  @override
  void add(E element) {
    _list.add(element);
    notifyListeners();
  }

  /// Appends all elements of [iterable] to the end of the list and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items.addAll(['item1', 'item2', 'item3']);
  /// ```
  @override
  void addAll(Iterable<E> iterable) {
    if (iterable.isEmpty) return;

    _list.addAll(iterable);
    notifyListeners();
  }

  /// Inserts [element] at position [index] and notifies listeners.
  ///
  /// This shifts all elements at or after [index] to the right.
  ///
  /// Example:
  /// ```dart
  /// items.insert(0, 'first'); // Insert at beginning
  /// ```
  ///
  /// Throws a [RangeError] if [index] is negative or greater than length.
  @override
  void insert(int index, E element) {
    _list.insert(index, element);
    notifyListeners();
  }

  /// Inserts all elements of [iterable] at position [index] and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items.insertAll(0, ['a', 'b', 'c']); // Insert at beginning
  /// ```
  @override
  void insertAll(int index, Iterable<E> iterable) {
    _list.insertAll(index, iterable);
    notifyListeners();
  }

  // --- Remove operations ---

  /// Removes the first occurrence of [element] from the list.
  ///
  /// Returns `true` if an element was removed and notifies listeners.
  /// Returns `false` if the element was not found (no notification).
  ///
  /// Example:
  /// ```dart
  /// final removed = items.remove('target');
  /// ```
  @override
  bool remove(Object? element) {
    final result = _list.remove(element);
    if (result) notifyListeners();
    return result;
  }

  /// Removes the element at position [index] and notifies listeners.
  ///
  /// Returns the removed element.
  ///
  /// Example:
  /// ```dart
  /// final removed = items.removeAt(0);
  /// ```
  ///
  /// Throws a [RangeError] if [index] is out of bounds.
  @override
  E removeAt(int index) {
    final result = _list.removeAt(index);
    notifyListeners();
    return result;
  }

  /// Removes and returns the last element of the list, then notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// final last = items.removeLast();
  /// ```
  ///
  /// Throws a [StateError] if the list is empty.
  @override
  E removeLast() {
    final result = _list.removeLast();
    notifyListeners();
    return result;
  }

  /// Removes elements in the range from [start] to [end] and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items.removeRange(2, 5); // Remove elements at indices 2, 3, 4
  /// ```
  @override
  void removeRange(int start, int end) {
    _list.removeRange(start, end);
    notifyListeners();
  }

  /// Removes all elements that satisfy [test] and notifies listeners if any were removed.
  ///
  /// Example:
  /// ```dart
  /// todos.removeWhere((todo) => todo.isCompleted);
  /// ```
  @override
  void removeWhere(bool Function(E element) test) {
    final lengthBefore = _list.length;
    _list.removeWhere(test);
    if (_list.length != lengthBefore) notifyListeners();
  }

  /// Removes all elements that don't satisfy [test] and notifies listeners if any were removed.
  ///
  /// Example:
  /// ```dart
  /// todos.retainWhere((todo) => !todo.isCompleted); // Keep only active
  /// ```
  @override
  void retainWhere(bool Function(E element) test) {
    final lengthBefore = _list.length;
    _list.retainWhere(test);
    if (_list.length != lengthBefore) notifyListeners();
  }

  /// Removes all elements from the list and notifies listeners if the list was not empty.
  ///
  /// Example:
  /// ```dart
  /// items.clear();
  /// ```
  @override
  void clear() {
    if (_list.isEmpty) return;
    _list.clear();
    notifyListeners();
  }

  // --- Update operations ---

  /// Overwrites elements starting at [index] with elements from [iterable] and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items.setAll(2, ['new1', 'new2']); // Replace from index 2
  /// ```
  @override
  void setAll(int index, Iterable<E> iterable) {
    _list.setAll(index, iterable);
    notifyListeners();
  }

  /// Copies elements from [iterable] into the range [start]..[end] and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items.setRange(0, 3, ['a', 'b', 'c']);
  /// ```
  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _list.setRange(start, end, iterable, skipCount);
    notifyListeners();
  }

  /// Sets all elements in the range [start]..[end] to [fillValue] and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items.fillRange(0, 5, 'default');
  /// ```
  @override
  void fillRange(int start, int end, [E? fillValue]) {
    _list.fillRange(start, end, fillValue);
    notifyListeners();
  }

  /// Replaces elements in the range [start]..[end] with [replacements] and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items.replaceRange(2, 4, ['new1', 'new2', 'new3']);
  /// ```
  @override
  void replaceRange(int start, int end, Iterable<E> replacements) {
    _list.replaceRange(start, end, replacements);
    notifyListeners();
  }

  /// Shuffles the elements randomly and notifies listeners.
  ///
  /// Example:
  /// ```dart
  /// items.shuffle(); // Random shuffle
  /// items.shuffle(Random(42)); // Seeded shuffle
  /// ```
  @override
  void shuffle([Random? random]) {
    _list.shuffle(random);
    notifyListeners();
  }

  /// Sorts the list according to [compare] and notifies listeners.
  ///
  /// If [compare] is omitted, elements must be [Comparable].
  ///
  /// Example:
  /// ```dart
  /// numbers.sort(); // Natural order
  /// items.sort((a, b) => a.priority.compareTo(b.priority));
  /// ```
  @override
  void sort([int Function(E a, E b)? compare]) {
    _list.sort(compare);
    notifyListeners();
  }

  // --- Read operations (delegate directly) ---

  @override
  E get first => _list.first;

  @override
  set first(E value) {
    _list.first = value;
    notifyListeners();
  }

  @override
  E get last => _list.last;

  @override
  set last(E value) {
    _list.last = value;
    notifyListeners();
  }

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  Iterator<E> get iterator => _list.iterator;

  @override
  Iterable<E> get reversed => _list.reversed;

  @override
  E get single => _list.single;

  @override
  bool any(bool Function(E element) test) => _list.any(test);

  @override
  bool every(bool Function(E element) test) => _list.every(test);

  @override
  bool contains(Object? element) => _list.contains(element);

  @override
  E elementAt(int index) => _list.elementAt(index);

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _list.firstWhere(test, orElse: orElse);

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _list.lastWhere(test, orElse: orElse);

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _list.singleWhere(test, orElse: orElse);

  @override
  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) =>
      _list.indexWhere(test, start);

  @override
  int lastIndexOf(E element, [int? start]) => _list.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) =>
      _list.lastIndexWhere(test, start);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      _list.fold(initialValue, combine);

  @override
  E reduce(E Function(E value, E element) combine) => _list.reduce(combine);

  @override
  void forEach(void Function(E element) action) => _list.forEach(action);

  @override
  String join([String separator = '']) => _list.join(separator);

  @override
  List<E> operator +(List<E> other) => _list + other;

  @override
  List<E> sublist(int start, [int? end]) => _list.sublist(start, end);

  @override
  List<E> toList({bool growable = true}) => _list.toList(growable: growable);

  @override
  Set<E> toSet() => _list.toSet();

  @override
  Iterable<E> getRange(int start, int end) => _list.getRange(start, end);

  @override
  Iterable<E> skip(int count) => _list.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) => _list.skipWhile(test);

  @override
  Iterable<E> followedBy(Iterable<E> other) => _list.followedBy(other);

  @override
  Iterable<E> take(int count) => _list.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) => _list.takeWhile(test);

  @override
  Iterable<E> where(bool Function(E element) test) => _list.where(test);

  @override
  Iterable<T> whereType<T>() => _list.whereType<T>();

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) =>
      _list.expand(toElements);

  @override
  Iterable<T> map<T>(T Function(E element) toElement) => _list.map(toElement);

  @override
  Map<int, E> asMap() => _list.asMap();

  @override
  List<R> cast<R>() => _list.cast<R>();

  // --- Custom reactive methods ---

  /// Replaces all elements with [elements] and notifies listeners once.
  ///
  /// This is more efficient than calling [clear] and [addAll] separately,
  /// as it triggers only a single notification.
  ///
  /// Example:
  /// ```dart
  /// items.replaceAll(['new', 'list', 'items']);
  /// ```
  void replaceAll(Iterable<E> elements) {
    _list
      ..clear()
      ..addAll(elements);
    notifyListeners();
  }

  /// Performs multiple operations with a single notification at the end.
  ///
  /// Use this to group multiple list modifications together, triggering
  /// only one rebuild instead of multiple.
  ///
  /// Example:
  /// ```dart
  /// items.batch((list) {
  ///   list.add('a');
  ///   list.add('b');
  ///   list.removeAt(0);
  ///   list.sort();
  /// });
  /// // Only one notification sent after all operations
  /// ```
  void batch(void Function(List<E> list) action) {
    action(_list);
    notifyListeners();
  }

  /// Updates the list without notifying listeners.
  ///
  /// After making changes with [silent], you must manually call [refresh]
  /// to notify listeners. This is useful for preparing multiple changes
  /// before triggering a single notification.
  ///
  /// Example:
  /// ```dart
  /// items.silent((list) {
  ///   list.sort();
  ///   list.removeDuplicates();
  ///   list.addAll(newItems);
  /// });
  /// items.refresh(); // Now notify listeners
  /// ```
  void silent(void Function(List<E> list) action) {
    action(_list);
  }

  /// Forces a notification to all listeners without changing the list.
  ///
  /// Use this after [silent] operations or when you've modified elements
  /// in place and need to trigger a rebuild.
  ///
  /// Example:
  /// ```dart
  /// // After silent modifications
  /// items.silent((list) => list.sort());
  /// items.refresh();
  ///
  /// // After in-place object modification
  /// items[0].completed = true;
  /// items.refresh(); // Notify that item changed
  /// ```
  void refresh() => notifyListeners();
}
