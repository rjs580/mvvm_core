import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  group('MultiReactiveBuilder', () {
    testWidgets('builds with multiple properties', (tester) async {
      final firstName = Reactive<String>('John');
      final lastName = Reactive<String>('Doe');

      await tester.pumpWidget(
        MaterialApp(
          home: MultiReactiveBuilder(
            properties: [firstName, lastName],
            builder: (context, _) => Text(
              '${firstName.value} ${lastName.value}',
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('rebuilds when any property changes', (tester) async {
      final firstName = Reactive<String>('John');
      final lastName = Reactive<String>('Doe');
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiReactiveBuilder(
            properties: [firstName, lastName],
            builder: (context, _) {
              buildCount++;
              return Text('${firstName.value} ${lastName.value}');
            },
          ),
        ),
      );

      expect(buildCount, equals(1));

      firstName.value = 'Jane';
      await tester.pump();

      expect(buildCount, equals(2));
      expect(find.text('Jane Doe'), findsOneWidget);

      lastName.value = 'Smith';
      await tester.pump();

      expect(buildCount, equals(3));
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('passes child to builder', (tester) async {
      final reactive = Reactive<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiReactiveBuilder(
            properties: [reactive],
            child: const Text('static'),
            builder: (context, child) => Column(
              children: [
                Text('${reactive.value}'),
                child!,
              ],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('static'), findsOneWidget);
    });

    testWidgets('child is not rebuilt', (tester) async {
      final reactive = Reactive<int>(0);
      int childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiReactiveBuilder(
            properties: [reactive],
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('child');
              },
            ),
            builder: (context, child) => Column(
              children: [
                Text('${reactive.value}'),
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

    testWidgets('works with different property types', (tester) async {
      final count = Reactive<int>(0);
      final name = Reactive<String>('Test');
      final items = ReactiveList<String>(['a', 'b']);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiReactiveBuilder(
            properties: [count, name, items],
            builder: (context, _) => Text(
              '${count.value} - ${name.value} - ${items.length}',
            ),
          ),
        ),
      );

      expect(find.text('0 - Test - 2'), findsOneWidget);

      items.add('c');
      await tester.pump();

      expect(find.text('0 - Test - 3'), findsOneWidget);
    });
  });
}
