import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Base class for all ViewModels in the MVVM architecture.
///
/// [ViewModel] serves as the foundation for managing state and business logic
/// in your application, separating it from the UI layer. It extends
/// [ChangeNotifier] for reactive updates and includes [DiagnosticableTreeMixin]
/// for Flutter DevTools integration.
///
/// ## Basic Usage
///
/// Create a ViewModel by extending this class and defining reactive properties:
///
/// ```dart
/// class CounterViewModel extends ViewModel {
///   final count = Reactive<int>(0);
///
///   void increment() => count.value++;
///   void decrement() => count.value--;
/// }
/// ```
///
/// ## Using with ViewHandler
///
/// ViewModels are typically used with [ViewHandler] to bind to views:
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
///     return vm.count.listen(
///       builder: (context, count, _) => Text('$count'),
///     );
///   }
/// }
/// ```
///
/// ## Async Operations
///
/// Handle async operations using [ReactiveFuture] or [ReactiveStream]:
///
/// ```dart
/// class UserViewModel extends ViewModel {
///   final user = ReactiveFuture<User>.idle();
///   final messages = ReactiveStream<Message>();
///
///   Future<void> loadUser(String id) async {
///     await user.run(() => userRepository.getUser(id));
///   }
///
///   void connectToChat(String roomId) {
///     messages.bind(chatService.getMessages(roomId));
///   }
///
///   @override
///   void dispose() {
///     messages.cancel();
///     super.dispose();
///   }
/// }
/// ```
///
/// ## Accessing BuildContext
///
/// The [context] getter provides access to the [BuildContext] after initialization.
/// Always check [mounted] before using context in async callbacks:
///
/// ```dart
/// class NavigationViewModel extends ViewModel {
///   Future<void> saveAndNavigate() async {
///     await saveData();
///
///     // Check if still mounted before using context
///     if (mounted) {
///       Navigator.of(context).pushNamed('/success');
///     }
///   }
///
///   Future<void> showError(String message) async {
///     if (mounted) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(message)),
///       );
///     }
///   }
/// }
/// ```
///
/// ## Notifying Listeners
///
/// Call [notifyListeners] to trigger UI rebuilds when using non-reactive state:
///
/// ```dart
/// class ManualViewModel extends ViewModel {
///   int _count = 0;
///   int get count => _count;
///
///   void increment() {
///     _count++;
///     notifyListeners(); // Triggers rebuild
///   }
/// }
/// ```
///
/// Note: When using [Reactive], [ReactiveFuture], [ReactiveStream], or other
/// reactive properties, you don't need to call [notifyListeners] manually
/// as they handle notifications internally.
///
/// ## DevTools Integration
///
/// Override [debugFillProperties] to expose properties in Flutter DevTools:
///
/// ```dart
/// class ProfileViewModel extends ViewModel {
///   final name = Reactive<String>('');
///   final email = Reactive<String>('');
///   final isLoading = Reactive<bool>(false);
///
///   @override
///   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
///     super.debugFillProperties(properties);
///     properties.add(DiagnosticsProperty('name', name));
///     properties.add(DiagnosticsProperty('email', email));
///     properties.add(DiagnosticsProperty('isLoading', isLoading));
///   }
/// }
/// ```
///
/// ## Lifecycle
///
/// The ViewModel lifecycle is managed automatically by [ViewHandler]:
///
/// 1. **Creation**: [viewModelFactory] creates the instance
/// 2. **Initialization**: [init] is called with the [BuildContext]
/// 3. **Active**: ViewModel responds to user interactions and updates state
/// 4. **Disposal**: [dispose] is called when the view is removed
///
/// ```dart
/// class LifecycleViewModel extends ViewModel {
///   StreamSubscription? _subscription;
///
///   @override
///   void init(BuildContext context) {
///     super.init(context);
///     // Called when the ViewModel is ready
///     _subscription = someStream.listen(_handleData);
///   }
///
///   void _handleData(data) {
///     // Handle stream data
///   }
///
///   @override
///   void dispose() {
///     // Clean up resources
///     _subscription?.cancel();
///     super.dispose();
///   }
/// }
/// ```
///
/// ## Best Practices
///
/// - Keep ViewModels focused on a single feature or screen
/// - Use reactive properties ([Reactive], [ReactiveFuture], etc.) for state
/// - Always check [mounted] before using [context] in async operations
/// - Clean up resources (subscriptions, timers) in [dispose]
/// - Override [debugFillProperties] for better debugging experience
///
/// See also:
///
/// * [ViewHandler], the widget that binds ViewModels to views.
/// * [Reactive], for simple reactive values.
/// * [ReactiveFuture], for async operations with Futures.
/// * [ReactiveStream], for reactive stream handling.
/// * [ReactiveList], [ReactiveMap], [ReactiveSet] for reactive collections.
class ViewModel extends ChangeNotifier with DiagnosticableTreeMixin {
  BuildContext? _context;
  bool _disposed = false;

  /// Called when the ViewModel is initialized and ready to use.
  ///
  /// This method is called automatically by [ViewHandler] after the ViewModel
  /// is created. The [context] parameter provides access to the widget's
  /// [BuildContext].
  ///
  /// Override this method to perform initialization tasks such as:
  /// - Loading initial data
  /// - Setting up stream subscriptions
  /// - Initializing dependencies
  ///
  /// Always call `super.init(context)` at the beginning of your override.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void init(BuildContext context) {
  ///   super.init(context);
  ///   loadUserData();
  /// }
  /// ```
  @mustCallSuper
  void init(BuildContext context) {
    _context = context;
  }

  /// Whether this ViewModel is currently mounted and active.
  ///
  /// Returns `true` if [init] has been called and [dispose] has not been called.
  /// Use this to check if it's safe to access [context] or perform UI operations.
  ///
  /// Example:
  /// ```dart
  /// Future<void> loadData() async {
  ///   final data = await fetchData();
  ///   if (mounted) {
  ///     // Safe to update UI or use context
  ///     showSnackBar(context, 'Data loaded');
  ///   }
  /// }
  /// ```
  bool get mounted => _context != null;

  /// The [BuildContext] associated with this ViewModel.
  ///
  /// This is available after [init] has been called and before [dispose].
  /// Accessing this property when the ViewModel is not mounted will throw
  /// a [FlutterError] in debug mode.
  ///
  /// Always check [mounted] before accessing [context] in async callbacks
  /// to avoid errors when the ViewModel has been disposed.
  ///
  /// Example:
  /// ```dart
  /// void navigateToDetails() {
  ///   Navigator.of(context).pushNamed('/details');
  /// }
  ///
  /// Future<void> loadAndShow() async {
  ///   final data = await loadData();
  ///   if (mounted) {
  ///     ScaffoldMessenger.of(context).showSnackBar(
  ///       SnackBar(content: Text('Loaded: $data')),
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// Throws a [FlutterError] if accessed when the ViewModel is not mounted.
  BuildContext get context {
    assert(() {
      if (_context == null) {
        throw FlutterError(
          'This ViewModel has been disposed or not initialized, so it no longer has a context.\n'
          'Consider canceling any active work during "dispose" or using the "mounted" getter to determine if the ViewModel is still active.',
        );
      }
      return true;
    }());
    return _context!;
  }

  /// Notifies all registered listeners that the state has changed.
  ///
  /// This method is safe to call even after the ViewModel has been disposed;
  /// it will simply do nothing in that case.
  ///
  /// When using reactive properties like [Reactive], [ReactiveFuture], etc.,
  /// you typically don't need to call this method manually as they handle
  /// notifications internally.
  ///
  /// Example:
  /// ```dart
  /// int _count = 0;
  /// int get count => _count;
  ///
  /// void increment() {
  ///   _count++;
  ///   notifyListeners(); // Manually trigger rebuild
  /// }
  /// ```
  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  /// Adds diagnostic properties for Flutter DevTools.
  ///
  /// Override this method to expose your ViewModel's properties in the
  /// Flutter DevTools widget inspector.
  ///
  /// Always call `super.debugFillProperties(properties)` to include
  /// the base properties ([mounted], [disposed]).
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  ///   super.debugFillProperties(properties);
  ///   properties.add(DiagnosticsProperty('count', count));
  ///   properties.add(DiagnosticsProperty('user', user));
  ///   properties.add(StringProperty('status', status));
  /// }
  /// ```
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty(
        'mounted',
        value: mounted,
        ifTrue: 'mounted',
        ifFalse: 'not mounted',
      ),
    );
    properties.add(
      FlagProperty('disposed', value: _disposed, ifTrue: 'disposed'),
    );
  }

  /// Disposes of this ViewModel and releases its resources.
  ///
  /// This method is called automatically by [ViewHandler] when the view is
  /// removed from the widget tree. After this method is called:
  /// - [mounted] will return `false`
  /// - [context] will throw if accessed
  /// - [notifyListeners] will do nothing
  ///
  /// Override this method to clean up resources such as:
  /// - Canceling stream subscriptions
  /// - Stopping timers
  /// - Closing controllers
  ///
  /// Always call `super.dispose()` at the end of your override.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   _subscription?.cancel();
  ///   _timer?.cancel();
  ///   _controller.close();
  ///   super.dispose();
  /// }
  /// ```
  @override
  void dispose() {
    _disposed = true;
    _context = null;
    super.dispose();
  }
}
