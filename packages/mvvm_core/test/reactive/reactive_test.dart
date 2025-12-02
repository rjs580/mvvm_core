import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('Reactive', () {
    group('initialization', () {
      test('initializes with given value', () {
        final reactive = Reactive<int>(42);
        expect(reactive.value, equals(42));
      });

      test('initializes with null for nullable types', () {
        final reactive = Reactive<String?>(null);
        expect(reactive.value, isNull);
      });
    });

    group('value setter', () {
      test('updates value', () {
        final reactive = Reactive<int>(0);
        reactive.value = 10;
        expect(reactive.value, equals(10));
      });

      test('notifies listeners when value changes', () {
        final reactive = Reactive<int>(0);
        int notificationCount = 0;
        reactive.addListener(() => notificationCount++);

        reactive.value = 10;
        expect(notificationCount, equals(1));
      });

      test('does not notify when value is the same', () {
        final reactive = Reactive<int>(5);
        int notificationCount = 0;
        reactive.addListener(() => notificationCount++);

        reactive.value = 5;
        expect(notificationCount, equals(0));
      });

      test('handles equality correctly for objects', () {
        final reactive = Reactive<String>('hello');
        int notificationCount = 0;
        reactive.addListener(() => notificationCount++);

        reactive.value = 'hello'; // Same value
        expect(notificationCount, equals(0));

        reactive.value = 'world'; // Different value
        expect(notificationCount, equals(1));
      });
    });

    group('update', () {
      test('transforms value using function', () {
        final reactive = Reactive<int>(5);
        reactive.update((current) => current * 2);
        expect(reactive.value, equals(10));
      });

      test('notifies listeners after update', () {
        final reactive = Reactive<int>(5);
        int notificationCount = 0;
        reactive.addListener(() => notificationCount++);

        reactive.update((current) => current + 1);
        expect(notificationCount, equals(1));
      });

      test('does not notify if update returns same value', () {
        final reactive = Reactive<int>(5);
        int notificationCount = 0;
        reactive.addListener(() => notificationCount++);

        reactive.update((current) => current); // Returns same value
        expect(notificationCount, equals(0));
      });

      test('works with complex transformations', () {
        final reactive = Reactive<List<int>>([1, 2, 3]);
        reactive.update((list) => [...list, 4]);
        expect(reactive.value, equals([1, 2, 3, 4]));
      });
    });

    group('refresh', () {
      test('notifies listeners without changing value', () {
        final reactive = Reactive<int>(5);
        int notificationCount = 0;
        reactive.addListener(() => notificationCount++);

        reactive.refresh();
        expect(notificationCount, equals(1));
        expect(reactive.value, equals(5));
      });
    });

    group('ValueListenable implementation', () {
      test('implements ValueListenable interface', () {
        final reactive = Reactive<int>(42);
        expect(reactive, isA<ValueListenable<int>>());
        expect(reactive.value, equals(42));
      });
    });
  });
}
