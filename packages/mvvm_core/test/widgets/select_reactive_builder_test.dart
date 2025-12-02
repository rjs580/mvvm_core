import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvvm_core/mvvm_core.dart';

class User {
  User({required this.name, required this.age});
  final String name;
  final int age;

  User copyWith({String? name, int? age}) {
    return User(name: name ?? this.name, age: age ?? this.age);
  }
}

void main() {
  group('SelectReactiveBuilder', () {
    testWidgets('builds with selected value', (tester) async {
      final user = Reactive<User>(User(name: 'John', age: 25));

      await tester.pumpWidget(
        MaterialApp(
          home: SelectReactiveBuilder<User, String>(
            property: user,
            selector: (u) => u.name,
            builder: (context, name) => Text(name),
          ),
        ),
      );

      expect(find.text('John'), findsOneWidget);
    });

    testWidgets('rebuilds when selected value changes', (tester) async {
      final user = Reactive<User>(User(name: 'John', age: 25));
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SelectReactiveBuilder<User, String>(
            property: user,
            selector: (u) => u.name,
            builder: (context, name) {
              buildCount++;
              return Text(name);
            },
          ),
        ),
      );

      expect(buildCount, equals(1));

      user.value = user.value.copyWith(name: 'Jane');
      await tester.pump();

      expect(buildCount, equals(2));
      expect(find.text('Jane'), findsOneWidget);
    });

    testWidgets('does not rebuild when unselected value changes', (tester) async {
      final user = Reactive<User>(User(name: 'John', age: 25));
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SelectReactiveBuilder<User, String>(
            property: user,
            selector: (u) => u.name,
            builder: (context, name) {
              buildCount++;
              return Text(name);
            },
          ),
        ),
      );

      expect(buildCount, equals(1));

      // Change age, not name
      user.value = user.value.copyWith(age: 30);
      await tester.pump();

      expect(buildCount, equals(1)); // Should NOT rebuild
      expect(find.text('John'), findsOneWidget);
    });

    testWidgets('works with select extension method', (tester) async {
      final user = Reactive<User>(User(name: 'John', age: 25));
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: user.select(
            selector: (u) => u.age,
            builder: (context, age) {
              buildCount++;
              return Text('Age: $age');
            },
          ),
        ),
      );

      expect(find.text('Age: 25'), findsOneWidget);
      expect(buildCount, equals(1));

      // Change name - should not rebuild
      user.value = user.value.copyWith(name: 'Jane');
      await tester.pump();
      expect(buildCount, equals(1));

      // Change age - should rebuild
      user.value = user.value.copyWith(age: 30);
      await tester.pump();
      expect(buildCount, equals(2));
      expect(find.text('Age: 30'), findsOneWidget);
    });
  });
}
