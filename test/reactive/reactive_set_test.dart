import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('ReactiveSet', () {
    group('initialization', () {
      test('creates empty set by default', () {
        final set = ReactiveSet<int>();
        expect(set.isEmpty, isTrue);
      });

      test('creates set with initial values', () {
        final set = ReactiveSet<int>({1, 2, 3});
        expect(set.length, equals(3));
        expect(set.contains(1), isTrue);
        expect(set.contains(2), isTrue);
        expect(set.contains(3), isTrue);
      });

      test('value returns unmodifiable view', () {
        final set = ReactiveSet<int>({1, 2, 3});
        expect(() => set.value.add(4), throwsUnsupportedError);
      });
    });

    group('add operations', () {
      test('add notifies when element is new', () {
        final set = ReactiveSet<int>();
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        final added = set.add(1);

        expect(added, isTrue);
        expect(set.contains(1), isTrue);
        expect(notificationCount, equals(1));
      });

      test('add does not notify when element exists', () {
        final set = ReactiveSet<int>({1});
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        final added = set.add(1);

        expect(added, isFalse);
        expect(notificationCount, equals(0));
      });

      test('addAll notifies when elements added', () {
        final set = ReactiveSet<int>({1});
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.addAll({2, 3});

        expect(set.length, equals(3));
        expect(notificationCount, equals(1));
      });

      test('addAll does not notify when all elements exist', () {
        final set = ReactiveSet<int>({1, 2, 3});
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.addAll({1, 2});

        expect(notificationCount, equals(0));
      });
    });

    group('remove operations', () {
      test('remove notifies when element exists', () {
        final set = ReactiveSet<int>({1, 2, 3});
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        final removed = set.remove(2);

        expect(removed, isTrue);
        expect(set.contains(2), isFalse);
        expect(notificationCount, equals(1));
      });

      test('remove does not notify when element does not exist', () {
        final set = ReactiveSet<int>({1, 2, 3});
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        final removed = set.remove(5);

        expect(removed, isFalse);
        expect(notificationCount, equals(0));
      });

      test('removeAll notifies when elements removed', () {
        final set = ReactiveSet<int>({1, 2, 3, 4, 5});
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.removeAll({2, 4});

        expect(set, equals({1, 3, 5}));
        expect(notificationCount, equals(1));
      });

      test('removeWhere notifies when elements removed', () {
        final set = ReactiveSet<int>({1, 2, 3, 4, 5});
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.removeWhere((e) => e.isEven);

        expect(set, equals({1, 3, 5}));
        expect(notificationCount, equals(1));
      });

      test('clear notifies when not empty', () {
        final set = ReactiveSet<int>({1, 2, 3});
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.clear();

        expect(set.isEmpty, isTrue);
        expect(notificationCount, equals(1));
      });

      test('clear does not notify when already empty', () {
        final set = ReactiveSet<int>();
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.clear();

        expect(notificationCount, equals(0));
      });
    });

    group('set operations', () {
      test('union returns new set', () {
        final set = ReactiveSet<int>({1, 2});
        final result = set.union({2, 3});

        expect(result, equals({1, 2, 3}));
        expect(result, isNot(isA<ReactiveSet>()));
      });

      test('intersection returns new set', () {
        final set = ReactiveSet<int>({1, 2, 3});
        final result = set.intersection({2, 3, 4});

        expect(result, equals({2, 3}));
      });

      test('difference returns new set', () {
        final set = ReactiveSet<int>({1, 2, 3});
        final result = set.difference({2, 3, 4});

        expect(result, equals({1}));
      });
    });

    group('custom reactive methods', () {
      test('replaceAll replaces all elements', () {
        final set = ReactiveSet<int>({1, 2, 3});
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.replaceAll({4, 5, 6});

        expect(set, equals({4, 5, 6}));
        expect(notificationCount, equals(1));
      });

      test('batch performs multiple operations with single notification', () {
        final set = ReactiveSet<int>();
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.batch((s) {
          s.add(1);
          s.add(2);
          s.add(3);
        });

        expect(set.length, equals(3));
        expect(notificationCount, equals(1));
      });

      test('silent does not notify', () {
        final set = ReactiveSet<int>();
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.silent((s) {
          s.add(1);
        });

        expect(set.contains(1), isTrue);
        expect(notificationCount, equals(0));
      });

      test('refresh notifies listeners', () {
        final set = ReactiveSet<int>();
        int notificationCount = 0;
        set.addListener(() => notificationCount++);

        set.refresh();

        expect(notificationCount, equals(1));
      });
    });
  });
}
