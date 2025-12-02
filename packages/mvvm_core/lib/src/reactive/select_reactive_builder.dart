import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that only rebuilds when the selected value changes.
///
/// This is useful for optimizing rebuilds when you only care about
/// a specific part of the value, avoiding unnecessary widget rebuilds.
///
/// ## Basic Usage
///
/// Select a single property from a complex object:
///
/// ```dart
/// final user = Reactive<User>(User(name: 'John', email: 'john@example.com'));
///
/// // Only rebuilds when email changes, ignores name changes
/// SelectReactiveBuilder<User, String>(
///   property: user,
///   selector: (user) => user.email,
///   builder: (context, email) => Text('Email: $email'),
/// )
/// ```
///
/// ## Using the Extension Method
///
/// A more concise way using [ReactiveProperty.select]:
///
/// ```dart
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
///     return Text('$name, $age years old');
///   },
/// )
/// ```
///
/// ## Selecting Computed Values
///
/// You can compute derived values in the selector:
///
/// ```dart
/// final cart = Reactive<Cart>(Cart(items: [...]));
///
/// cart.select(
///   selector: (cart) => cart.items.fold(0.0, (sum, item) => sum + item.price),
///   builder: (context, total) => Text('Total: \$${total.toStringAsFixed(2)}'),
/// )
/// ```
///
/// ## Selecting from Collections
///
/// Useful for reacting to specific changes in collections:
///
/// ```dart
/// final items = ReactiveList<Item>([...]);
///
/// SelectReactiveBuilder<List<Item>, int>(
///   property: items,
///   selector: (list) => list.length,
///   builder: (context, count) => Text('$count items'),
/// )
/// ```
///
/// ## Comparison with [ReactiveBuilder]
///
/// | Feature | ReactiveBuilder | SelectReactiveBuilder |
/// |---------|-----------------|----------------------|
/// | Rebuilds on | Any change | Selected value change only |
/// | Performance | Standard | Optimized for partial updates |
/// | Use case | Simple values | Complex objects, collections |
///
/// See also:
///
/// * [ReactiveProperty.select], the extension method for easier usage.
/// * [ReactiveBuilder], for listening to all changes.
/// * [MultiReactiveBuilder], for listening to multiple properties.
class SelectReactiveBuilder<T, R> extends StatefulWidget {
  /// Creates a [SelectReactiveBuilder].
  ///
  /// The [property], [selector], and [builder] arguments must not be null.
  const SelectReactiveBuilder({
    super.key,
    required this.property,
    required this.selector,
    required this.builder,
  });

  /// The reactive property to listen to.
  final ValueListenable<T> property;

  /// A function that extracts the value to watch from the property's value.
  ///
  /// The widget only rebuilds when the result of this function changes.
  final R Function(T value) selector;

  /// A function that builds the widget based on the selected value.
  final Widget Function(BuildContext context, R value) builder;

  @override
  State<SelectReactiveBuilder<T, R>> createState() =>
      _SelectReactiveBuilderState<T, R>();
}

class _SelectReactiveBuilderState<T, R>
    extends State<SelectReactiveBuilder<T, R>> {
  late R _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selector(widget.property.value);
    widget.property.addListener(_onPropertyChanged);
  }

  @override
  void didUpdateWidget(covariant SelectReactiveBuilder<T, R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property != widget.property) {
      oldWidget.property.removeListener(_onPropertyChanged);
      widget.property.addListener(_onPropertyChanged);
      _selectedValue = widget.selector(widget.property.value);
    }
  }

  void _onPropertyChanged() {
    final newSelectedValue = widget.selector(widget.property.value);
    if (_selectedValue != newSelectedValue) {
      setState(() {
        _selectedValue = newSelectedValue;
      });
    }
  }

  @override
  void dispose() {
    widget.property.removeListener(_onPropertyChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selectedValue);
  }
}
