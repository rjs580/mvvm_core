/// Tests for the mvvm_core library.
///
/// This file contains integration tests and verifies that all public APIs
/// are properly exported and work together.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('mvvm_core exports', () {
    test('exports core classes', () {
      // Verify core classes are exported
      expect(ViewModel, isNotNull);
      expect(ViewHandler, isNotNull);
    });

    test('exports reactive primitives', () {
      // Verify reactive primitives are exported
      expect(ReactiveProperty, isNotNull);
      expect(Reactive, isNotNull);
      expect(ReactiveFuture, isNotNull);
      expect(ReactiveStream, isNotNull);
    });

    test('exports reactive collections', () {
      // Verify reactive collections are exported
      expect(ReactiveList, isNotNull);
      expect(ReactiveMap, isNotNull);
      expect(ReactiveSet, isNotNull);
    });

    test('exports async state classes', () {
      // Verify async state classes are exported
      expect(AsyncState, isNotNull);
      expect(AsyncIdle, isNotNull);
      expect(AsyncLoading, isNotNull);
      expect(AsyncData, isNotNull);
      expect(AsyncError, isNotNull);
      expect(StreamDone, isNotNull);
    });

    test('exports builder widgets', () {
      // Verify builder widgets are exported
      expect(ReactiveBuilder, isNotNull);
      expect(SelectReactiveBuilder, isNotNull);
      expect(MultiReactiveBuilder, isNotNull);
    });

    test('exports typedef', () {
      // Verify typedefs work (compile-time check)
      PopInvokedContextWithResultCallback<String>? callback;
      expect(callback, isNull); // Just verify it compiles
    });
  });

  group('mvvm_core integration', () {
    test('complete MVVM flow works', () {
      // Create a ViewModel
      final viewModel = _TestViewModel();

      // Verify initial state
      expect(viewModel.counter.value, equals(0));
      expect(viewModel.mounted, isFalse);

      // Initialize
      viewModel.init(_MockBuildContext());
      expect(viewModel.mounted, isTrue);

      // Update state
      viewModel.increment();
      expect(viewModel.counter.value, equals(1));

      // Dispose
      viewModel.dispose();
      expect(viewModel.mounted, isFalse);
    });

    test('reactive collections integrate with ViewModel', () {
      final viewModel = _CollectionViewModel();
      viewModel.init(_MockBuildContext());

      // Test ReactiveList
      viewModel.items.add('item1');
      expect(viewModel.items.length, equals(1));

      // Test ReactiveMap
      viewModel.settings['key'] = 'value';
      expect(viewModel.settings['key'], equals('value'));

      // Test ReactiveSet
      viewModel.tags.add('tag1');
      expect(viewModel.tags.contains('tag1'), isTrue);

      viewModel.dispose();
    });

    test('ReactiveFuture integrates with ViewModel', () async {
      final viewModel = _AsyncViewModel();
      viewModel.init(_MockBuildContext());

      expect(viewModel.data.value.isIdle, isTrue);

      await viewModel.loadData();

      expect(viewModel.data.value.hasData, isTrue);
      expect(viewModel.data.data, equals('loaded'));

      viewModel.dispose();
    });

    test('ReactiveStream integrates with ViewModel', () async {
      final viewModel = _StreamViewModel();
      viewModel.init(_MockBuildContext());

      expect(viewModel.events.value.isIdle, isTrue);

      viewModel.startListening();
      expect(viewModel.events.isActive, isTrue);

      // Simulate stream event
      viewModel.simulateEvent('event1');
      await Future.delayed(Duration.zero);

      expect(viewModel.events.data, equals('event1'));

      viewModel.dispose();
    });

    testWidgets('ViewHandler creates and manages ViewModel', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestView()));

      // Verify view is rendered
      expect(find.text('Count: 0'), findsOneWidget);

      // Find and interact with increment button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Verify state updated
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('MultiReactiveBuilder works with mixed property types', (
      tester,
    ) async {
      final count = Reactive<int>(0);
      final name = Reactive<String>('Test');
      final items = ReactiveList<String>(['a']);
      final settings = ReactiveMap<String, int>({'x': 1});

      await tester.pumpWidget(
        MaterialApp(
          home: MultiReactiveBuilder(
            properties: [count, name, items, settings],
            builder: (context, _) => Text(
              '${count.value}-${name.value}-${items.length}-${settings.length}',
            ),
          ),
        ),
      );

      expect(find.text('0-Test-1-1'), findsOneWidget);

      // Update different property types
      count.value = 5;
      await tester.pump();
      expect(find.text('5-Test-1-1'), findsOneWidget);

      items.add('b');
      await tester.pump();
      expect(find.text('5-Test-2-1'), findsOneWidget);

      settings['y'] = 2;
      await tester.pump();
      expect(find.text('5-Test-2-2'), findsOneWidget);
    });

    testWidgets('SelectReactiveBuilder optimizes rebuilds', (tester) async {
      final user = Reactive<_User>(_User('John', 25));
      int nameBuilds = 0;
      int ageBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              user.select(
                selector: (u) => u.name,
                builder: (context, name) {
                  nameBuilds++;
                  return Text('Name: $name');
                },
              ),
              user.select(
                selector: (u) => u.age,
                builder: (context, age) {
                  ageBuilds++;
                  return Text('Age: $age');
                },
              ),
            ],
          ),
        ),
      );

      expect(nameBuilds, equals(1));
      expect(ageBuilds, equals(1));

      // Change only name
      user.value = _User('Jane', 25);
      await tester.pump();

      expect(nameBuilds, equals(2)); // Rebuilt
      expect(ageBuilds, equals(1)); // NOT rebuilt

      // Change only age
      user.value = _User('Jane', 30);
      await tester.pump();

      expect(nameBuilds, equals(2)); // NOT rebuilt
      expect(ageBuilds, equals(2)); // Rebuilt
    });

    test('AsyncState pattern matching is exhaustive', () {
      // This test verifies that all AsyncState subclasses are handled
      final states = <AsyncState<String>>[
        const AsyncIdle<String>(),
        const AsyncLoading<String>(),
        const AsyncData<String>('data'),
        AsyncError<String>(Exception('error'), StackTrace.current),
        const StreamDone<String>('last'),
      ];

      for (final state in states) {
        // This should compile and not throw - verifies exhaustive matching
        final result = switch (state) {
          AsyncIdle<String>() => 'idle',
          AsyncLoading<String>() => 'loading',
          AsyncData<String>() => 'data',
          AsyncError<String>() => 'error',
          StreamDone<String>() => 'done',
        };

        expect(result, isNotNull);
      }
    });
  });

  group('edge cases', () {
    test('Reactive handles null values', () {
      final nullable = Reactive<String?>(null);
      expect(nullable.value, isNull);

      nullable.value = 'value';
      expect(nullable.value, equals('value'));

      nullable.value = null;
      expect(nullable.value, isNull);
    });

    test('ReactiveList handles empty operations', () {
      final list = ReactiveList<int>();
      int notifications = 0;
      list.addListener(() => notifications++);

      // Empty operations should not notify
      list.clear();
      list.addAll([]);
      list.removeWhere((_) => true);

      expect(notifications, equals(0));
    });

    test('ReactiveMap handles empty operations', () {
      final map = ReactiveMap<String, int>();
      int notifications = 0;
      map.addListener(() => notifications++);

      // Empty operations should not notify
      map.clear();
      map.addAll({});

      expect(notifications, equals(0));
    });

    test('ReactiveSet handles duplicate additions', () {
      final set = ReactiveSet<int>({1, 2, 3});
      int notifications = 0;
      set.addListener(() => notifications++);

      // Adding existing elements should not notify
      set.add(1);
      set.addAll({1, 2});

      expect(notifications, equals(0));
    });

    test('ReactiveFuture handles rapid successive calls', () async {
      final future = ReactiveFuture<int>.idle();
      int notifications = 0;
      future.addListener(() => notifications++);

      // Start multiple operations rapidly
      unawaited(
        future.run(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 1;
        }),
      );

      unawaited(
        future.run(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 2;
        }),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Last one should win
      expect(future.data, equals(2));
    });

    test('ViewModel notifyListeners is safe after dispose', () {
      final viewModel = _TestViewModel();
      viewModel.init(_MockBuildContext());

      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.notifyListeners();
      expect(notifications, equals(1));

      viewModel.dispose();

      // Should not throw or notify
      viewModel.notifyListeners();
      expect(notifications, equals(1));
    });
  });
}

// =============================================================================
// Test Helpers
// =============================================================================

class _MockBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TestViewModel extends ViewModel {
  final counter = Reactive<int>(0);

  void increment() => counter.value++;
}

class _CollectionViewModel extends ViewModel {
  final items = ReactiveList<String>();
  final settings = ReactiveMap<String, String>();
  final tags = ReactiveSet<String>();
}

class _AsyncViewModel extends ViewModel {
  final data = ReactiveFuture<String>.idle();

  Future<void> loadData() async {
    await data.run(() async {
      await Future.delayed(const Duration(milliseconds: 10));
      return 'loaded';
    });
  }
}

class _StreamViewModel extends ViewModel {
  final events = ReactiveStream<String>.idle();
  late final _controller = StreamController<String>();

  void startListening() {
    events.bind(_controller.stream);
  }

  void simulateEvent(String event) {
    _controller.add(event);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

class _TestView extends ViewHandler<_TestViewModel> {
  const _TestView();

  @override
  _TestViewModel viewModelFactory() => _TestViewModel();

  @override
  Widget build(BuildContext context, _TestViewModel vm, Widget? child) {
    return Scaffold(
      body: vm.counter.listen(
        builder: (context, count, _) => Text('Count: $count'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: vm.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _User {
  _User(this.name, this.age);
  final String name;
  final int age;
}

// Helper to ignore unawaited futures in tests
void unawaited(Future<void> future) {}
