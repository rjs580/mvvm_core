import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('ReactiveStream', () {
    group('initialization', () {
      test('default constructor starts in loading state', () {
        final stream = ReactiveStream<String>();
        expect(stream.value.isLoading, isTrue);
      });

      test('idle constructor starts in idle state', () {
        final stream = ReactiveStream<String>.idle();
        expect(stream.value.isIdle, isTrue);
      });

      test('isActive is false initially', () {
        final stream = ReactiveStream<String>();
        expect(stream.isActive, isFalse);
      });
    });

    group('bind', () {
      test('subscribes to stream and receives data', () async {
        final stream = ReactiveStream<int>.idle();
        final controller = StreamController<int>();

        stream.bind(controller.stream);
        expect(stream.isActive, isTrue);

        controller.add(1);
        await Future.delayed(Duration.zero);

        expect(stream.value.hasData, isTrue);
        expect(stream.data, equals(1));

        await controller.close();
        stream.dispose();
      });

      test('updates on each stream event', () async {
        final stream = ReactiveStream<int>.idle();
        final controller = StreamController<int>();
        final values = <int?>[];

        stream.addListener(() {
          if (stream.value.hasData) {
            values.add(stream.data);
          }
        });

        stream.bind(controller.stream);

        controller.add(1);
        await Future.delayed(Duration.zero);
        controller.add(2);
        await Future.delayed(Duration.zero);
        controller.add(3);
        await Future.delayed(Duration.zero);

        expect(values, equals([1, 2, 3]));

        await controller.close();
        stream.dispose();
      });

      test('handles stream errors', () async {
        final stream = ReactiveStream<int>.idle();
        final controller = StreamController<int>();

        stream.bind(controller.stream);

        controller.addError(Exception('test error'));
        await Future.delayed(Duration.zero);

        expect(stream.value.hasError, isTrue);
        expect(stream.isActive, isTrue); // Still active by default

        await controller.close();
        stream.dispose();
      });

      test('handles stream done', () async {
        final stream = ReactiveStream<int>.idle();
        final controller = StreamController<int>();

        stream.bind(controller.stream);

        controller.add(42);
        await Future.delayed(Duration.zero);

        await controller.close();
        await Future.delayed(Duration.zero);

        expect(stream.value.isDone, isTrue);
        expect((stream.value as StreamDone<int>).lastData, equals(42));
        expect(stream.isActive, isFalse);

        stream.dispose();
      });

      test('cancels previous subscription when rebinding', () async {
        final stream = ReactiveStream<int>.idle();
        final controller1 = StreamController<int>();
        final controller2 = StreamController<int>();

        stream.bind(controller1.stream);
        stream.bind(controller2.stream);

        controller1.add(1);
        await Future.delayed(Duration.zero);

        controller2.add(2);
        await Future.delayed(Duration.zero);

        // Should only have data from controller2
        expect(stream.data, equals(2));

        await controller1.close();
        await controller2.close();
        stream.dispose();
      });

      test('cancelOnError stops subscription on error', () async {
        final stream = ReactiveStream<int>.idle();
        final controller = StreamController<int>();

        stream.bind(controller.stream, cancelOnError: true);

        controller.addError(Exception('error'));
        await Future.delayed(Duration.zero);

        expect(stream.value.hasError, isTrue);

        await controller.close();
        stream.dispose();
      });
    });

    group('cancel', () {
      test('cancels active subscription', () async {
        final stream = ReactiveStream<int>.idle();
        final controller = StreamController<int>();

        stream.bind(controller.stream);
        expect(stream.isActive, isTrue);

        stream.cancel();
        expect(stream.isActive, isFalse);

        await controller.close();
        stream.dispose();
      });

      test('preserves current state after cancel', () async {
        final stream = ReactiveStream<int>.idle();
        final controller = StreamController<int>();

        stream.bind(controller.stream);
        controller.add(42);
        await Future.delayed(Duration.zero);

        stream.cancel();

        expect(stream.data, equals(42));

        await controller.close();
        stream.dispose();
      });
    });

    group('reset', () {
      test('cancels and resets to idle', () async {
        final stream = ReactiveStream<int>.idle();
        final controller = StreamController<int>();

        stream.bind(controller.stream);
        controller.add(42);
        await Future.delayed(Duration.zero);

        stream.reset();

        expect(stream.value.isIdle, isTrue);
        expect(stream.isActive, isFalse);
        expect(stream.data, isNull);

        await controller.close();
        stream.dispose();
      });
    });

    group('dispose', () {
      test('cancels subscription on dispose', () async {
        final stream = ReactiveStream<int>.idle();
        final controller = StreamController<int>();

        stream.bind(controller.stream);
        stream.dispose();

        expect(stream.isActive, isFalse);

        await controller.close();
      });
    });
  });
}
