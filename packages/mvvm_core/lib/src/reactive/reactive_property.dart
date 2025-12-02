import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_core/src/reactive/reactive_builder.dart';
import 'package:mvvm_core/src/reactive/select_reactive_builder.dart';

/// Abstract base class for all reactive properties in the MVVM architecture.
///
/// [ReactiveProperty] provides a foundation for creating observable values that
/// automatically notify listeners when they change. It extends [ChangeNotifier]
/// for listener management, implements [ValueListenable] for compatibility with
/// Flutter's built-in widgets, and includes [DiagnosticableTreeMixin] for
/// Flutter DevTools integration.
///
/// ## Overview
///
/// This is an abstract class that defines the contract for reactive properties.
/// Use one of the concrete implementations based on your needs:
///
/// | Class | Use Case |
/// |-------|----------|
/// | [Reactive] | Simple synchronous values |
/// | [ReactiveFuture] | Async operations with Futures |
/// | [ReactiveStream] | Stream-based reactive data |
/// | [ReactiveList] | Observable lists |
/// | [ReactiveMap] | Observable maps |
/// | [ReactiveSet] | Observable sets |
///
/// ## Listening to Changes
///
/// Use the [listen] method to create a widget that rebuilds when the value changes:
///
/// ```dart
/// final counter = Reactive<int>(0);
///
/// // In your build method:
/// counter.listen(
///   builder: (context, value, child) => Text('Count: $value'),
/// )
/// ```
///
/// ## Optimizing Rebuilds with Child
///
/// Pass a [child] widget that doesn't depend on the value to optimize rebuilds:
///
/// ```dart
/// counter.listen(
///   child: const Icon(Icons.star), // Won't rebuild
///   builder: (context, value, child) => Row(
///     children: [
///       child!, // Reused across rebuilds
///       Text('$value'),
///     ],
///   ),
/// )
/// ```
///
/// ## Selective Listening
///
/// Use the [select] method to only rebuild when a specific part of the value changes:
///
/// ```dart
/// final user = Reactive<User>(User(name: 'John', email: 'john@example.com'));
///
/// // Only rebuilds when email changes, not when name changes
/// user.select(
///   selector: (user) => user.email,
///   builder: (context, email) => Text(email),
/// )
/// ```
///
/// ## Using with ValueListenableBuilder
///
/// Since [ReactiveProperty] implements [ValueListenable], it works with
/// Flutter's built-in [ValueListenableBuilder]:
///
/// ```dart
/// ValueListenableBuilder<int>(
///   valueListenable: counter,
///   builder: (context, value, child) => Text('$value'),
/// )
/// ```
///
/// ## DevTools Integration
///
/// The current [value] is automatically exposed in Flutter DevTools through
/// the [debugFillProperties] implementation. You can see the value in the
/// widget inspector when debugging your app.
///
/// ## Creating Custom Reactive Properties
///
/// Extend this class to create custom reactive properties:
///
/// ```dart
/// class ReactiveColor extends ReactiveProperty<Color> {
///   ReactiveColor(this._color);
///
///   Color _color;
///
///   @override
///   Color get value => _color;
///
///   set value(Color newColor) {
///     if (_color == newColor) return;
///     _color = newColor;
///     notifyListeners();
///   }
///
///   void lerp(Color target, double t) {
///     value = Color.lerp(_color, target, t)!;
///   }
/// }
/// ```
///
/// See also:
///
/// * [Reactive], for simple synchronous reactive values.
/// * [ReactiveFuture], for Future-based async state.
/// * [ReactiveStream], for Stream-based reactive state.
/// * [ReactiveBuilder], the widget used by [listen].
/// * [SelectReactiveBuilder], the widget used by [select].
/// * [ValueListenable], the Flutter interface this class implements.
abstract class ReactiveProperty<T> extends ChangeNotifier
    with DiagnosticableTreeMixin
    implements ValueListenable<T> {
  /// The current value of this reactive property.
  ///
  /// Accessing this getter returns the current value synchronously.
  /// To react to changes, use [listen], [select], or [addListener].
  ///
  /// Example:
  /// ```dart
  /// final counter = Reactive<int>(0);
  /// print(counter.value); // 0
  /// ```
  @override
  T get value;

  /// Creates a widget that rebuilds whenever this property's value changes.
  ///
  /// The [builder] function is called with the current [BuildContext],
  /// the current [value], and an optional [child] widget. It should return
  /// the widget to display.
  ///
  /// The optional [child] parameter allows you to pass a widget that doesn't
  /// depend on the reactive value. This widget is built once and reused
  /// across rebuilds, improving performance.
  ///
  /// Returns a [ReactiveBuilder] widget that manages the subscription
  /// and rebuilding automatically.
  ///
  /// ## Basic Example
  ///
  /// ```dart
  /// final name = Reactive<String>('World');
  ///
  /// name.listen(
  ///   builder: (context, value, _) => Text('Hello, $value!'),
  /// )
  /// ```
  ///
  /// ## With Child Optimization
  ///
  /// ```dart
  /// final isLoading = Reactive<bool>(false);
  ///
  /// isLoading.listen(
  ///   child: const Text('Status: '), // Built once, reused
  ///   builder: (context, loading, child) => Row(
  ///     children: [
  ///       child!,
  ///       loading
  ///         ? const CircularProgressIndicator()
  ///         : const Icon(Icons.check),
  ///     ],
  ///   ),
  /// )
  /// ```
  ///
  /// ## Nested Listeners
  ///
  /// ```dart
  /// final user = Reactive<User?>(null);
  /// final theme = Reactive<ThemeMode>(ThemeMode.light);
  ///
  /// user.listen(
  ///   builder: (context, user, _) => theme.listen(
  ///     builder: (context, mode, _) => UserCard(
  ///       user: user,
  ///       isDark: mode == ThemeMode.dark,
  ///     ),
  ///   ),
  /// )
  /// ```
  ///
  /// Consider using [MultiReactiveBuilder] for multiple properties instead
  /// of nesting listeners.
  ReactiveBuilder<T> listen({
    required Widget Function(BuildContext context, T value, Widget? child)
    builder,
    Widget? child,
  }) {
    return ReactiveBuilder<T>(property: this, builder: builder, child: child);
  }

  /// Creates a widget that only rebuilds when the selected value changes.
  ///
  /// This is useful for optimizing performance when you only care about
  /// a specific part of a complex value. The widget will only rebuild when
  /// the result of [selector] changes, not when other parts of the value change.
  ///
  /// The [selector] function extracts the value to watch from the full value.
  /// The [builder] function creates the widget using the selected value.
  ///
  /// Returns a [SelectReactiveBuilder] widget.
  ///
  /// ## Basic Example
  ///
  /// ```dart
  /// final user = Reactive<User>(User(
  ///   name: 'John',
  ///   email: 'john@example.com',
  ///   age: 25,
  /// ));
  ///
  /// // Only rebuilds when email changes
  /// user.select(
  ///   selector: (user) => user.email,
  ///   builder: (context, email) => Text('Email: $email'),
  /// )
  /// ```
  ///
  /// ## Selecting Multiple Values
  ///
  /// Use Dart records to select multiple values:
  ///
  /// ```dart
  /// user.select(
  ///   selector: (user) => (user.name, user.age),
  ///   builder: (context, selected) {
  ///     final (name, age) = selected;
  ///     return Text('$name is $age years old');
  ///   },
  /// )
  /// ```
  ///
  /// ## Selecting Computed Values
  ///
  /// Compute derived values in the selector:
  ///
  /// ```dart
  /// final cart = Reactive<Cart>(Cart(items: [...]));
  ///
  /// // Only rebuilds when total changes
  /// cart.select(
  ///   selector: (cart) => cart.items.fold(
  ///     0.0,
  ///     (sum, item) => sum + item.price,
  ///   ),
  ///   builder: (context, total) => Text(
  ///     'Total: \$${total.toStringAsFixed(2)}',
  ///   ),
  /// )
  /// ```
  ///
  /// ## Selecting from Collections
  ///
  /// ```dart
  /// final items = ReactiveList<Item>([...]);
  ///
  /// // Only rebuilds when length changes
  /// items.select(
  ///   selector: (list) => list.length,
  ///   builder: (context, count) => Text('$count items'),
  /// )
  /// ```
  ///
  /// ## Equality Comparison
  ///
  /// The selected values are compared using `==`. For custom objects,
  /// ensure they properly implement `operator ==` and `hashCode`, or
  /// use immutable data classes.
  Widget select<R>({
    required R Function(T value) selector,
    required Widget Function(BuildContext context, R value) builder,
  }) {
    return SelectReactiveBuilder<T, R>(
      property: this,
      selector: selector,
      builder: builder,
    );
  }

  /// Adds diagnostic properties for Flutter DevTools.
  ///
  /// This method automatically exposes the current [value] in the Flutter
  /// DevTools widget inspector, making it easier to debug your application.
  ///
  /// Subclasses can override this method to add additional diagnostic
  /// properties, but should always call `super.debugFillProperties(properties)`.
  ///
  /// Example of adding custom properties in a subclass:
  /// ```dart
  /// @override
  /// void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  ///   super.debugFillProperties(properties);
  ///   properties.add(FlagProperty('isLoading', value: isLoading));
  ///   properties.add(StringProperty('status', status));
  /// }
  /// ```
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('value', value));
  }
}
