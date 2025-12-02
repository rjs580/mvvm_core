/// Represents the state of an asynchronous operation.
///
/// [AsyncState] is a sealed class that models all possible states of an async
/// operation, enabling exhaustive pattern matching and type-safe state handling.
/// It is used by [ReactiveFuture] and [ReactiveStream] to represent their
/// current state.
///
/// ## States
///
/// | State | Description |
/// |-------|-------------|
/// | [AsyncIdle] | Operation has not started yet |
/// | [AsyncLoading] | Operation is in progress |
/// | [AsyncData] | Operation completed successfully with data |
/// | [AsyncError] | Operation failed with an error |
/// | [StreamDone] | Stream has completed (for [ReactiveStream] only) |
///
/// ## Basic Usage
///
/// Use the [when] method for exhaustive pattern matching:
///
/// ```dart
/// final state = AsyncData<String>('Hello');
///
/// final widget = state.when(
///   idle: () => const Text('Not started'),
///   loading: () => const CircularProgressIndicator(),
///   data: (value) => Text(value),
///   error: (e, s) => Text('Error: $e'),
/// );
/// ```
///
/// ## State Checking
///
/// Use the convenience getters to check the current state:
///
/// ```dart
/// if (state.isLoading) {
///   showLoadingIndicator();
/// }
///
/// if (state.hasData) {
///   processData(state.dataOrNull!);
/// }
///
/// if (state.hasError) {
///   logError(state);
/// }
/// ```
///
/// ## Accessing Data
///
/// Use [dataOrNull] to safely access data in any state:
///
/// ```dart
/// // Returns data if available, null otherwise
/// final data = state.dataOrNull;
///
/// // Works in loading/error states too (returns previous data)
/// final previousData = loadingState.dataOrNull;
/// ```
///
/// ## With ReactiveFuture
///
/// ```dart
/// class UserViewModel extends ViewModel {
///   final user = ReactiveFuture<User>.idle();
///
///   Future<void> loadUser(String id) async {
///     await user.run(() => api.fetchUser(id));
///   }
/// }
///
/// // In the view:
/// vm.user.listenWhen(
///   idle: () => const Text('Enter ID to search'),
///   loading: () => const CircularProgressIndicator(),
///   data: (user) => UserCard(user: user),
///   error: (e, _) => Text('Failed: $e'),
/// )
/// ```
///
/// ## With ReactiveStream
///
/// ```dart
/// class ChatViewModel extends ViewModel {
///   final messages = ReactiveStream<Message>();
///
///   void connect(String roomId) {
///     messages.bind(chatService.getMessages(roomId));
///   }
/// }
///
/// // In the view:
/// vm.messages.listenWhen(
///   loading: () => const Text('Connecting...'),
///   data: (msg) => MessageBubble(msg),
///   error: (e, _) => const Text('Disconnected'),
///   done: (_) => const Text('Chat ended'),
/// )
/// ```
///
/// ## Previous Data Access
///
/// During loading or error states, the previous successful data is preserved.
/// Use [whenWithPrevious] to access it:
///
/// ```dart
/// state.whenWithPrevious(
///   idle: () => const Text('No data'),
///   loading: (previous) => Column(
///     children: [
///       const CircularProgressIndicator(),
///       if (previous != null) Text('Last: $previous'),
///     ],
///   ),
///   data: (data) => Text('Current: $data'),
///   error: (e, s, previous) => Column(
///     children: [
///       Text('Error: $e'),
///       if (previous != null) Text('Showing cached: $previous'),
///     ],
///   ),
/// )
/// ```
///
/// ## Partial Matching
///
/// Use [maybeWhen] when you only care about specific states:
///
/// ```dart
/// final message = state.maybeWhen(
///   error: (e, _) => 'Error: $e',
///   orElse: () => 'OK',
/// );
/// ```
///
/// See also:
///
/// * [ReactiveFuture], which uses this for Future-based state.
/// * [ReactiveStream], which uses this for Stream-based state.
/// * [AsyncIdle], the initial/not-started state.
/// * [AsyncLoading], the in-progress state.
/// * [AsyncData], the success state.
/// * [AsyncError], the error state.
/// * [StreamDone], the stream completion state.
sealed class AsyncState<T> {
  /// Creates an [AsyncState].
  const AsyncState();

  /// Whether the async operation has not started yet.
  ///
  /// Returns `true` if this is an [AsyncIdle] state.
  ///
  /// Example:
  /// ```dart
  /// final state = AsyncIdle<String>();
  /// print(state.isIdle); // true
  /// ```
  bool get isIdle => this is AsyncIdle<T>;

  /// Whether the async operation is currently loading.
  ///
  /// Returns `true` if this is an [AsyncLoading] state.
  ///
  /// Example:
  /// ```dart
  /// final state = AsyncLoading<String>();
  /// print(state.isLoading); // true
  /// ```
  bool get isLoading => this is AsyncLoading<T>;

  /// Whether the async operation completed successfully with data.
  ///
  /// Returns `true` if this is an [AsyncData] state.
  ///
  /// Example:
  /// ```dart
  /// final state = AsyncData<String>('Hello');
  /// print(state.hasData); // true
  /// ```
  bool get hasData => this is AsyncData<T>;

  /// Whether the async operation completed with an error.
  ///
  /// Returns `true` if this is an [AsyncError] state.
  ///
  /// Example:
  /// ```dart
  /// final state = AsyncError<String>(Exception('Failed'), StackTrace.current);
  /// print(state.hasError); // true
  /// ```
  bool get hasError => this is AsyncError<T>;

  /// Whether a stream has completed.
  ///
  /// Returns `true` if this is a [StreamDone] state. This state is only
  /// used by [ReactiveStream] when the underlying stream closes.
  ///
  /// Example:
  /// ```dart
  /// final state = StreamDone<String>('last value');
  /// print(state.isDone); // true
  /// ```
  bool get isDone => this is StreamDone<T>;

  /// Returns the data if available, otherwise `null`.
  ///
  /// This getter provides safe access to data across all states:
  /// - [AsyncIdle]: Returns `null`
  /// - [AsyncLoading]: Returns the previous data if available
  /// - [AsyncData]: Returns the current data
  /// - [AsyncError]: Returns the previous data if available
  /// - [StreamDone]: Returns the last data if available
  ///
  /// Example:
  /// ```dart
  /// final loadingWithPrevious = AsyncLoading<String>('cached');
  /// print(loadingWithPrevious.dataOrNull); // 'cached'
  ///
  /// final idle = AsyncIdle<String>();
  /// print(idle.dataOrNull); // null
  /// ```
  T? get dataOrNull => switch (this) {
    AsyncIdle<T>() => null,
    AsyncData<T>(:final data) => data,
    AsyncLoading<T>(:final previousData) => previousData,
    AsyncError<T>(:final previousData) => previousData,
    StreamDone<T>(:final lastData) => lastData,
  };

  /// Pattern matches on all possible states with required handlers.
  ///
  /// This method ensures exhaustive handling of all states. Each handler
  /// is required except [done], which falls back to [data] (if data exists)
  /// or [idle] (if no data) when not provided.
  ///
  /// ## Parameters
  ///
  /// - [idle]: Called when the operation has not started
  /// - [loading]: Called when the operation is in progress
  /// - [data]: Called with the data when the operation succeeded
  /// - [error]: Called with error and stack trace when the operation failed
  /// - [done]: Optional handler for stream completion
  ///
  /// ## Example
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return state.when(
  ///     idle: () => const Text('Press button to load'),
  ///     loading: () => const CircularProgressIndicator(),
  ///     data: (user) => Text('Hello, ${user.name}'),
  ///     error: (e, s) => Text('Error: $e'),
  ///   );
  /// }
  /// ```
  ///
  /// ## With Stream Done Handler
  ///
  /// ```dart
  /// state.when(
  ///   idle: () => const Text('Not connected'),
  ///   loading: () => const Text('Connecting...'),
  ///   data: (msg) => Text(msg.content),
  ///   error: (e, _) => Text('Error: $e'),
  ///   done: (lastMsg) => Text('Stream ended. Last: ${lastMsg?.content}'),
  /// )
  /// ```
  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error, StackTrace stackTrace) error,
    R Function(T? lastData)? done,
  }) {
    return switch (this) {
      AsyncIdle<T>() => idle(),
      AsyncLoading<T>() => loading(),
      AsyncData<T>(data: final d) => data(d),
      AsyncError<T>(error: final e, stackTrace: final s) => error(e, s),
      StreamDone<T>(:final lastData) =>
        done?.call(lastData) ?? (lastData != null ? data(lastData) : idle()),
    };
  }

  /// Pattern matches with optional handlers and a required fallback.
  ///
  /// Use this when you only need to handle specific states and want a
  /// default behavior for the rest.
  ///
  /// ## Parameters
  ///
  /// - [idle]: Optional handler for idle state
  /// - [loading]: Optional handler for loading state
  /// - [data]: Optional handler for data state
  /// - [error]: Optional handler for error state
  /// - [done]: Optional handler for stream done state
  /// - [orElse]: Required fallback for unhandled states
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Only handle error state specially
  /// final color = state.maybeWhen(
  ///   error: (_, __) => Colors.red,
  ///   orElse: () => Colors.black,
  /// );
  /// ```
  ///
  /// ## Show Loading Overlay
  ///
  /// ```dart
  /// final showOverlay = state.maybeWhen(
  ///   loading: () => true,
  ///   orElse: () => false,
  /// );
  /// ```
  R maybeWhen<R>({
    R Function()? idle,
    R Function()? loading,
    R Function(T data)? data,
    R Function(Object error, StackTrace stackTrace)? error,
    R Function(T? lastData)? done,
    required R Function() orElse,
  }) {
    return switch (this) {
      AsyncIdle<T>() => idle?.call() ?? orElse(),
      AsyncLoading<T>() => loading?.call() ?? orElse(),
      AsyncData<T>(data: final d) => data?.call(d) ?? orElse(),
      AsyncError<T>(error: final e, stackTrace: final s) =>
        error?.call(e, s) ?? orElse(),
      StreamDone<T>(:final lastData) => done?.call(lastData) ?? orElse(),
    };
  }

  /// Pattern matches with access to previous data in loading/error states.
  ///
  /// This is useful when you want to show stale data while refreshing or
  /// display cached content alongside an error message.
  ///
  /// ## Parameters
  ///
  /// - [idle]: Called when the operation has not started
  /// - [loading]: Called with previous data (may be null) during loading
  /// - [data]: Called with current data on success
  /// - [error]: Called with error, stack trace, and previous data on failure
  /// - [done]: Optional handler for stream completion
  ///
  /// ## Example: Refresh with Stale Data
  ///
  /// ```dart
  /// state.whenWithPrevious(
  ///   idle: () => const Text('No data'),
  ///   loading: (previous) => Stack(
  ///     children: [
  ///       if (previous != null) UserCard(user: previous),
  ///       const Center(child: CircularProgressIndicator()),
  ///     ],
  ///   ),
  ///   data: (user) => UserCard(user: user),
  ///   error: (e, s, previous) => Column(
  ///     children: [
  ///       Text('Error: $e'),
  ///       if (previous != null) ...[
  ///         const Text('Showing cached data:'),
  ///         UserCard(user: previous),
  ///       ],
  ///     ],
  ///   ),
  /// )
  /// ```
  ///
  /// ## Example: Pull-to-Refresh
  ///
  /// ```dart
  /// state.whenWithPrevious(
  ///   idle: () => const EmptyState(),
  ///   loading: (previous) => previous != null
  ///     ? RefreshIndicator(
  ///         onRefresh: vm.refresh,
  ///         child: ItemList(items: previous),
  ///       )
  ///     : const LoadingSpinner(),
  ///   data: (items) => RefreshIndicator(
  ///     onRefresh: vm.refresh,
  ///     child: ItemList(items: items),
  ///   ),
  ///   error: (e, _, previous) => ErrorWithRetry(
  ///     error: e,
  ///     cachedData: previous,
  ///     onRetry: vm.refresh,
  ///   ),
  /// )
  /// ```
  R whenWithPrevious<R>({
    required R Function() idle,
    required R Function(T? previousData) loading,
    required R Function(T data) data,
    required R Function(Object error, StackTrace stackTrace, T? previousData)
    error,
    R Function(T? lastData)? done,
  }) {
    return switch (this) {
      AsyncIdle<T>() => idle(),
      AsyncLoading<T>(:final previousData) => loading(previousData),
      AsyncData<T>(data: final d) => data(d),
      AsyncError<T>(error: final e, stackTrace: final s, :final previousData) =>
        error(e, s, previousData),
      StreamDone<T>(:final lastData) =>
        done?.call(lastData) ?? (lastData != null ? data(lastData) : idle()),
    };
  }
}

/// Represents an idle state where the async operation has not started.
///
/// This is the initial state for [ReactiveFuture.idle] and [ReactiveStream.idle].
/// Use this when you want to show a different UI before the user triggers
/// an action.
///
/// ## Example
///
/// ```dart
/// final searchResults = ReactiveFuture<List<Item>>.idle();
///
/// // Show a prompt before the user searches
/// searchResults.listenWhen(
///   idle: () => const Text('Enter a search term'),
///   loading: () => const CircularProgressIndicator(),
///   data: (results) => ResultsList(results),
///   error: (e, _) => Text('Error: $e'),
/// )
/// ```
class AsyncIdle<T> extends AsyncState<T> {
  /// Creates an [AsyncIdle] state.
  const AsyncIdle();
}

/// Represents a loading state where the async operation is in progress.
///
/// Optionally holds [previousData] from a previous successful operation,
/// allowing you to show stale content while refreshing.
///
/// ## Example
///
/// ```dart
/// // Loading without previous data
/// const state = AsyncLoading<String>();
///
/// // Loading with previous data (e.g., during refresh)
/// const refreshing = AsyncLoading<String>('cached value');
/// print(refreshing.previousData); // 'cached value'
/// ```
///
/// ## Accessing Previous Data
///
/// ```dart
/// if (state is AsyncLoading<User>) {
///   final cached = state.previousData;
///   if (cached != null) {
///     showStaleData(cached);
///   }
/// }
/// ```
class AsyncLoading<T> extends AsyncState<T> {
  /// Creates an [AsyncLoading] state with optional previous data.
  ///
  /// The [previousData] parameter holds data from a previous successful
  /// operation, useful for showing stale content during refresh.
  const AsyncLoading([this.previousData]);

  /// The data from a previous successful operation, if any.
  ///
  /// This is `null` for the first load, but contains the previous value
  /// when refreshing or retrying after an error.
  final T? previousData;
}

/// Represents a successful state with data.
///
/// This state indicates that the async operation completed successfully
/// and contains the resulting [data].
///
/// ## Example
///
/// ```dart
/// const state = AsyncData<String>('Hello, World!');
/// print(state.data); // 'Hello, World!'
/// print(state.hasData); // true
/// ```
///
/// ## Pattern Matching
///
/// ```dart
/// if (state case AsyncData<User>(:final data)) {
///   print('User: ${data.name}');
/// }
/// ```
class AsyncData<T> extends AsyncState<T> {
  /// Creates an [AsyncData] state with the given data.
  const AsyncData(this.data);

  /// The successful result of the async operation.
  final T data;
}

/// Represents an error state where the async operation failed.
///
/// Contains the [error] that occurred, the [stackTrace] for debugging,
/// and optionally [previousData] from before the error.
///
/// ## Example
///
/// ```dart
/// try {
///   await fetchData();
/// } catch (e, s) {
///   state = AsyncError<String>(e, s, previousValue);
/// }
/// ```
///
/// ## Accessing Error Information
///
/// ```dart
/// if (state case AsyncError<User>(:final error, :final stackTrace)) {
///   print('Error: $error');
///   print('Stack trace: $stackTrace');
/// }
/// ```
///
/// ## Error Recovery with Previous Data
///
/// ```dart
/// state.whenWithPrevious(
///   error: (error, stackTrace, previous) {
///     // Log the error
///     logger.error('Failed to load', error, stackTrace);
///
///     // Show previous data if available
///     if (previous != null) {
///       return CachedDataView(data: previous, error: error);
///     }
///     return ErrorView(error: error);
///   },
///   // ... other handlers
/// )
/// ```
class AsyncError<T> extends AsyncState<T> {
  /// Creates an [AsyncError] state.
  ///
  /// - [error]: The error that occurred
  /// - [stackTrace]: The stack trace at the point of failure
  /// - [previousData]: Optional data from before the error occurred
  const AsyncError(this.error, this.stackTrace, [this.previousData]);

  /// The error that caused the operation to fail.
  ///
  /// This can be any object, but is typically an [Exception] or [Error].
  final Object error;

  /// The stack trace captured when the error occurred.
  ///
  /// Useful for debugging and error reporting.
  final StackTrace stackTrace;

  /// The data from before the error occurred, if any.
  ///
  /// This allows showing cached/stale data alongside the error message,
  /// giving users a better experience during temporary failures.
  final T? previousData;
}

/// Represents a completed stream state.
///
/// This state is specific to [ReactiveStream] and indicates that the
/// underlying stream has closed. It optionally contains [lastData],
/// which is the last value emitted before the stream completed.
///
/// ## Example
///
/// ```dart
/// final messages = ReactiveStream<Message>();
/// messages.bind(chatStream);
///
/// // When the stream closes:
/// messages.listenWhen(
///   loading: () => const Text('Connecting...'),
///   data: (msg) => MessageBubble(msg),
///   error: (e, _) => Text('Error: $e'),
///   done: (lastMsg) => Column(
///     children: [
///       const Text('Chat ended'),
///       if (lastMsg != null) Text('Last message: ${lastMsg.content}'),
///     ],
///   ),
/// )
/// ```
///
/// ## Handling Stream Completion
///
/// ```dart
/// if (state.isDone) {
///   final lastValue = (state as StreamDone<Message>).lastData;
///   showStreamEndedDialog(lastValue);
/// }
/// ```
class StreamDone<T> extends AsyncState<T> {
  /// Creates a [StreamDone] state with optional last data.
  ///
  /// The [lastData] parameter contains the last value emitted by the
  /// stream before it completed, or `null` if the stream completed
  /// without emitting any values.
  const StreamDone([this.lastData]);

  /// The last data emitted by the stream before it completed.
  ///
  /// This is `null` if the stream completed without emitting any values.
  final T? lastData;
}
