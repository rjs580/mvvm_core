import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('ReactiveList', () {
    group('initialization', () {
      test('creates empty list by default', () {
        final list = ReactiveList<int>();
        expect(list.isEmpty, isTrue);
        expect(list.length, equals(0));
      });

      test('creates list with initial values', () {
        final list = ReactiveList<int>([1, 2, 3]);
        expect(list.length, equals(3));
        expect(list[0], equals(1));
        expect(list[1], equals(2));
        expect(list[2], equals(3));
      });

      test('value returns unmodifiable view', () {
        final list = ReactiveList<int>([1, 2, 3]);
        expect(() => list.value.add(4), throwsUnsupportedError);
      });
    });

    group('add operations', () {
      test('add notifies listeners', () {
        final list = ReactiveList<int>();
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.add(1);

        expect(list.length, equals(1));
        expect(notificationCount, equals(1));
      });

      test('addAll notifies listeners', () {
        final list = ReactiveList<int>();
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.addAll([1, 2, 3]);

        expect(list.length, equals(3));
        expect(notificationCount, equals(1));
      });

      test('insert notifies listeners', () {
        final list = ReactiveList<int>([1, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.insert(1, 2);

        expect(list, equals([1, 2, 3]));
        expect(notificationCount, equals(1));
      });

      test('insertAll notifies listeners', () {
        final list = ReactiveList<int>([1, 4]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.insertAll(1, [2, 3]);

        expect(list, equals([1, 2, 3, 4]));
        expect(notificationCount, equals(1));
      });
    });

    group('remove operations', () {
      test('remove notifies when element exists', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        final removed = list.remove(2);

        expect(removed, isTrue);
        expect(list, equals([1, 3]));
        expect(notificationCount, equals(1));
      });

      test('remove does not notify when element does not exist', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        final removed = list.remove(5);

        expect(removed, isFalse);
        expect(notificationCount, equals(0));
      });

      test('removeAt notifies listeners', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        final removed = list.removeAt(1);

        expect(removed, equals(2));
        expect(list, equals([1, 3]));
        expect(notificationCount, equals(1));
      });

      test('removeLast notifies listeners', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        final removed = list.removeLast();

        expect(removed, equals(3));
        expect(list, equals([1, 2]));
        expect(notificationCount, equals(1));
      });

      test('removeWhere notifies when elements removed', () {
        final list = ReactiveList<int>([1, 2, 3, 4, 5]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.removeWhere((e) => e.isEven);

        expect(list, equals([1, 3, 5]));
        expect(notificationCount, equals(1));
      });

      test('removeWhere does not notify when no elements removed', () {
        final list = ReactiveList<int>([1, 3, 5]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.removeWhere((e) => e.isEven);

        expect(notificationCount, equals(0));
      });

      test('clear notifies when list is not empty', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.clear();

        expect(list.isEmpty, isTrue);
        expect(notificationCount, equals(1));
      });

      test('clear does not notify when list is already empty', () {
        final list = ReactiveList<int>();
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.clear();

        expect(notificationCount, equals(0));
      });
    });

    group('update operations', () {
      test('operator []= notifies listeners', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list[1] = 10;

        expect(list[1], equals(10));
        expect(notificationCount, equals(1));
      });

      test('sort notifies listeners', () {
        final list = ReactiveList<int>([3, 1, 2]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.sort();

        expect(list, equals([1, 2, 3]));
        expect(notificationCount, equals(1));
      });

      test('shuffle notifies listeners', () {
        final list = ReactiveList<int>([1, 2, 3, 4, 5]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.shuffle();

        expect(notificationCount, equals(1));
      });
    });

    group('custom reactive methods', () {
      test('replaceAll replaces all elements', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.replaceAll([4, 5, 6]);

        expect(list, equals([4, 5, 6]));
        expect(notificationCount, equals(1));
      });

      test('batch performs multiple operations with single notification', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.batch((l) {
          l.add(4);
          l.add(5);
          l.removeAt(0);
        });

        expect(list, equals([2, 3, 4, 5]));
        expect(notificationCount, equals(1));
      });

      test('silent does not notify', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.silent((l) {
          l.add(4);
          l.add(5);
        });

        expect(list, equals([1, 2, 3, 4, 5]));
        expect(notificationCount, equals(0));
      });

      test('refresh notifies listeners', () {
        final list = ReactiveList<int>([1, 2, 3]);
        int notificationCount = 0;
        list.addListener(() => notificationCount++);

        list.refresh();

        expect(notificationCount, equals(1));
      });
    });
  });
}
