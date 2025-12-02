import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mvvm_core/src/reactive/async_state.dart';
import 'package:mvvm_core/src/reactive/reactive_property.dart';

/// A reactive property that manages the state of a [Stream]-based async operation.
///
/// [ReactiveStream] wraps a stream subscription and automatically manages
/// connection, data, error, and completion states through [AsyncState]. It
/// provides a clean way to handle real-time data streams in your ViewModels
/// while keeping the UI reactive.
///
/// ## Basic Usage
///
/// ```dart
/// class ChatViewModel extends ViewModel {
///   final messages = ReactiveStream<Message>();
///
///   void connect(String roomId) {
///     messages.bind(chatService.getMessages(roomId));
///   }
///
///   void disconnect() {
///     messages.cancel();
///   }
///
///   @override
///   void dispose() {
///     messages.cancel();
///     super.dispose();
///   }
/// }
///
/// // In the view:
/// vm.messages.listenWhen(
///   loading: () => const Text('Connecting...'),
///   data: (message) => MessageBubble(message),
///   error: (e, _) => Text('Error: $e'),
///   done: (_) => const Text('Chat ended'),
/// )
/// ```
///
/// ## Starting in Idle State
///
/// Use [ReactiveStream.idle] when the stream shouldn't connect automatically:
///
/// ```dart
/// class LocationViewModel extends ViewModel {
///   final location = ReactiveStream<Position>.idle();
///
///   void startTracking() {
///     location.bind(locationService.positionStream);
///   }
///
///   void stopTracking() {
///     location.reset();
///   }
/// }
///
/// // In the view:
/// vm.location.listenWhen(
///   idle: () => const Text('Tap to start tracking'),
///   loading: () => const Text('Getting location...'),
///   data: (pos) => Text('${pos.latitude}, ${pos.longitude}'),
///   error: (e, _) => Text('Location error: $e'),
/// )
/// ```
///
/// ## Stream Event Handling
///
/// [ReactiveStream] handles all stream events:
///
/// ```dart
/// // Data event -> AsyncData state
/// // Error event -> AsyncError state (stream continues unless cancelOnError)
/// // Done event -> StreamDone state (stream completed)
/// ```
///
/// ## Rebinding to a New Stream
///
/// Calling [bind] again automatically cancels the previous subscription:
///
/// ```dart
/// void switchRoom(String newRoomId) {
///   // Previous subscription is automatically cancelled
///   messages.bind(chatService.getMessages(newRoomId));
/// }
/// ```
///
/// ## Canceling on Error
///
/// By default, streams continue after errors. Use [cancelOnError] to stop:
///
/// ```dart
/// // Continue after errors (default)
/// stream.bind(dataStream);
///
/// // Stop on first error
/// stream.bind(dataStream, cancelOnError: true);
/// ```
///
/// ## Accessing Current Data
///
/// Use the [data] getter to access the most recent value:
///
/// ```dart
/// void processLatestMessage() {
///   final latestMessage = messages.data;
///   if (latestMessage != null) {
///     analytics.log('Last message: ${latestMessage.text}');
///   }
/// }
/// ```
///
/// ## Checking Stream Status
///
/// Use [isActive] to check if the stream subscription is active:
///
/// ```dart
/// IconButton(
///   icon: Icon(vm.location.isActive ? Icons.pause : Icons.play_arrow),
///   onPressed: () {
///     if (vm.location.isActive) {
///       vm.location.cancel();
///     } else {
///       vm.location.bind(locationStream);
///     }
///   },
/// )
/// ```
///
/// ## State Flow
///
/// ```
/// ┌─────────────────────────────────────────────────────────────┐
/// │                                                             │
/// │  ┌──────────┐     bind()      ┌───────────┐                │
/// │  │  Idle    │ ─────────────►  │  Loading  │                │
/// │  └──────────┘                 └───────────┘                │
/// │       ▲                            │                        │
/// │       │                    data    │   error                │
/// │    reset()                event    │   event                │
/// │       │                      │     │     │                  │
/// │       │                      ▼     │     ▼                  │
/// │       │                 ┌──────────┴─┐  ┌─────────┐        │
/// │       │                 │    Data    │  │  Error  │        │
/// │       │                 └────────────┘  └─────────┘        │
/// │       │                      │               │              │
/// │       │                      │  done event   │              │
/// │       │                      ▼               │              │
/// │       │                 ┌────────────────────┴──┐          │
/// │       └─────────────────│     StreamDone        │          │
/// │                         └───────────────────────┘          │
/// │                                                             │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Common Use Cases
///
/// ### Real-time Chat
/// ```dart
/// class ChatViewModel extends ViewModel {
///   final messages = ReactiveStream<Message>();
///   final typingUsers = ReactiveStream<List<User>>();
///
///   void joinRoom(String roomId) {
///     messages.bind(chatService.messages(roomId));
///     typingUsers.bind(chatService.typingUsers(roomId));
///   }
///
///   void leaveRoom() {
///     messages.reset();
///     typingUsers.reset();
///   }
/// }
/// ```
///
/// ### Live Data Feed
/// ```dart
/// class StockViewModel extends ViewModel {
///   final stockPrice = ReactiveStream<double>();
///
///   void subscribe(String symbol) {
///     stockPrice.bind(stockService.priceStream(symbol));
///   }
///
///   void unsubscribe() {
///     stockPrice.cancel();
///   }
/// }
/// ```
///
/// ### Sensor Data
/// ```dart
/// class SensorViewModel extends ViewModel {
///   final accelerometer = ReactiveStream<AccelerometerEvent>.idle();
///
///   void startListening() {
///     accelerometer.bind(accelerometerEvents);
///   }
///
///   void stopListening() {
///     accelerometer.reset();
///   }
/// }
/// ```
///
/// ## Handling Stream Completion
///
/// Use the [done] handler for streams that complete:
///
/// ```dart
/// vm.download.listenWhen(
///   loading: () => const Text('Starting download...'),
///   data: (progress) => LinearProgressIndicator(value: progress),
///   error: (e, _) => Text('Download failed: $e'),
///   done: (finalProgress) => const Text('Download complete!'),
/// )
/// ```
///
/// ## Memory Management
///
/// Always cancel subscriptions when done. The subscription is automatically
/// cancelled when:
/// - [cancel] is called
/// - [reset] is called
/// - [bind] is called with a new stream
/// - [dispose] is called
///
/// ```dart
/// class MyViewModel extends ViewModel {
///   final data = ReactiveStream<Data>();
///
///   @override
///   void dispose() {
///     data.cancel(); // Or handled automatically by ReactiveStream.dispose()
///     super.dispose();
///   }
/// }
/// ```
///
/// See also:
///
/// * [AsyncState], the sealed class representing all possible states.
/// * [ReactiveFuture], for one-time async operations.
/// * [StreamDone], the state for completed streams.
class ReactiveStream<T> extends ReactiveProperty<AsyncState<T>> {
  /// Creates a [ReactiveStream] that starts in the loading state.
  ///
  /// Use this constructor when you plan to bind a stream immediately
  /// and want to show a loading indicator by default.
  ///
  /// Example:
  /// ```dart
  /// class ChatViewModel extends ViewModel {
  ///   final messages = ReactiveStream<Message>();
  ///
  ///   @override
  ///   void init(BuildContext context) {
  ///     super.init(context);
  ///     messages.bind(chatService.messageStream);
  ///   }
  /// }
  /// ```
  ReactiveStream() : _state = const AsyncLoading();

  /// Creates a [ReactiveStream] that starts in the idle state.
  ///
  /// Use this constructor when the stream connection should not start
  /// automatically and you want to show a different UI before the
  /// user triggers the connection.
  ///
  /// Example:
  /// ```dart
  /// // Location tracking that waits for user to start
  /// final location = ReactiveStream<Position>.idle();
  ///
  /// // Live feed that connects on demand
  /// final feed = ReactiveStream<FeedItem>.idle();
  /// ```
  ReactiveStream.idle() : _state = const AsyncIdle();

  AsyncState<T> _state;
  StreamSubscription<T>? _subscription;

  /// The current [AsyncState] of this reactive stream.
  ///
  /// Use this to access the full state object for pattern matching
  /// with [AsyncState.when], [AsyncState.maybeWhen], or
  /// [AsyncState.whenWithPrevious].
  ///
  /// Example:
  /// ```dart
  /// if (messages.value.isLoading) {
  ///   showConnectionIndicator();
  /// }
  /// ```
  @override
  AsyncState<T> get value => _state;

  /// The most recent data emitted by the stream, if available.
  ///
  /// This is a convenience getter that returns:
  /// - The latest data if in [AsyncData] state
  /// - The previous data if in [AsyncLoading] or [AsyncError] state
  /// - The last data if in [StreamDone] state
  /// - `null` if in [AsyncIdle] state or no data has been received
  ///
  /// Example:
  /// ```dart
  /// void logLatestMessage() {
  ///   final latest = messages.data;
  ///   if (latest != null) {
  ///     print('Latest: ${latest.text}');
  ///   }
  /// }
  /// ```
  T? get data => _state.dataOrNull;

  /// Whether there is an active stream subscription.
  ///
  /// Returns `true` if [bind] has been called and the stream hasn't
  /// completed or been cancelled.
  ///
  /// Example:
  /// ```dart
  /// Widget build() {
  ///   return IconButton(
  ///     icon: Icon(vm.stream.isActive ? Icons.stop : Icons.play),
  ///     onPressed: vm.stream.isActive ? vm.stop : vm.start,
  ///   );
  /// }
  /// ```
  bool get isActive => _subscription != null;

  /// Binds to a stream and updates state on each event.
  ///
  /// This method:
  /// 1. Cancels any existing subscription
  /// 2. Sets state to [AsyncLoading] (preserving previous data)
  /// 3. Subscribes to the new stream
  /// 4. Updates state on data/error/done events
  ///
  /// The [cancelOnError] parameter controls whether the subscription
  /// should be cancelled when an error occurs. Default is `false`,
  /// meaning the stream continues after errors.
  ///
  /// ## Basic Example
  ///
  /// ```dart
  /// void connect() {
  ///   messages.bind(chatService.messageStream);
  /// }
  /// ```
  ///
  /// ## With Cancel on Error
  ///
  /// ```dart
  /// // Stop subscription on first error
  /// location.bind(locationStream, cancelOnError: true);
  /// ```
  ///
  /// ## Switching Streams
  ///
  /// ```dart
  /// void switchChannel(String channelId) {
  ///   // Previous subscription is automatically cancelled
  ///   messages.bind(chatService.getChannel(channelId));
  /// }
  /// ```
  ///
  /// ## Event Handling
  ///
  /// - **Data event**: State becomes [AsyncData] with the new value
  /// - **Error event**: State becomes [AsyncError] with error and stack trace
  /// - **Done event**: State becomes [StreamDone] with the last data
  void bind(Stream<T> stream, {bool cancelOnError = false}) {
    cancel();

    final previousData = _state.dataOrNull;
    _state = AsyncLoading<T>(previousData);
    notifyListeners();

    _subscription = stream.listen(
      (data) {
        _state = AsyncData<T>(data);
        notifyListeners();
      },
      onError: (Object e, StackTrace s) {
        _state = AsyncError<T>(e, s, _state.dataOrNull);
        notifyListeners();
      },
      onDone: () {
        _state = StreamDone<T>(_state.dataOrNull);
        _subscription = null;
        notifyListeners();
      },
      cancelOnError: cancelOnError,
    );
  }

  /// Cancels the current stream subscription.
  ///
  /// After calling this method, [isActive] will return `false`.
  /// The current state is preserved - use [reset] if you also want
  /// to clear the state.
  ///
  /// This is safe to call even if there's no active subscription.
  ///
  /// Example:
  /// ```dart
  /// void disconnect() {
  ///   messages.cancel();
  ///   // State remains as it was (e.g., last AsyncData)
  /// }
  /// ```
  void cancel() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Resets to idle state and cancels any active subscription.
  ///
  /// This method:
  /// 1. Cancels the current subscription (if any)
  /// 2. Sets state to [AsyncIdle]
  /// 3. Notifies listeners
  ///
  /// Use this when you want to completely reset the stream state,
  /// such as when the user logs out or switches contexts.
  ///
  /// Example:
  /// ```dart
  /// void onLogout() {
  ///   messages.reset();
  ///   // UI shows idle state
  /// }
  /// ```
  void reset() {
    cancel();
    _state = const AsyncIdle();
    notifyListeners();
  }

  /// Creates a widget that handles all stream states with a clean API.
  ///
  /// This is a convenience method that combines [listen] with [AsyncState.when]
  /// for a cleaner syntax when building UI based on stream state.
  ///
  /// ## Parameters
  ///
  /// - [idle]: Widget to show before stream is connected (defaults to [loading])
  /// - [loading]: Widget to show while connecting (required)
  /// - [data]: Widget builder for each data event (required)
  /// - [error]: Widget builder for error events (required)
  /// - [done]: Optional widget builder when stream completes
  ///
  /// ## Basic Example
  ///
  /// ```dart
  /// vm.messages.listenWhen(
  ///   loading: () => const CircularProgressIndicator(),
  ///   data: (message) => MessageBubble(message: message),
  ///   error: (e, _) => Text('Error: $e'),
  /// )
  /// ```
  ///
  /// ## With All States
  ///
  /// ```dart
  /// vm.location.listenWhen(
  ///   idle: () => const Text('Tap to start tracking'),
  ///   loading: () => const Text('Getting location...'),
  ///   data: (position) => PositionDisplay(position: position),
  ///   error: (e, s) => ErrorDisplay(error: e),
  ///   done: (lastPosition) => Text('Tracking ended at $lastPosition'),
  /// )
  /// ```
  ///
  /// ## For More Control
  ///
  /// Use [listen] with [AsyncState.whenWithPrevious] for access to
  /// previous data during loading/error states:
  ///
  /// ```dart
  /// vm.price.listen(
  ///   builder: (context, state, _) => state.whenWithPrevious(
  ///     idle: () => const Text('Not subscribed'),
  ///     loading: (previous) => PriceDisplay(
  ///       price: previous,
  ///       isLoading: true,
  ///     ),
  ///     data: (price) => PriceDisplay(price: price),
  ///     error: (e, s, previous) => PriceDisplay(
  ///       price: previous,
  ///       error: e,
  ///     ),
  ///   ),
  /// )
  /// ```
  Widget listenWhen({
    Widget Function()? idle,
    required Widget Function() loading,
    required Widget Function(T data) data,
    required Widget Function(Object error, StackTrace stackTrace) error,
    Widget Function(T? lastData)? done,
  }) {
    return listen(
      builder: (context, state, _) => state.when(
        idle: idle ?? loading,
        loading: loading,
        data: data,
        error: error,
        done: done,
      ),
    );
  }

  /// Disposes of this reactive stream and cancels any active subscription.
  ///
  /// This method is called automatically when the associated [ViewModel]
  /// is disposed. You typically don't need to call this directly.
  ///
  /// After disposal, the stream should not be used.
  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}
