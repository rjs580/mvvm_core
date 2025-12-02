import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mvvm_core/src/reactive/async_state.dart';
import 'package:mvvm_core/src/reactive/reactive_property.dart';

/// A reactive property that manages the state of a [Future]-based async operation.
///
/// [ReactiveFuture] wraps async operations and automatically manages loading,
/// success, and error states through [AsyncState]. It provides a clean way to
/// handle async data fetching in your ViewModels while keeping the UI reactive.
///
/// ## Basic Usage
///
/// ```dart
/// class UserViewModel extends ViewModel {
///   final user = ReactiveFuture<User>();
///
///   Future<void> loadUser(String id) async {
///     await user.run(() => userRepository.getUser(id));
///   }
/// }
///
/// // In the view:
/// vm.user.listenWhen(
///   loading: () => const CircularProgressIndicator(),
///   data: (user) => Text('Hello, ${user.name}'),
///   error: (e, _) => Text('Error: $e'),
/// )
/// ```
///
/// ## Starting in Idle State
///
/// Use [ReactiveFuture.idle] when you want to show a different UI before
/// the operation starts (e.g., search functionality):
///
/// ```dart
/// class SearchViewModel extends ViewModel {
///   final results = ReactiveFuture<List<Item>>.idle();
///
///   Future<void> search(String query) async {
///     if (query.isEmpty) {
///       results.reset(); // Back to idle
///       return;
///     }
///     await results.run(() => api.search(query));
///   }
/// }
///
/// // In the view:
/// vm.results.listenWhen(
///   idle: () => const Text('Enter a search term'),
///   loading: () => const CircularProgressIndicator(),
///   data: (items) => ItemList(items: items),
///   error: (e, _) => Text('Search failed: $e'),
/// )
/// ```
///
/// ## Accessing Data Directly
///
/// Use the [data] getter when you need the current data outside of the UI:
///
/// ```dart
/// void processCurrentUser() {
///   final currentUser = user.data;
///   if (currentUser != null) {
///     analytics.logUser(currentUser);
///   }
/// }
/// ```
///
/// ## Handling the Result
///
/// The [run] method returns the result, allowing you to chain operations:
///
/// ```dart
/// Future<void> loadAndProcess() async {
///   final user = await this.user.run(() => api.fetchUser(id));
///   if (user != null) {
///     // Success - do additional processing
///     await loadUserPosts(user.id);
///   }
///   // user is null if an error occurred
/// }
/// ```
///
/// ## Manual State Control
///
/// Set state manually when needed:
///
/// ```dart
/// // Pre-populate with cached data
/// user.setData(cachedUser);
///
/// // Set error state from external source
/// user.setError(CustomException('Session expired'));
///
/// // Reset to idle state
/// user.reset();
/// ```
///
/// ## Refresh with Previous Data
///
/// When [run] is called, previous data is preserved during loading,
/// enabling pull-to-refresh patterns:
///
/// ```dart
/// vm.user.listenWhen(
///   loading: () {
///     // Show loading indicator
///     // Previous data is available via vm.user.data
///     final previous = vm.user.data;
///     if (previous != null) {
///       return RefreshingUserCard(user: previous);
///     }
///     return const CircularProgressIndicator();
///   },
///   data: (user) => UserCard(user: user),
///   error: (e, _) => Text('Error: $e'),
/// )
/// ```
///
/// ## Using with Pattern Matching
///
/// Access the full [AsyncState] for more control:
///
/// ```dart
/// vm.user.listen(
///   builder: (context, state, _) => state.whenWithPrevious(
///     idle: () => const EmptyState(),
///     loading: (previous) => Stack(
///       children: [
///         if (previous != null) UserCard(user: previous),
///         const LoadingOverlay(),
///       ],
///     ),
///     data: (user) => UserCard(user: user),
///     error: (e, s, previous) => Column(
///       children: [
///         Text('Error: $e'),
///         if (previous != null) UserCard(user: previous),
///         RetryButton(onPressed: vm.loadUser),
///       ],
///     ),
///   ),
/// )
/// ```
///
/// ## State Transitions
///
/// ```
/// ┌─────────────────────────────────────────────────────────┐
/// │                                                         │
/// │  ┌──────────┐     run()      ┌───────────┐             │
/// │  │  Idle    │ ─────────────► │  Loading  │             │
/// │  └──────────┘                └───────────┘             │
/// │       ▲                        │       │               │
/// │       │                        │       │               │
/// │    reset()              success│       │error          │
/// │       │                        │       │               │
/// │       │                        ▼       ▼               │
/// │  ┌────┴─────────────────────────┐  ┌─────────┐        │
/// │  │          Data                │  │  Error  │        │
/// │  └──────────────────────────────┘  └─────────┘        │
/// │       ▲                                   │            │
/// │       │            run()                  │            │
/// │       └───────────────────────────────────┘            │
/// │                                                         │
/// └─────────────────────────────────────────────────────────┘
/// ```
///
/// See also:
///
/// * [AsyncState], the sealed class representing all possible states.
/// * [ReactiveStream], for Stream-based async operations.
/// * [Reactive], for simple synchronous values.
class ReactiveFuture<T> extends ReactiveProperty<AsyncState<T>> {
  /// Creates a [ReactiveFuture] that starts in the loading state.
  ///
  /// Use this constructor when the async operation should start immediately
  /// or when you want to show a loading indicator by default.
  ///
  /// Example:
  /// ```dart
  /// class UserViewModel extends ViewModel {
  ///   final user = ReactiveFuture<User>();
  ///
  ///   @override
  ///   void init(BuildContext context) {
  ///     super.init(context);
  ///     loadUser(); // Start loading immediately
  ///   }
  ///
  ///   Future<void> loadUser() => user.run(() => api.fetchUser());
  /// }
  /// ```
  ReactiveFuture() : _state = const AsyncLoading();

  /// Creates a [ReactiveFuture] that starts in the idle state.
  ///
  /// Use this constructor when the async operation should not start
  /// automatically and you want to show a different UI before the
  /// user triggers the operation.
  ///
  /// Example:
  /// ```dart
  /// // Search that waits for user input
  /// final searchResults = ReactiveFuture<List<Item>>.idle();
  ///
  /// // Form submission that waits for button press
  /// final submission = ReactiveFuture<Response>.idle();
  /// ```
  ReactiveFuture.idle() : _state = const AsyncIdle();

  AsyncState<T> _state;

  /// Tracks the current execution ID for handling rapid successive calls.
  ///
  /// Each call to [run] increments this counter. When an async operation
  /// completes, it checks if its ID matches the current [_runId]. If not,
  /// the result is discarded because a newer operation was started.
  ///
  /// This implements a "last call wins" pattern, which is essential for:
  /// - Search-as-you-type (only show results for the latest query)
  /// - Rapid refresh (ignore stale data from earlier refreshes)
  /// - Debounced operations (prevent race conditions)
  ///
  /// Note: Overflow is not a concern. Even at 1000 calls/second, it would
  /// take over 285,000 years to overflow on web (the more limited platform).
  ///
  /// Example scenario:
  /// ```
  /// run() called -> _runId = 1 -> starts slow API call
  /// run() called -> _runId = 2 -> starts fast API call
  /// Fast call completes -> _runId == 2 ✓ -> state updated
  /// Slow call completes -> _runId != 1 ✗ -> result discarded
  /// ```
  int _runId = 0;

  /// The current [AsyncState] of this reactive future.
  ///
  /// Use this to access the full state object for pattern matching
  /// with [AsyncState.when], [AsyncState.maybeWhen], or
  /// [AsyncState.whenWithPrevious].
  ///
  /// Example:
  /// ```dart
  /// if (user.value.isLoading) {
  ///   showLoadingIndicator();
  /// }
  /// ```
  @override
  AsyncState<T> get value => _state;

  /// The current data if available, otherwise `null`.
  ///
  /// This is a convenience getter that returns:
  /// - The data if in [AsyncData] state
  /// - The previous data if in [AsyncLoading] or [AsyncError] state
  /// - `null` if in [AsyncIdle] state or no data has been loaded
  ///
  /// Example:
  /// ```dart
  /// void logCurrentUser() {
  ///   final currentUser = user.data;
  ///   if (currentUser != null) {
  ///     print('Current user: ${currentUser.name}');
  ///   }
  /// }
  /// ```
  T? get data => _state.dataOrNull;

  /// Executes an async operation and updates the state accordingly.
  ///
  /// The state transitions are:
  /// 1. Immediately sets state to [AsyncLoading] (preserving previous data)
  /// 2. Awaits the [futureFactory] function
  /// 3. On success: sets state to [AsyncData] with the result
  /// 4. On error: sets state to [AsyncError] with error and stack trace
  ///
  /// Returns the result on success, or `null` if an error occurred.
  ///
  /// ## Basic Example
  ///
  /// ```dart
  /// Future<void> loadUser(String id) async {
  ///   await user.run(() => api.fetchUser(id));
  /// }
  /// ```
  ///
  /// ## Using the Return Value
  ///
  /// ```dart
  /// Future<void> loadAndNavigate(String id) async {
  ///   final result = await user.run(() => api.fetchUser(id));
  ///   if (result != null && mounted) {
  ///     Navigator.of(context).pushNamed('/profile');
  ///   }
  /// }
  /// ```
  ///
  /// ## Chained Operations
  ///
  /// ```dart
  /// Future<void> loadUserWithPosts(String id) async {
  ///   final user = await this.user.run(() => api.fetchUser(id));
  ///   if (user != null) {
  ///     await posts.run(() => api.fetchPosts(user.id));
  ///   }
  /// }
  /// ```
  ///
  /// ## Previous Data During Loading
  ///
  /// When called while data exists, the previous data is preserved
  /// in the loading state, enabling refresh patterns:
  ///
  /// ```dart
  /// // First load
  /// await user.run(() => api.fetchUser(id));
  /// // user.data is now available
  ///
  /// // Refresh - previous data preserved during loading
  /// await user.run(() => api.fetchUser(id));
  /// // During loading: user.data still returns previous value
  /// ```
  Future<T?> run(Future<T> Function() futureFactory) async {
    final currentRunId = ++_runId;

    final previousData = _state.dataOrNull;
    _state = AsyncLoading<T>(previousData);
    notifyListeners();

    try {
      final result = await futureFactory();

      // Only update if this is still the current run
      if (currentRunId == _runId) {
        _state = AsyncData<T>(result);
        notifyListeners();
        return result;
      }

      return null;
    } catch (e, s) {
      // Only update if this is still the current run
      if (currentRunId == _runId) {
        _state = AsyncError<T>(e, s, previousData);
        notifyListeners();
      }

      return null;
    }
  }

  /// Resets the state to [AsyncIdle].
  ///
  /// Use this to clear the current state and return to the initial
  /// idle state, typically used for:
  /// - Clearing search results
  /// - Resetting forms
  /// - Clearing selections
  ///
  /// Example:
  /// ```dart
  /// void clearSearch() {
  ///   searchQuery.value = '';
  ///   searchResults.reset();
  /// }
  /// ```
  void reset() {
    _state = const AsyncIdle();
    notifyListeners();
  }

  /// Manually sets the state to [AsyncData] with the given data.
  ///
  /// Use this to:
  /// - Pre-populate with cached data
  /// - Set data from a different source
  /// - Update data without running an async operation
  ///
  /// Example:
  /// ```dart
  /// // Pre-populate from cache
  /// final cached = await cache.getUser(id);
  /// if (cached != null) {
  ///   user.setData(cached);
  /// }
  ///
  /// // Then optionally refresh from network
  /// await user.run(() => api.fetchUser(id));
  /// ```
  void setData(T data) {
    _state = AsyncData<T>(data);
    notifyListeners();
  }

  /// Manually sets the state to [AsyncError].
  ///
  /// Use this to:
  /// - Set error state from external validation
  /// - Handle errors from other sources
  /// - Simulate errors for testing
  ///
  /// The [stackTrace] defaults to [StackTrace.current] if not provided.
  /// Previous data is preserved in the error state.
  ///
  /// Example:
  /// ```dart
  /// void validateAndSubmit() {
  ///   if (!isValid) {
  ///     submission.setError(ValidationException('Invalid input'));
  ///     return;
  ///   }
  ///   submission.run(() => api.submit(data));
  /// }
  /// ```
  void setError(Object error, [StackTrace? stackTrace]) {
    _state = AsyncError<T>(error, stackTrace ?? StackTrace.current, data);
    notifyListeners();
  }

  /// Creates a widget that handles all async states with a clean API.
  ///
  /// This is a convenience method that combines [listen] with [AsyncState.when]
  /// for a cleaner syntax when building UI based on async state.
  ///
  /// ## Parameters
  ///
  /// - [idle]: Widget to show when operation hasn't started (defaults to [loading])
  /// - [loading]: Widget to show during loading (required)
  /// - [data]: Widget builder for success state (required)
  /// - [error]: Widget builder for error state (required)
  /// - [child]: Optional cached widget passed to the builder
  ///
  /// ## Basic Example
  ///
  /// ```dart
  /// vm.user.listenWhen(
  ///   loading: () => const CircularProgressIndicator(),
  ///   data: (user) => UserCard(user: user),
  ///   error: (e, _) => Text('Error: $e'),
  /// )
  /// ```
  ///
  /// ## With Idle State
  ///
  /// ```dart
  /// vm.searchResults.listenWhen(
  ///   idle: () => const Text('Enter a search term to begin'),
  ///   loading: () => const CircularProgressIndicator(),
  ///   data: (results) => ResultsList(results: results),
  ///   error: (e, s) => ErrorWidget(error: e, stackTrace: s),
  /// )
  /// ```
  ///
  /// ## With Child Optimization
  ///
  /// ```dart
  /// vm.user.listenWhen(
  ///   child: const AppHeader(), // Won't rebuild
  ///   loading: () => const LoadingScreen(),
  ///   data: (user) => UserDashboard(user: user),
  ///   error: (e, _) => ErrorScreen(error: e),
  /// )
  /// ```
  ///
  /// ## For More Control
  ///
  /// Use [listen] with [AsyncState.whenWithPrevious] for access to
  /// previous data during loading/error states:
  ///
  /// ```dart
  /// vm.user.listen(
  ///   builder: (context, state, _) => state.whenWithPrevious(
  ///     idle: () => const EmptyState(),
  ///     loading: (previous) => LoadingWithPreview(data: previous),
  ///     data: (user) => UserCard(user: user),
  ///     error: (e, s, previous) => ErrorWithFallback(
  ///       error: e,
  ///       fallbackData: previous,
  ///     ),
  ///   ),
  /// )
  /// ```
  Widget listenWhen({
    Widget Function()? idle,
    required Widget Function() loading,
    required Widget Function(T data) data,
    required Widget Function(Object error, StackTrace stackTrace) error,
    Widget? child,
  }) {
    return listen(
      child: child,
      builder: (context, state, child) => state.when(
        idle: idle ?? loading,
        loading: loading,
        data: data,
        error: error,
      ),
    );
  }
}
