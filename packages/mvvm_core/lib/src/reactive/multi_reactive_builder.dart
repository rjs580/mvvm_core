import 'package:flutter/material.dart';

/// A widget that rebuilds when any of multiple reactive properties change.
///
/// [MultiReactiveBuilder] listens to a list of [Listenable] objects (such as
/// [Reactive], [ReactiveFuture], [ReactiveList], etc.) and rebuilds whenever
/// any of them notifies its listeners.
///
/// This is more efficient than nesting multiple [ReactiveBuilder] widgets
/// when you need to respond to changes in several properties.
///
/// ## Basic Usage
///
/// ```dart
/// class ProfileViewModel extends ViewModel {
///   final firstName = Reactive<String>('');
///   final lastName = Reactive<String>('');
///   final age = Reactive<int>(0);
/// }
///
/// // In your view:
/// MultiReactiveBuilder(
///   properties: [vm.firstName, vm.lastName, vm.age],
///   builder: (context, child) => Text(
///     '${vm.firstName.value} ${vm.lastName.value}, ${vm.age.value} years old',
///   ),
/// )
/// ```
///
/// ## Comparison with Nested Builders
///
/// Instead of nesting builders:
///
/// ```dart
/// // ❌ Verbose and hard to read
/// vm.firstName.listen(
///   builder: (context, firstName, _) => vm.lastName.listen(
///     builder: (context, lastName, _) => vm.age.listen(
///       builder: (context, age, _) => Text('$firstName $lastName, $age'),
///     ),
///   ),
/// )
/// ```
///
/// Use [MultiReactiveBuilder]:
///
/// ```dart
/// // ✅ Clean and readable
/// MultiReactiveBuilder(
///   properties: [vm.firstName, vm.lastName, vm.age],
///   builder: (context, _) => Text(
///     '${vm.firstName.value} ${vm.lastName.value}, ${vm.age.value}',
///   ),
/// )
/// ```
///
/// ## Optimizing with Child
///
/// Use the [child] parameter for widgets that don't depend on the properties:
///
/// ```dart
/// MultiReactiveBuilder(
///   properties: [vm.items, vm.selectedIndex],
///   child: const ListHeader(), // Won't rebuild
///   builder: (context, child) => Column(
///     children: [
///       child!, // Reused across rebuilds
///       ListView.builder(
///         itemCount: vm.items.length,
///         itemBuilder: (_, i) => ListTile(
///           title: Text(vm.items[i]),
///           selected: i == vm.selectedIndex.value,
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ## With Different Property Types
///
/// Works with any [Listenable], including all reactive types:
///
/// ```dart
/// class DashboardViewModel extends ViewModel {
///   final user = ReactiveFuture<User>.idle();
///   final notifications = ReactiveList<Notification>();
///   final settings = ReactiveMap<String, dynamic>();
///   final isOnline = Reactive<bool>(true);
/// }
///
/// MultiReactiveBuilder(
///   properties: [
///     vm.user,
///     vm.notifications,
///     vm.settings,
///     vm.isOnline,
///   ],
///   builder: (context, _) => DashboardContent(
///     user: vm.user.data,
///     notificationCount: vm.notifications.length,
///     theme: vm.settings['theme'],
///     isOnline: vm.isOnline.value,
///   ),
/// )
/// ```
///
/// ## Conditional Rebuilds
///
/// For more granular control over when to rebuild based on specific
/// property changes, consider using [SelectReactiveBuilder] or
/// [ReactiveProperty.select] instead.
///
/// ## Performance Considerations
///
/// - The widget rebuilds when **any** property in the list changes
/// - Use [child] to cache widgets that don't need rebuilding
/// - For large lists of properties, consider grouping related state
///   into a single object to reduce the number of notifications
///
/// See also:
///
/// * [ReactiveBuilder], for listening to a single property.
/// * [SelectReactiveBuilder], for selective rebuilds based on derived values.
/// * [Listenable.merge], the underlying mechanism for combining listenables.
class MultiReactiveBuilder extends StatelessWidget {
  /// Creates a [MultiReactiveBuilder].
  ///
  /// The [properties] list must not be empty and contains the [Listenable]
  /// objects to observe. The [builder] function is called whenever any
  /// property notifies its listeners.
  ///
  /// The optional [child] parameter allows passing a widget that doesn't
  /// depend on the properties, which will be cached and reused across rebuilds.
  const MultiReactiveBuilder({
    super.key,
    required this.properties,
    required this.builder,
    this.child,
  });

  /// The list of [Listenable] objects to observe.
  ///
  /// The widget rebuilds whenever any of these properties notify their
  /// listeners. This can include [Reactive], [ReactiveFuture], [ReactiveStream],
  /// [ReactiveList], [ReactiveMap], [ReactiveSet], or any other [Listenable].
  ///
  /// Example:
  /// ```dart
  /// properties: [vm.name, vm.email, vm.isLoading]
  /// ```
  final List<Listenable> properties;

  /// Called whenever any property in [properties] changes.
  ///
  /// The [child] parameter contains the widget passed to the constructor's
  /// [child] parameter, allowing for optimization of static content.
  ///
  /// Access the current values of properties directly in the builder:
  /// ```dart
  /// builder: (context, child) => Text('${vm.count.value}'),
  /// ```
  final Widget Function(BuildContext context, Widget? child) builder;

  /// A widget that doesn't depend on the reactive properties.
  ///
  /// This widget is built once and passed to the [builder] function on
  /// each rebuild. Use this for expensive widgets or static content that
  /// shouldn't rebuild when properties change.
  ///
  /// Example:
  /// ```dart
  /// child: const ExpensiveWidget(),
  /// builder: (context, child) => Column(
  ///   children: [
  ///     child!, // Reused, won't rebuild
  ///     Text('${vm.count.value}'), // Rebuilds
  ///   ],
  /// ),
  /// ```
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(properties),
      builder: (context, child) => builder(context, child),
      child: child,
    );
  }
}
