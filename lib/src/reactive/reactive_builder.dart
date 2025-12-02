import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that rebuilds when a [ReactiveProperty] changes.
///
/// [ReactiveBuilder] listens to a [ValueListenable] and calls its [builder]
/// function whenever the value changes. It is a thin wrapper around Flutter's
/// [ValueListenableBuilder] designed to work seamlessly with [ReactiveProperty]
/// and its subclasses.
///
/// ## Typical Usage
///
/// While you can use [ReactiveBuilder] directly, it's typically more convenient
/// to use the [ReactiveProperty.listen] extension method:
///
/// ```dart
/// // Using listen() - recommended
/// vm.counter.listen(
///   builder: (context, value, child) => Text('$value'),
/// )
///
/// // Using ReactiveBuilder directly - equivalent
/// ReactiveBuilder<int>(
///   property: vm.counter,
///   builder: (context, value, child) => Text('$value'),
/// )
/// ```
///
/// ## Basic Example
///
/// ```dart
/// class CounterViewModel extends ViewModel {
///   final count = Reactive<int>(0);
///   void increment() => count.value++;
/// }
///
/// // In your view:
/// ReactiveBuilder<int>(
///   property: vm.count,
///   builder: (context, count, _) => Column(
///     children: [
///       Text('Count: $count'),
///       ElevatedButton(
///         onPressed: vm.increment,
///         child: const Text('Increment'),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ## Optimizing with Child
///
/// Use the [child] parameter to cache widgets that don't depend on the value.
/// The child is built once and passed to the builder on each rebuild:
///
/// ```dart
/// ReactiveBuilder<int>(
///   property: vm.count,
///   child: const Icon(Icons.favorite), // Built once, reused
///   builder: (context, count, child) => Row(
///     children: [
///       child!, // Cached icon
///       Text('$count likes'),
///     ],
///   ),
/// )
/// ```
///
/// ## With Complex Objects
///
/// ```dart
/// class UserViewModel extends ViewModel {
///   final user = Reactive<User>(User(name: 'John', age: 25));
/// }
///
/// ReactiveBuilder<User>(
///   property: vm.user,
///   builder: (context, user, _) => ListTile(
///     title: Text(user.name),
///     subtitle: Text('${user.age} years old'),
///   ),
/// )
/// ```
///
/// ## With Nullable Values
///
/// ```dart
/// final selectedItem = Reactive<Item?>(null);
///
/// ReactiveBuilder<Item?>(
///   property: selectedItem,
///   builder: (context, item, _) => item != null
///     ? ItemDetails(item: item)
///     : const Text('No item selected'),
/// )
/// ```
///
/// ## Nested Builders
///
/// For multiple properties, you can nest builders, though [MultiReactiveBuilder]
/// is often cleaner:
///
/// ```dart
/// // Nested approach
/// ReactiveBuilder<String>(
///   property: vm.firstName,
///   builder: (context, firstName, _) => ReactiveBuilder<String>(
///     property: vm.lastName,
///     builder: (context, lastName, _) => Text('$firstName $lastName'),
///   ),
/// )
///
/// // Better: Use MultiReactiveBuilder
/// MultiReactiveBuilder(
///   properties: [vm.firstName, vm.lastName],
///   builder: (context, _) => Text(
///     '${vm.firstName.value} ${vm.lastName.value}',
///   ),
/// )
/// ```
///
/// ## Works with Any ValueListenable
///
/// While designed for [ReactiveProperty], it works with any [ValueListenable]:
///
/// ```dart
/// final valueNotifier = ValueNotifier<int>(0);
///
/// ReactiveBuilder<int>(
///   property: valueNotifier,
///   builder: (context, value, _) => Text('$value'),
/// )
/// ```
///
/// ## When to Use ReactiveBuilder vs listen()
///
/// | Scenario | Recommendation |
/// |----------|----------------|
/// | Simple usage | Use `property.listen()` |
/// | Need explicit type | Use `ReactiveBuilder<T>()` |
/// | Custom widget class | Use `ReactiveBuilder` in build method |
/// | Storing in variable | Use `ReactiveBuilder` |
///
/// See also:
///
/// * [ReactiveProperty.listen], the convenience method that creates this widget.
/// * [SelectReactiveBuilder], for selective rebuilds based on derived values.
/// * [MultiReactiveBuilder], for listening to multiple properties.
/// * [ValueListenableBuilder], the Flutter widget this wraps.
class ReactiveBuilder<T> extends StatelessWidget {
  /// Creates a [ReactiveBuilder].
  ///
  /// The [property] and [builder] arguments must not be null.
  ///
  /// The [child] argument is optional and can be used to pass a widget
  /// that doesn't depend on the reactive value for optimization.
  const ReactiveBuilder({
    super.key,
    required this.property,
    required this.builder,
    this.child,
  });

  /// The [ValueListenable] to listen to.
  ///
  /// Typically a [ReactiveProperty] such as [Reactive], [ReactiveFuture],
  /// [ReactiveStream], or any reactive collection. Can also be any other
  /// [ValueListenable] like [ValueNotifier].
  ///
  /// The widget will rebuild whenever this property notifies its listeners.
  final ValueListenable<T> property;

  /// Called whenever the [property] value changes.
  ///
  /// The builder receives:
  /// - [context]: The [BuildContext] for building widgets
  /// - [value]: The current value of the property
  /// - [child]: The widget passed to the [child] parameter
  ///
  /// This function should return the widget to display based on the
  /// current value.
  ///
  /// Example:
  /// ```dart
  /// builder: (context, value, child) => Text('Value: $value'),
  /// ```
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// A widget that doesn't depend on the reactive property's value.
  ///
  /// This widget is built once and passed to the [builder] function on
  /// each rebuild. Use this for expensive widgets or static content that
  /// shouldn't rebuild when the property changes.
  ///
  /// The child is available as the third parameter in the [builder] function.
  ///
  /// Example:
  /// ```dart
  /// ReactiveBuilder<int>(
  ///   property: counter,
  ///   child: const ExpensiveWidget(), // Built once
  ///   builder: (context, count, child) => Column(
  ///     children: [
  ///       child!, // Reused on each rebuild
  ///       Text('$count'),
  ///     ],
  ///   ),
  /// )
  /// ```
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: property,
      builder: builder,
      child: child,
    );
  }
}
