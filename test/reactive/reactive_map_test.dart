import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('ReactiveMap', () {
    group('initialization', () {
      test('creates empty map by default', () {
        final map = ReactiveMap<String, int>();
        expect(map.isEmpty, isTrue);
      });

      test('creates map with initial values', () {
        final map = ReactiveMap<String, int>({'a': 1, 'b': 2});
        expect(map.length, equals(2));
        expect(map['a'], equals(1));
        expect(map['b'], equals(2));
      });

      test('value returns unmodifiable view', () {
        final map = ReactiveMap<String, int>({'a': 1});
        expect(() => map.value['b'] = 2, throwsUnsupportedError);
      });
    });

    group('operations', () {
      test('operator []= notifies listeners', () {
        final map = ReactiveMap<String, int>();
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map['a'] = 1;

        expect(map['a'], equals(1));
        expect(notificationCount, equals(1));
      });

      test('remove notifies when key exists', () {
        final map = ReactiveMap<String, int>({'a': 1, 'b': 2});
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        final removed = map.remove('a');

        expect(removed, equals(1));
        expect(map.containsKey('a'), isFalse);
        expect(notificationCount, equals(1));
      });

      test('remove does not notify when key does not exist', () {
        final map = ReactiveMap<String, int>({'a': 1});
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        final removed = map.remove('b');

        expect(removed, isNull);
        expect(notificationCount, equals(0));
      });

      test('addAll notifies when adding entries', () {
        final map = ReactiveMap<String, int>();
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.addAll({'a': 1, 'b': 2});

        expect(map.length, equals(2));
        expect(notificationCount, equals(1));
      });

      test('addAll does not notify when empty', () {
        final map = ReactiveMap<String, int>();
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.addAll({});

        expect(notificationCount, equals(0));
      });

      test('clear notifies when not empty', () {
        final map = ReactiveMap<String, int>({'a': 1});
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.clear();

        expect(map.isEmpty, isTrue);
        expect(notificationCount, equals(1));
      });

      test('clear does not notify when already empty', () {
        final map = ReactiveMap<String, int>();
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.clear();

        expect(notificationCount, equals(0));
      });

      test('update notifies listeners', () {
        final map = ReactiveMap<String, int>({'a': 1});
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.update('a', (v) => v + 10);

        expect(map['a'], equals(11));
        expect(notificationCount, equals(1));
      });

      test('putIfAbsent notifies when key added', () {
        final map = ReactiveMap<String, int>();
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        final value = map.putIfAbsent('a', () => 1);

        expect(value, equals(1));
        expect(notificationCount, equals(1));
      });

      test('putIfAbsent does not notify when key exists', () {
        final map = ReactiveMap<String, int>({'a': 1});
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        final value = map.putIfAbsent('a', () => 2);

        expect(value, equals(1));
        expect(notificationCount, equals(0));
      });

      test('removeWhere notifies when entries removed', () {
        final map = ReactiveMap<String, int>({'a': 1, 'b': 2, 'c': 3});
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.removeWhere((k, v) => v.isEven);

        expect(map.keys, equals(['a', 'c']));
        expect(notificationCount, equals(1));
      });
    });

    group('custom reactive methods', () {
      test('replaceAll replaces all entries', () {
        final map = ReactiveMap<String, int>({'a': 1});
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.replaceAll({'x': 10, 'y': 20});

        expect(map.keys.toList(), equals(['x', 'y']));
        expect(notificationCount, equals(1));
      });

      test('batch performs multiple operations with single notification', () {
        final map = ReactiveMap<String, int>();
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.batch((m) {
          m['a'] = 1;
          m['b'] = 2;
          m['c'] = 3;
        });

        expect(map.length, equals(3));
        expect(notificationCount, equals(1));
      });

      test('silent does not notify', () {
        final map = ReactiveMap<String, int>();
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.silent((m) {
          m['a'] = 1;
        });

        expect(map['a'], equals(1));
        expect(notificationCount, equals(0));
      });

      test('refresh notifies listeners', () {
        final map = ReactiveMap<String, int>();
        int notificationCount = 0;
        map.addListener(() => notificationCount++);

        map.refresh();

        expect(notificationCount, equals(1));
      });
    });
  });
}
