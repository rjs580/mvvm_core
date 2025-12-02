import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

class TestViewModel extends ViewModel {
  final counter = Reactive<int>(0);
  int initCallCount = 0;
  int disposeCallCount = 0;

  @override
  void init(BuildContext context) {
    super.init(context);
    initCallCount++;
  }

  @override
  void dispose() {
    disposeCallCount++;
    super.dispose();
  }
}

void main() {
  group('ViewModel', () {
    late TestViewModel viewModel;

    setUp(() {
      viewModel = TestViewModel();
    });

    tearDown(() {
      if (viewModel.mounted) {
        viewModel.dispose();
      }
    });

    group('initialization', () {
      test('starts unmounted', () {
        expect(viewModel.mounted, isFalse);
      });

      test('becomes mounted after init', () {
        final context = _MockBuildContext();
        viewModel.init(context);

        expect(viewModel.mounted, isTrue);
        expect(viewModel.initCallCount, equals(1));
      });

      test('provides context after init', () {
        final context = _MockBuildContext();
        viewModel.init(context);

        expect(viewModel.context, equals(context));
      });

      test('throws when accessing context before init', () {
        expect(() => viewModel.context, throwsA(isA<FlutterError>()));
      });
    });

    group('disposal', () {
      test('becomes unmounted after dispose', () {
        final context = _MockBuildContext();
        viewModel.init(context);
        viewModel.dispose();

        expect(viewModel.mounted, isFalse);
        expect(viewModel.disposeCallCount, equals(1));
      });

      test('throws when accessing context after dispose', () {
        final context = _MockBuildContext();
        viewModel.init(context);
        viewModel.dispose();

        expect(() => viewModel.context, throwsA(isA<FlutterError>()));
      });

      test('notifyListeners does nothing after dispose', () {
        final context = _MockBuildContext();
        viewModel.init(context);

        int notificationCount = 0;
        viewModel.addListener(() => notificationCount++);

        viewModel.notifyListeners();
        expect(notificationCount, equals(1));

        viewModel.dispose();

        // Should not throw or increment
        viewModel.notifyListeners();
        expect(notificationCount, equals(1));
      });
    });

    group('listeners', () {
      test('notifies listeners when notifyListeners is called', () {
        final context = _MockBuildContext();
        viewModel.init(context);

        int notificationCount = 0;
        viewModel.addListener(() => notificationCount++);

        viewModel.notifyListeners();
        expect(notificationCount, equals(1));

        viewModel.notifyListeners();
        expect(notificationCount, equals(2));
      });

      test('can remove listeners', () {
        final context = _MockBuildContext();
        viewModel.init(context);

        int notificationCount = 0;
        void listener() => notificationCount++;

        viewModel.addListener(listener);
        viewModel.notifyListeners();
        expect(notificationCount, equals(1));

        viewModel.removeListener(listener);
        viewModel.notifyListeners();
        expect(notificationCount, equals(1));
      });
    });
  });
}

class _MockBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
