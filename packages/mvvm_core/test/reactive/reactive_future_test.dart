import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('ReactiveFuture', () {
    group('initialization', () {
      test('default constructor starts in loading state', () {
        final future = ReactiveFuture<String>();
        expect(future.value.isLoading, isTrue);
      });

      test('idle constructor starts in idle state', () {
        final future = ReactiveFuture<String>.idle();
        expect(future.value.isIdle, isTrue);
      });

      test('data is null initially', () {
        final future = ReactiveFuture<String>.idle();
        expect(future.data, isNull);
      });
    });

    group('run', () {
      test('transitions to loading then data on success', () async {
        final future = ReactiveFuture<String>.idle();
        final states = <AsyncState<String>>[];
        future.addListener(() => states.add(future.value));

        await future.run(() async => 'result');

        expect(states.length, equals(2));
        expect(states[0].isLoading, isTrue);
        expect(states[1].hasData, isTrue);
        expect(future.data, equals('result'));
      });

      test('transitions to loading then error on failure', () async {
        final future = ReactiveFuture<String>.idle();
        final states = <AsyncState<String>>[];
        future.addListener(() => states.add(future.value));

        await future.run(() async => throw Exception('test error'));

        expect(states.length, equals(2));
        expect(states[0].isLoading, isTrue);
        expect(states[1].hasError, isTrue);
      });

      test('returns result on success', () async {
        final future = ReactiveFuture<int>.idle();
        final result = await future.run(() async => 42);
        expect(result, equals(42));
      });

      test('returns null on error', () async {
        final future = ReactiveFuture<int>.idle();
        final result = await future.run(() async => throw Exception());
        expect(result, isNull);
      });

      test('preserves previous data during loading', () async {
        final future = ReactiveFuture<String>.idle();

        // First load
        await future.run(() async => 'first');
        expect(future.data, equals('first'));

        // Second load - should preserve data during loading
        AsyncState<String>? loadingState;
        future.addListener(() {
          if (future.value.isLoading) {
            loadingState = future.value;
          }
        });

        await future.run(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'second';
        });

        expect(
          (loadingState as AsyncLoading<String>).previousData,
          equals('first'),
        );
      });

      test('preserves previous data on error', () async {
        final future = ReactiveFuture<String>.idle();

        await future.run(() async => 'original');
        await future.run(() async => throw Exception());

        final errorState = future.value as AsyncError<String>;
        expect(errorState.previousData, equals('original'));
      });
    });

    group('reset', () {
      test('resets to idle state', () async {
        final future = ReactiveFuture<String>();
        await future.run(() async => 'data');

        future.reset();

        expect(future.value.isIdle, isTrue);
        expect(future.data, isNull);
      });

      test('notifies listeners on reset', () async {
        final future = ReactiveFuture<String>();
        await future.run(() async => 'data');

        int notificationCount = 0;
        future.addListener(() => notificationCount++);

        future.reset();

        expect(notificationCount, equals(1));
      });
    });

    group('setData', () {
      test('sets data state manually', () {
        final future = ReactiveFuture<String>.idle();
        future.setData('manual');

        expect(future.value.hasData, isTrue);
        expect(future.data, equals('manual'));
      });

      test('notifies listeners', () {
        final future = ReactiveFuture<String>.idle();
        int notificationCount = 0;
        future.addListener(() => notificationCount++);

        future.setData('manual');

        expect(notificationCount, equals(1));
      });
    });

    group('setError', () {
      test('sets error state manually', () {
        final future = ReactiveFuture<String>.idle();
        future.setError(Exception('manual error'));

        expect(future.value.hasError, isTrue);
      });

      test('preserves previous data in error', () async {
        final future = ReactiveFuture<String>.idle();
        await future.run(() async => 'data');

        future.setError(Exception('error'));

        final errorState = future.value as AsyncError<String>;
        expect(errorState.previousData, equals('data'));
      });
    });
  });
}
