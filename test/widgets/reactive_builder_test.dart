import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('ReactiveBuilder', () {
    testWidgets('builds with initial value', (tester) async {
      final reactive = Reactive<int>(42);

      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveBuilder<int>(
            property: reactive,
            builder: (context, value, _) => Text('$value'),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('rebuilds when value changes', (tester) async {
      final reactive = Reactive<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveBuilder<int>(
            property: reactive,
            builder: (context, value, _) => Text('$value'),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      reactive.value = 10;
      await tester.pump();

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('passes child to builder', (tester) async {
      final reactive = Reactive<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveBuilder<int>(
            property: reactive,
            child: const Text('child'),
            builder: (context, value, child) => Column(
              children: [
                Text('$value'),
                child!,
              ],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('child'), findsOneWidget);
    });

    testWidgets('child is not rebuilt', (tester) async {
      final reactive = Reactive<int>(0);
      int childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ReactiveBuilder<int>(
            property: reactive,
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('child');
              },
            ),
            builder: (context, value, child) => Column(
              children: [
                Text('$value'),
                child!,
              ],
            ),
          ),
        ),
      );

      expect(childBuildCount, equals(1));

      reactive.value = 10;
      await tester.pump();

      expect(childBuildCount, equals(1)); // Child not rebuilt
    });
  });

  group('ReactiveProperty.listen', () {
    testWidgets('creates ReactiveBuilder', (tester) async {
      final reactive = Reactive<String>('hello');

      await tester.pumpWidget(
        MaterialApp(
          home: reactive.listen(
            builder: (context, value, _) => Text(value),
          ),
        ),
      );

      expect(find.text('hello'), findsOneWidget);

      reactive.value = 'world';
      await tester.pump();

      expect(find.text('world'), findsOneWidget);
    });
  });
}
