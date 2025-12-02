import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

class TestViewModel extends ViewModel {
  final counter = Reactive<int>(0);
  bool wasInitCalled = false;
  bool wasDisposeCalled = false;

  @override
  void init(BuildContext context) {
    super.init(context);
    wasInitCalled = true;
  }

  @override
  void dispose() {
    wasDisposeCalled = true;
    super.dispose();
  }
}

class TestView extends ViewHandler<TestViewModel> {
  const TestView({super.key});

  static TestViewModel? lastViewModel;

  @override
  TestViewModel viewModelFactory() {
    lastViewModel = TestViewModel();
    return lastViewModel!;
  }

  @override
  Widget build(BuildContext context, TestViewModel vm, Widget? child) {
    return vm.counter.listen(
      builder: (context, count, _) {
        return Text('${vm.counter.value}');
      },
    );
  }
}

class TestViewWithChild extends ViewHandler<TestViewModel> {
  const TestViewWithChild({super.key});

  static int childBuildCount = 0;

  @override
  TestViewModel viewModelFactory() => TestViewModel();

  @override
  Widget? child(BuildContext context) {
    childBuildCount++;
    return const Text('child');
  }

  @override
  Widget build(BuildContext context, TestViewModel vm, Widget? child) {
    return Column(children: [Text('${vm.counter.value}'), child!]);
  }
}

class TestViewWithPopScope extends ViewHandler<TestViewModel> {
  const TestViewWithPopScope({
    super.key,
    this.canPopValue = true,
    this.removePopScopeValue = false,
  });

  final bool canPopValue;
  final bool removePopScopeValue;

  @override
  TestViewModel viewModelFactory() => TestViewModel();

  @override
  bool get canPop => canPopValue;

  @override
  bool get removePopScope => removePopScopeValue;

  @override
  Widget build(BuildContext context, TestViewModel vm, Widget? child) {
    return const Text('test');
  }
}

void main() {
  group('ViewHandler', () {
    testWidgets('creates and initializes ViewModel', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestView()));

      expect(TestView.lastViewModel, isNotNull);
      expect(TestView.lastViewModel!.wasInitCalled, isTrue);
      expect(TestView.lastViewModel!.mounted, isTrue);
    });

    testWidgets('builds with ViewModel', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestView()));

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('rebuilds when ViewModel changes', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestView()));

      expect(find.text('0'), findsOneWidget);

      TestView.lastViewModel!.counter.value = 10;

      await tester.pump();

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('disposes ViewModel when removed', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestView()));

      final vm = TestView.lastViewModel!;
      expect(vm.wasDisposeCalled, isFalse);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(vm.wasDisposeCalled, isTrue);
      expect(vm.mounted, isFalse);
    });

    testWidgets('child is built once', (tester) async {
      TestViewWithChild.childBuildCount = 0;

      await tester.pumpWidget(const MaterialApp(home: TestViewWithChild()));

      expect(TestViewWithChild.childBuildCount, equals(1));
      expect(find.text('child'), findsOneWidget);
    });

    testWidgets('includes PopScope by default', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestViewWithPopScope()));

      expect(find.byType(PopScope<dynamic>), findsOneWidget);
    });

    testWidgets('removes PopScope when removePopScope is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestViewWithPopScope(removePopScopeValue: true),
        ),
      );

      expect(find.byType(PopScope<dynamic>), findsNothing);
    });
  });
}
