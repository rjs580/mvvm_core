import 'package:flutter/foundation.dart';
import 'package:mvvm_core/src/reactive/reactive_property.dart';

/// A reactive property that holds a synchronous value and notifies listeners
/// when it changes.
///
/// [Reactive] is the simplest and most commonly used reactive primitive. It
/// wraps a value of type [T] and automatically notifies listeners whenever
/// the value changes, triggering UI rebuilds.
///
/// ## Basic Usage
///
/// ```dart
/// final counter = Reactive<int>(0);
///
/// // Read the value
/// print(counter.value); // 0
///
/// // Update the value (automatically notifies listeners)
/// counter.value = 1;
/// counter.value++; // Works with increment/decrement
/// ```
///
/// ## In a ViewModel
///
/// ```dart
/// class CounterViewModel extends ViewModel {
///   final count = Reactive<int>(0);
///   final name = Reactive<String>('');
///   final isEnabled = Reactive<bool>(true);
///
///   void increment() => count.value++;
///   void decrement() => count.value--;
///   void reset() => count.value = 0;
/// }
/// ```
///
/// ## Listening in the UI
///
/// Use the [listen] method to rebuild widgets when the value changes:
///
/// ```dart
/// vm.count.listen(
///   builder: (context, count, _) => Text('Count: $count'),
/// )
/// ```
///
/// ## Transforming Values
///
/// Use [update] for transformations based on the current value:
///
/// ```dart
/// final name = Reactive<String>('hello');
///
/// // Transform to uppercase
/// name.update((current) => current.toUpperCase());
/// print(name.value); // 'HELLO'
///
/// // Append text
/// name.update((current) => '$current WORLD');
/// print(name.value); // 'HELLO WORLD'
/// ```
///
/// ## Working with Objects
///
/// For mutable objects, use [refresh] after modifying internal state:
///
/// ```dart
/// class User {
///   String name;
///   int age;
///   User(this.name, this.age);
/// }
///
/// final user = Reactive<User>(User('John', 25));
///
/// // Modifying the object's properties doesn't trigger notification
/// user.value.name = 'Jane'; // ❌ UI won't update
///
/// // Option 1: Use refresh() after modification
/// user.value.name = 'Jane';
/// user.refresh(); // ✅ UI updates
///
/// // Option 2: Assign a new object (preferred for immutability)
/// user.value = User('Jane', user.value.age); // ✅ UI updates
/// ```
///
/// ## With Immutable Objects (Recommended)
///
/// Using immutable objects with `copyWith` is the preferred pattern:
///
/// ```dart
/// class User {
///   final String name;
///   final int age;
///
///   const User({required this.name, required this.age});
///
///   User copyWith({String? name, int? age}) {
///     return User(
///       name: name ?? this.name,
///       age: age ?? this.age,
///     );
///   }
/// }
///
/// final user = Reactive<User>(const User(name: 'John', age: 25));
///
/// // Update using copyWith
/// user.update((u) => u.copyWith(name: 'Jane'));
/// user.update((u) => u.copyWith(age: u.age + 1));
/// ```
///
/// ## Nullable Values
///
/// [Reactive] works with nullable types:
///
/// ```dart
/// final selectedUser = Reactive<User?>(null);
///
/// // Set a value
/// selectedUser.value = User('John', 25);
///
/// // Clear the selection
/// selectedUser.value = null;
///
/// // Listen with null handling
/// selectedUser.listen(
///   builder: (context, user, _) => user != null
///     ? Text(user.name)
///     : const Text('No user selected'),
/// )
/// ```
///
/// ## Equality Checking
///
/// [Reactive] uses `==` to check if the value has changed. If the new value
/// equals the old value, listeners are not notified:
///
/// ```dart
/// final count = Reactive<int>(5);
/// count.value = 5; // No notification (same value)
/// count.value = 6; // Notifies listeners (different value)
/// ```
///
/// For custom objects, ensure proper `==` and `hashCode` implementation:
///
/// ```dart
/// class Point {
///   final int x, y;
///   const Point(this.x, this.y);
///
///   @override
///   bool operator ==(Object other) =>
///     other is Point && other.x == x && other.y == y;
///
///   @override
///   int get hashCode => Object.hash(x, y);
/// }
/// ```
///
/// ## Selective Listening
///
/// Use [select] to only rebuild when a specific part of the value changes:
///
/// ```dart
/// final user = Reactive<User>(User(name: 'John', age: 25));
///
/// // Only rebuilds when age changes, ignores name changes
/// user.select(
///   selector: (u) => u.age,
///   builder: (context, age) => Text('Age: $age'),
/// )
/// ```
///
/// See also:
///
/// * [ReactiveProperty], the base class for all reactive properties.
/// * [ReactiveFuture], for async operations with Futures.
/// * [ReactiveStream], for Stream-based reactive data.
/// * [ReactiveList], [ReactiveMap], [ReactiveSet] for reactive collections.
class Reactive<T> extends ReactiveProperty<T> {
  /// Creates a [Reactive] with the given initial value.
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive<int>(0);
  /// final name = Reactive<String>('John');
  /// final user = Reactive<User?>(null);
  /// ```
  Reactive(this._value);

  @protected
  T _value;

  /// The current value of this reactive property.
  ///
  /// Reading this getter returns the current value synchronously.
  /// To react to changes, use [listen], [select], or [addListener].
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive<int>(0);
  /// print(counter.value); // 0
  /// ```
  @override
  T get value => _value;

  /// Sets a new value and notifies listeners if the value changed.
  ///
  /// If [newValue] equals the current value (using `==`), no notification
  /// is sent and listeners are not called. This prevents unnecessary rebuilds.
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive<int>(0);
  ///
  /// counter.value = 1;  // Notifies listeners
  /// counter.value = 1;  // No notification (same value)
  /// counter.value++;    // Notifies listeners
  /// counter.value += 5; // Notifies listeners
  /// ```
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  /// Updates the value using a transform function.
  ///
  /// The [transform] function receives the current value and should return
  /// the new value. This is useful for updates that depend on the current
  /// state.
  ///
  /// If the transformed value equals the current value, no notification
  /// is sent.
  ///
  /// ## Example: Simple Transformations
  ///
  /// ```dart
  /// final counter = Reactive<int>(0);
  ///
  /// counter.update((n) => n + 1);     // Increment
  /// counter.update((n) => n * 2);     // Double
  /// counter.update((n) => n.clamp(0, 100)); // Clamp
  /// ```
  ///
  /// ## Example: String Transformations
  ///
  /// ```dart
  /// final text = Reactive<String>('hello');
  ///
  /// text.update((s) => s.toUpperCase());
  /// text.update((s) => s.trim());
  /// text.update((s) => '$s world');
  /// ```
  ///
  /// ## Example: Object Updates with copyWith
  ///
  /// ```dart
  /// final user = Reactive<User>(User(name: 'John', age: 25));
  ///
  /// user.update((u) => u.copyWith(age: u.age + 1));
  /// user.update((u) => u.copyWith(name: u.name.toUpperCase()));
  /// ```
  ///
  /// ## Example: List/Collection in Reactive
  ///
  /// ```dart
  /// final items = Reactive<List<String>>([]);
  ///
  /// // Add item (creates new list)
  /// items.update((list) => [...list, 'new item']);
  ///
  /// // Remove item
  /// items.update((list) => list.where((i) => i != 'remove').toList());
  /// ```
  ///
  /// Note: For reactive collections, prefer [ReactiveList], [ReactiveMap],
  /// or [ReactiveSet] for better performance and API.
  void update(T Function(T current) transform) {
    value = transform(_value);
  }

  /// Forces a notification to all listeners without changing the value.
  ///
  /// This is useful when the internal state of a mutable object has changed
  /// but the reference remains the same, so the normal equality check would
  /// not detect a change.
  ///
  /// ## Example: Mutable Object Modification
  ///
  /// ```dart
  /// class Counter {
  ///   int value = 0;
  /// }
  ///
  /// final counter = Reactive<Counter>(Counter());
  ///
  /// // Modify the object's internal state
  /// counter.value.value = 10;
  ///
  /// // Force notification since reference didn't change
  /// counter.refresh();
  /// ```
  ///
  /// ## Example: External State Sync
  ///
  /// ```dart
  /// final config = Reactive<AppConfig>(loadConfig());
  ///
  /// // Config was updated externally
  /// externalConfigService.onUpdate(() {
  ///   config.refresh(); // Notify listeners to re-read
  /// });
  /// ```
  ///
  /// ## When to Use
  ///
  /// - After modifying mutable object properties
  /// - When external state has changed
  /// - To force a UI refresh
  ///
  /// ## Prefer Immutable Objects
  ///
  /// Consider using immutable objects with `copyWith` instead of [refresh]:
  ///
  /// ```dart
  /// // Instead of:
  /// user.value.name = 'Jane';
  /// user.refresh();
  ///
  /// // Prefer:
  /// user.update((u) => u.copyWith(name: 'Jane'));
  /// ```
  void refresh() => notifyListeners();
}
