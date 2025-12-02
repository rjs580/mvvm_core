import 'package:flutter/material.dart';
import 'package:mvvm_core/src/core/view_model.dart';
import 'package:mvvm_core/src/devtools/service_extension.dart';

/// A callback type for informing that a navigation pop has been invoked,
/// whether or not it was handled successfully.
///
/// Parameters:
/// - [context]: The [BuildContext] in which the pop was invoked.
/// - [didPop]: A boolean indicating whether or not back navigation succeeded.
/// - [result]: The optional result of the pop action.
typedef PopInvokedContextWithResultCallback<T> =
    void Function(BuildContext context, bool didPop, T? result);

/// A widget that binds a [ViewModel] to its view in the MVVM architecture.
///
/// [ViewHandler] simplifies the connection between views and their corresponding
/// view models by handling lifecycle management, state updates, and navigation
/// control automatically.
///
/// ## Basic Usage
///
/// Create a view by extending [ViewHandler] and providing the ViewModel type:
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
///           builder: (context, count, _) => Text('$count'),
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
/// ## Lifecycle Hooks
///
/// Override [init] and [dispose] to handle setup and cleanup:
///
/// ```dart
/// class UserProfileView extends ViewHandler<UserProfileViewModel> {
///   const UserProfileView({super.key, required this.userId});
///
///   final String userId;
///
///   @override
///   UserProfileViewModel viewModelFactory() => UserProfileViewModel();
///
///   @override
///   void init(UserProfileViewModel vm) {
///     super.init(vm);
///     vm.loadUser(userId);
///   }
///
///   @override
///   void dispose(UserProfileViewModel vm) {
///     vm.cancelPendingRequests();
///     super.dispose(vm);
///   }
///
///   @override
///   Widget build(BuildContext context, UserProfileViewModel vm, Widget? child) {
///     return vm.user.listenWhen(
///       loading: () => const CircularProgressIndicator(),
///       data: (user) => UserProfileContent(user: user),
///       error: (e, _) => Text('Error: $e'),
///     );
///   }
/// }
/// ```
///
/// ## Optimizing Rebuilds with Child
///
/// Use the [child] method to cache widgets that don't depend on the ViewModel:
///
/// ```dart
/// class TodoListView extends ViewHandler<TodoListViewModel> {
///   const TodoListView({super.key});
///
///   @override
///   TodoListViewModel viewModelFactory() => TodoListViewModel();
///
///   @override
///   Widget? child(BuildContext context) {
///     // This widget won't rebuild when the ViewModel changes
///     return const ExpensiveHeader();
///   }
///
///   @override
///   Widget build(BuildContext context, TodoListViewModel vm, Widget? child) {
///     return Column(
///       children: [
///         child!, // Reused across rebuilds
///         Expanded(
///           child: vm.todos.listen(
///             builder: (context, todos, _) => TodoList(todos: todos),
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// ## Navigation Control with PopScope
///
/// Control back navigation behavior using [canPop] and [onPopInvokedWithResult]:
///
/// ```dart
/// class FormView extends ViewHandler<FormViewModel> {
///   const FormView({super.key});
///
///   @override
///   FormViewModel viewModelFactory() => FormViewModel();
///
///   @override
///   bool get canPop => false; // Prevent back navigation
///
///   @override
///   PopInvokedContextWithResultCallback<dynamic>? get onPopInvokedWithResult =>
///     (context, didPop, result) {
///       if (!didPop) {
///         // Show confirmation dialog when user tries to go back
///         showDialog(
///           context: context,
///           builder: (_) => AlertDialog(
///             title: const Text('Discard changes?'),
///             actions: [
///               TextButton(
///                 onPressed: () => Navigator.pop(context),
///                 child: const Text('Cancel'),
///               ),
///               TextButton(
///                 onPressed: () {
///                   Navigator.pop(context); // Close dialog
///                   Navigator.pop(context); // Go back
///                 },
///                 child: const Text('Discard'),
///               ),
///             ],
///           ),
///         );
///       }
///     };
///
///   @override
///   Widget build(BuildContext context, FormViewModel vm, Widget? child) {
///     return Scaffold(
///       body: FormContent(vm: vm),
///     );
///   }
/// }
/// ```
///
/// ## Removing PopScope
///
/// Set [removePopScope] to `true` if you don't need navigation control:
///
/// ```dart
/// class SimpleView extends ViewHandler<SimpleViewModel> {
///   const SimpleView({super.key});
///
///   @override
///   SimpleViewModel viewModelFactory() => SimpleViewModel();
///
///   @override
///   bool get removePopScope => true; // No PopScope wrapper
///
///   @override
///   Widget build(BuildContext context, SimpleViewModel vm, Widget? child) {
///     return const Text('Simple content');
///   }
/// }
/// ```
///
/// See also:
///
/// * [ViewModel], the base class for all view models.
/// * [PopScope], the Flutter widget used for navigation control.
abstract class ViewHandler<T extends ViewModel> extends Widget {
  /// Creates a [ViewHandler].
  const ViewHandler({super.key});

  /// Builds the widget tree for this view.
  ///
  /// Called whenever the [ViewModel] notifies its listeners of changes.
  /// The [child] parameter contains the widget returned by the [child] method,
  /// which can be used for optimization.
  ///
  /// This method must not return null.
  @protected
  Widget build(BuildContext context, T viewModel, Widget? child);

  /// Creates and returns the [ViewModel] instance for this view.
  ///
  /// This factory method is called once when the view is first mounted.
  /// The returned ViewModel will be automatically disposed when the view
  /// is unmounted.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// MyViewModel viewModelFactory() => MyViewModel();
  /// ```
  @protected
  T viewModelFactory();

  /// Returns a widget that should not rebuild when the [ViewModel] changes.
  ///
  /// Use this for expensive widgets that don't depend on the ViewModel's state.
  /// The widget returned here is passed to the [build] method as the `child`
  /// parameter.
  ///
  /// Returns `null` by default, meaning no cached child widget.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget? child(BuildContext context) {
  ///   return const ExpensiveStaticWidget();
  /// }
  /// ```
  @protected
  Widget? child(BuildContext context) => null;

  /// Called after a route pop was handled.
  ///
  /// It's not possible to prevent the pop from happening at the time that
  /// this method is called; the pop has already happened. Use [canPop] to
  /// disable pops in advance.
  ///
  /// This will still be called even when the pop is canceled. A pop is
  /// canceled when the relevant [Route.popDisposition] returns false, such
  /// as when [canPop] is set to false on a [PopScope]. The `didPop` parameter
  /// indicates whether or not the back navigation actually happened
  /// successfully.
  ///
  /// Returns `null` by default, meaning no pop callback.
  @protected
  PopInvokedContextWithResultCallback<dynamic>? get onPopInvokedWithResult =>
      null;

  /// When false, blocks the current route from being popped.
  ///
  /// This includes the root route, where upon popping, the Flutter app would
  /// exit.
  ///
  /// If multiple [PopScope] widgets appear in a route's widget subtree, then
  /// each and every `canPop` must be `true` in order for the route to be
  /// able to pop.
  ///
  /// [Android's predictive back](https://developer.android.com/guide/navigation/predictive-back-gesture)
  /// feature will not animate when this boolean is false.
  ///
  /// Returns `true` by default, allowing normal back navigation.
  @protected
  bool get canPop => true;

  /// Whether to remove the [PopScope] wrapper from the widget tree.
  ///
  /// Set to `true` if you don't need any navigation control and want to
  /// avoid the overhead of the [PopScope] widget.
  ///
  /// Returns `false` by default, meaning [PopScope] is included.
  @protected
  bool get removePopScope => false;

  /// Called when this view is inserted into the widget tree.
  ///
  /// This method is called exactly once for each [ViewHandler] instance,
  /// after the [ViewModel] has been created and initialized.
  ///
  /// Override this method to perform initialization that depends on the
  /// [ViewModel], such as loading initial data or setting up subscriptions.
  ///
  /// Implementations should call `super.init(viewModel)`.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void init(MyViewModel vm) {
  ///   super.init(vm);
  ///   vm.loadInitialData();
  /// }
  /// ```
  @protected
  @mustCallSuper
  void init(T viewModel) {}

  /// Called when this view is permanently removed from the widget tree.
  ///
  /// Override this method to release any resources held by the view,
  /// such as canceling subscriptions or timers that were set up in [init].
  ///
  /// The [ViewModel] will be disposed automatically after this method returns,
  /// so you don't need to call `viewModel.dispose()` manually.
  ///
  /// Implementations should call `super.dispose(viewModel)`.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose(MyViewModel vm) {
  ///   vm.cancelSubscriptions();
  ///   super.dispose(vm);
  /// }
  /// ```
  @protected
  @mustCallSuper
  void dispose(T viewModel) {}

  @override
  Element createElement() => _ViewElement<T>(this);
}

/// The [Element] that manages the lifecycle and rebuilding of a [ViewHandler].
///
/// [_ViewElement] is responsible for:
/// - Creating and storing the [ViewModel] instance
/// - Calling lifecycle methods ([init], [dispose]) at appropriate times
/// - Rebuilding the view when the [ViewModel] notifies listeners
/// - Wrapping the view with [PopScope] for navigation control
///
/// You typically don't interact with this class directly. It's created
/// automatically when a [ViewHandler] is inserted into the widget tree.
///
/// See also:
///
/// * [ViewHandler], the widget that uses this element.
/// * [ComponentElement], the base class for elements that build other widgets.
class _ViewElement<T extends ViewModel> extends ComponentElement {
  /// Creates a [_ViewElement] for the given [ViewHandler].
  _ViewElement(super.widget);

  T? _viewModel;
  bool _initialized = false;
  int _devToolsId = -1;

  @override
  ViewHandler<T> get widget => super.widget as ViewHandler<T>;

  /// The [ViewModel] instance associated with this element.
  ///
  /// The ViewModel is created lazily on first access using
  /// [ViewHandler.viewModelFactory].
  T get viewModel {
    _viewModel ??= widget.viewModelFactory();
    return _viewModel!;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    if (!_initialized) {
      viewModel.init(this);
      widget.init(viewModel);
      _devToolsId = MvvmDevToolsExtension.registerViewModel(viewModel);
      _initialized = true;
    }
  }

  @override
  Widget build() {
    Widget content = ListenableBuilder(
      listenable: viewModel,
      child: widget.child(this),
      builder: (context, child) => widget.build(context, viewModel, child),
    );

    if (!widget.removePopScope) {
      content = PopScope<dynamic>(
        canPop: widget.canPop,
        onPopInvokedWithResult: widget.onPopInvokedWithResult != null
            ? (didPop, result) =>
                  widget.onPopInvokedWithResult?.call(this, didPop, result)
            : null,
        child: content,
      );
    }

    return content;
  }

  @override
  void update(ViewHandler<T> newWidget) {
    super.update(newWidget);
    rebuild();
  }

  @override
  void unmount() {
    widget.dispose(viewModel);
    MvvmDevToolsExtension.unregisterViewModel(_devToolsId);
    _viewModel?.dispose();
    _viewModel = null;
    super.unmount();
  }
}
