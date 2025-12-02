/// A lightweight, powerful MVVM state management library for Flutter.
///
/// MVVM Core provides a clean and intuitive way to separate your application's
/// business logic from the UI layer using the Model-View-ViewModel pattern.
/// Built on Flutter's native primitives with zero external dependencies.
///
/// ## Features
///
/// - **Simple & Intuitive**: Easy to learn, minimal boilerplate
/// - **Reactive Primitives**: [Reactive], [ReactiveList], [ReactiveMap], [ReactiveSet]
/// - **Async Support**: Built-in handling for [Future]s and [Stream]s
/// - **DevTools Integration**: Full Flutter DevTools support out of the box
/// - **Type Safe**: Leverages Dart's type system and sealed classes
/// - **Zero Dependencies**: Only Flutter SDK required
///
/// ## Quick Start
///
/// ### 1. Create a ViewModel
///
/// ```dart
/// class CounterViewModel extends ViewModel {
///   final count = Reactive<int>(0);
///
///   void increment() => count.value++;
///   void decrement() => count.value--;
///
///   @override
///   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
///     super.debugFillProperties(properties);
///     properties.add(DiagnosticsProperty('count', count));
///   }
/// }
/// ```
///
/// ### 2. Create a View
///
/// ```dart
/// class CounterView extends ViewHandler<CounterViewModel> {
///   const CounterView({super.key});
///
///   @override
///   CounterViewModel viewModelFactory() => CounterViewModel();
///
///   @override
///   Widget build(BuildContext context, CounterViewModel vm, Widget? child) {
///     return Scaffold(
///       appBar: AppBar(title: const Text('Counter')),
///       body: Center(
///         child: vm.count.listen(
///           builder: (context, count, _) => Text(
///             '$count',
///             style: Theme.of(context).textTheme.headlineLarge,
///           ),
///         ),
///       ),
///       floatingActionButton: FloatingActionButton(
///         onPressed: vm.increment,
///         child: const Icon(Icons.add),
///       ),
///     );
///   }
/// }
/// ```
///
/// ## Core Concepts
///
/// ### Reactive Properties
///
/// Reactive properties are observable values that automatically notify
/// listeners when they change:
///
/// ```dart
/// // Simple values
/// final name = Reactive<String>('');
/// final isEnabled = Reactive<bool>(true);
///
/// // Update values
/// name.value = 'John';
/// isEnabled.value = false;
///
/// // Transform values
/// name.update((current) => current.toUpperCase());
/// ```
///
/// ### Reactive Collections
///
/// Built-in reactive versions of Dart collections:
///
/// ```dart
/// // Reactive List
/// final items = ReactiveList<String>(['a', 'b', 'c']);
/// items.add('d');
/// items.removeAt(0);
///
/// // Reactive Map
/// final settings = ReactiveMap<String, dynamic>({'theme': 'dark'});
/// settings['language'] = 'en';
///
/// // Reactive Set
/// final tags = ReactiveSet<String>({'flutter', 'dart'});
/// tags.add('mvvm');
/// ```
///
/// ### Async State Management
///
/// Handle async operations with [ReactiveFuture] and [ReactiveStream]:
///
/// ```dart
/// // Future-based
/// final user = ReactiveFuture<User>.idle();
/// await user.run(() => api.fetchUser(id));
///
/// // Stream-based
/// final messages = ReactiveStream<Message>();
/// messages.bind(chatService.messageStream);
/// ```
///
/// ### AsyncState
///
/// All async properties use [AsyncState] for type-safe state handling:
///
/// ```dart
/// user.listenWhen(
///   idle: () => Text('Enter ID to search'),
///   loading: () => CircularProgressIndicator(),
///   data: (user) => UserCard(user: user),
///   error: (e, _) => Text('Error: $e'),
/// )
/// ```
///
/// ## Listening to Changes
///
/// ### Single Property
///
/// ```dart
/// vm.count.listen(
///   builder: (context, count, _) => Text('$count'),
/// )
/// ```
///
/// ### Multiple Properties
///
/// ```dart
/// MultiReactiveBuilder(
///   properties: [vm.firstName, vm.lastName],
///   builder: (context, _) => Text(
///     '${vm.firstName.value} ${vm.lastName.value}',
///   ),
/// )
/// ```
///
/// ### Selective Rebuilds
///
/// ```dart
/// vm.user.select(
///   selector: (user) => user.email,
///   builder: (context, email) => Text(email),
/// )
/// ```
///
/// ## Architecture
///
/// ```
/// ┌─────────────────────────────────────────────────────────────┐
/// │                          View                               │
/// │  (ViewHandler, Widgets)                                     │
/// └─────────────────────────────────────────────────────────────┘
///                              │
///                              │ Observes
///                              ▼
/// ┌─────────────────────────────────────────────────────────────┐
/// │                       ViewModel                             │
/// │  (Reactive, ReactiveFuture, ReactiveStream, Collections)    │
/// └─────────────────────────────────────────────────────────────┘
///                              │
///                              │ Uses
///                              ▼
/// ┌─────────────────────────────────────────────────────────────┐
/// │                         Model                               │
/// │  (Services, Repositories, Data Sources)                     │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Best Practices
///
/// - Keep ViewModels focused on a single feature or screen
/// - Use reactive properties for all state
/// - Check [ViewModel.mounted] before using context in async callbacks
/// - Clean up resources (subscriptions, streams) in [ViewModel.dispose]
/// - Override [debugFillProperties] for better debugging
/// - Use [batch] for multiple collection updates
/// - Use [select] for granular rebuilds
///
/// See the individual class documentation for more details and examples.
library;

// Core
export 'src/core/view_model.dart';
export 'src/core/view_handler.dart';

// Reactive primitives
export 'src/reactive/reactive_property.dart';
export 'src/reactive/reactive.dart';
export 'src/reactive/reactive_future.dart';
export 'src/reactive/reactive_stream.dart';

// Reactive collections
export 'src/reactive/reactive_list.dart';
export 'src/reactive/reactive_map.dart';
export 'src/reactive/reactive_set.dart';

// Async state
export 'src/reactive/async_state.dart';

// Builders
export 'src/reactive/reactive_builder.dart';
export 'src/reactive/select_reactive_builder.dart';
export 'src/reactive/multi_reactive_builder.dart';
