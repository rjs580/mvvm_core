import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('AsyncState', () {
    group('state checks', () {
      test('AsyncIdle properties', () {
        const state = AsyncIdle<String>();

        expect(state.isIdle, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isFalse);
        expect(state.hasError, isFalse);
        expect(state.isDone, isFalse);
        expect(state.dataOrNull, isNull);
      });

      test('AsyncLoading properties', () {
        const state = AsyncLoading<String>();

        expect(state.isIdle, isFalse);
        expect(state.isLoading, isTrue);
        expect(state.hasData, isFalse);
        expect(state.hasError, isFalse);
        expect(state.isDone, isFalse);
        expect(state.dataOrNull, isNull);
      });

      test('AsyncLoading with previous data', () {
        const state = AsyncLoading<String>('previous');

        expect(state.isLoading, isTrue);
        expect(state.dataOrNull, equals('previous'));
        expect(state.previousData, equals('previous'));
      });

      test('AsyncData properties', () {
        const state = AsyncData<String>('hello');

        expect(state.isIdle, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isTrue);
        expect(state.hasError, isFalse);
        expect(state.isDone, isFalse);
        expect(state.dataOrNull, equals('hello'));
        expect(state.data, equals('hello'));
      });

      test('AsyncError properties', () {
        final state = AsyncError<String>(
          Exception('error'),
          StackTrace.current,
          'previous',
        );

        expect(state.isIdle, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isFalse);
        expect(state.hasError, isTrue);
        expect(state.isDone, isFalse);
        expect(state.dataOrNull, equals('previous'));
        expect(state.previousData, equals('previous'));
      });

      test('StreamDone properties', () {
        const state = StreamDone<String>('last');

        expect(state.isIdle, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isFalse);
        expect(state.hasError, isFalse);
        expect(state.isDone, isTrue);
        expect(state.dataOrNull, equals('last'));
        expect(state.lastData, equals('last'));
      });
    });

    group('when', () {
      test('calls idle for AsyncIdle', () {
        const state = AsyncIdle<String>();

        final result = state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, s) => 'error',
        );

        expect(result, equals('idle'));
      });

      test('calls loading for AsyncLoading', () {
        const state = AsyncLoading<String>();

        final result = state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, s) => 'error',
        );

        expect(result, equals('loading'));
      });

      test('calls data for AsyncData', () {
        const state = AsyncData<String>('hello');

        final result = state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, s) => 'error',
        );

        expect(result, equals('data: hello'));
      });

      test('calls error for AsyncError', () {
        final state = AsyncError<String>(
          Exception('test'),
          StackTrace.current,
        );

        final result = state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, s) => 'error: $e',
        );

        expect(result, contains('error'));
      });

      test('calls done for StreamDone when provided', () {
        const state = StreamDone<String>('last');

        final result = state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, s) => 'error',
          done: (d) => 'done: $d',
        );

        expect(result, equals('done: last'));
      });

      test('falls back to data for StreamDone when done not provided', () {
        const state = StreamDone<String>('last');

        final result = state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, s) => 'error',
        );

        expect(result, equals('data: last'));
      });

      test('falls back to idle for StreamDone with no data', () {
        const state = StreamDone<String>();

        final result = state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, s) => 'error',
        );

        expect(result, equals('idle'));
      });
    });

    group('maybeWhen', () {
      test('calls specific handler when provided', () {
        const state = AsyncData<String>('hello');

        final result = state.maybeWhen(
          data: (d) => 'data: $d',
          orElse: () => 'other',
        );

        expect(result, equals('data: hello'));
      });

      test('calls orElse when handler not provided', () {
        const state = AsyncData<String>('hello');

        final result = state.maybeWhen(
          loading: () => 'loading',
          orElse: () => 'other',
        );

        expect(result, equals('other'));
      });
    });

    group('whenWithPrevious', () {
      test('provides previous data in loading callback', () {
        const state = AsyncLoading<String>('previous');

        final result = state.whenWithPrevious(
          idle: () => 'idle',
          loading: (prev) => 'loading with: $prev',
          data: (d) => 'data: $d',
          error: (e, s, prev) => 'error',
        );

        expect(result, equals('loading with: previous'));
      });

      test('provides previous data in error callback', () {
        final state = AsyncError<String>(
          Exception('error'),
          StackTrace.current,
          'previous',
        );

        final result = state.whenWithPrevious(
          idle: () => 'idle',
          loading: (prev) => 'loading',
          data: (d) => 'data: $d',
          error: (e, s, prev) => 'error with: $prev',
        );

        expect(result, equals('error with: previous'));
      });
    });
  });
}
