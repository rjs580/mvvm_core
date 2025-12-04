# MVVM Core

[![pub package](https://img.shields.io/pub/v/mvvm_core.svg)](https://pub.dev/packages/mvvm_core)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)

A simple yet powerful MVVM state management library for Flutter. Built on Flutter's native primitives with zero external dependencies.

<p align="center">
  <img src="https://raw.githubusercontent.com/rjs580/mvvm_core/main/assets/mvvm_core_architecture.svg" alt="MVVM Architecture" width="250"/>
</p>

---

## ✨ Features

- **🎯 Simple & Intuitive** — Easy to learn, minimal boilerplate
- **⚡ Reactive Primitives** — `Reactive`, `ReactiveFuture`, `ReactiveStream`
- **📦 Reactive Collections** — `ReactiveList`, `ReactiveMap`, `ReactiveSet`
- **🔄 Async State Management** — Built-in loading, error, and data states
- **🛠️ DevTools Integration** — Inspect ViewModels in Flutter DevTools
- **🧪 Testable** — Easy to test ViewModels in isolation
- **📱 Zero Dependencies** — Only Flutter SDK required

---

## 📦 Installation

Add `mvvm_core` to your `pubspec.yaml`:
```yaml
dependencies:
  mvvm_core: ^1.0.0
```
Then run:
```bash
flutter pub get
```
---

## 🚀 Quick Start

### 1. Create a ViewModel
```dart
import 'package:mvvm_core/mvvm_core.dart';

class CounterViewModel extends ViewModel {
  final count = Reactive<int>(0);

  void increment() => count.value++;

  void decrement() => count.value--;
  
  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('count', count));
  }
}
```
### 2. Create a View

```dart
class CounterView extends ViewHandler<CounterViewModel> {
  const CounterView({super.key});

  @override
  CounterViewModel viewModelFactory() => CounterViewModel();

  @override
  Widget build(BuildContext context, CounterViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: viewModel.count.listen(
          builder: (context, count, _) =>
              Text(
                '$count',
                style: Theme
                    .of(context)
                    .textTheme
                    .displayLarge,
              ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: viewModel.increment,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: viewModel.decrement,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
```
That's it! Your counter app is ready with clean separation between UI and logic.

---

## 📖 Core Concepts

### Reactive\<T\>

A simple reactive wrapper for synchronous values:
```dart
final name = Reactive<String>('');
final isEnabled = Reactive<bool>(true);
final count = Reactive<int>(0);

// Read value
print(count.value); // 0

// Update value
count.value = 10;
count.value++;

// Transform value
name.update((current) => current.toUpperCase());

// Listen in UI
count.listen(
  builder: (context, value, _) => Text('$value'),
)
```
### ReactiveFuture\<T\>

Handle async operations with built-in loading/error states:
```dart
class UserViewModel extends ViewModel {
  final user = ReactiveFuture<User>.idle();

  // Call loadUser() from init(), button press, or other triggers
  Future<void> loadUser(String id) async {
    await user.run(() => userRepository.getUser(id));
  }
}

// In the view
vm.user.listenWhen(
  idle: () => const Text('Enter ID to search'),
  loading: () => const CircularProgressIndicator(),
  data: (user) => UserCard(user: user),
  error: (e, _) => Text('Error: $e'),
)
```
### ReactiveStream\<T\>

React to stream events in real-time:
```dart
class ChatViewModel extends ViewModel {
  final messages = ReactiveStream<Message>.idle();

  // Call connect() from init(), button press, or other triggers
  void connect(String roomId) {
    // chatService.getMessages() returns a Stream<Message> that emits new messages
    // We bind this stream to our reactive stream to handle its events
    messages.bind(chatService.getMessages(roomId));
  }

  @override
  void dispose() {
    messages.cancel();
    super.dispose();
  }
}

// In the view
vm.messages.listenWhen(
  loading: () => const Text('Connecting...'),
  data: (message) => MessageBubble(message: message),
  error: (e, _) => const Text('Disconnected'),
  done: (_) => const Text('Chat ended'),
)
```
### Reactive Collections

Full-featured reactive collections that notify on changes:
```dart
// ReactiveList
final todos = ReactiveList<Todo>([]);
todos.add(Todo('Buy milk'));
todos.removeWhere((t) => t.completed);
todos[0] = todos[0].copyWith(completed: true);

// ReactiveMap
final settings = ReactiveMap<String, dynamic>({'theme': 'dark'});
settings['language'] = 'en';
settings.remove('deprecated');

// ReactiveSet
final selectedIds = ReactiveSet<String>();
selectedIds.add('item_1');
selectedIds.remove('item_2');
```
#### Batch Operations

Perform multiple updates with a single notification:
```dart
// Only one rebuild will be triggered!
todos.batch((list) {
  list.add(Todo('Task 1'));
  list.add(Todo('Task 2'));
  list.removeAt(0);
  list.sort((a, b) => a.priority.compareTo(b.priority));
});
```
---

## 🎯 AsyncState

All async properties use the `AsyncState` sealed class for type-safe state handling:

| State          | Description           |
|----------------|-----------------------|
| `AsyncIdle`    | Operation not started |
| `AsyncLoading` | Operation in progress |
| `AsyncData`    | Success with data     |
| `AsyncError`   | Error with details    |
| `StreamDone`   | Stream completed      |

### Pattern Matching
```dart
// Exhaustive matching
state.when(
  idle: () => const Text('Ready'),
  loading: () => const CircularProgressIndicator(),
  data: (user) => Text(user.name),
  error: (e, stackTrace) => Text('Error: $e'),
  // Optional for streams
  done: (lastMsg) => Text('Stream ended. Last: ${lastMsg?.content}'),
);

// Partial matching
state.maybeWhen(
  error: (e, _) => showErrorSnackbar(e),
  orElse: () {},
);

// With previous data access
state.whenWithPrevious(
  idle: () => const Text('Ready'),
  loading: (previousData) => previousData != null
    ? RefreshIndicator(child: UserCard(previousData))
    : const LoadingSpinner(),
  data: (user) => UserCard(user),
  error: (e, _, previousData) => ErrorWithRetry(
    error: e,
    cachedData: previousData,
  ),
);
```
---

## 🔍 Selective Rebuilds

Optimize performance by only rebuilding when specific values change:
```dart
// Only rebuilds when email changes, not when name or age changes
viewModel.user.select(
  selector: (user) => user.email,
  builder: (context, email) => Text(email),
)

// Select multiple values using records
viewModel.user.select(
  selector: (user) => (user.firstName, user.lastName),
  builder: (context, names) {
    final (first, last) = names;
    return Text('$first $last');
  },
)
```
---

## 🔗 Multiple Properties

Listen to multiple reactive properties at once:
```dart
MultiReactiveBuilder(
  properties: [
    viewModel.firstName, 
    viewModel.lastName, 
    viewModel.age,
  ],
  builder: (context, _) => Text(
    '${vm.firstName.value} ${vm.lastName.value}, ${vm.age.value}',
  ),
)
```
---

## 🎛️ ViewHandler Features

### Lifecycle Hooks
```dart
class UserProfileView extends ViewHandler<UserProfileViewModel> {
  const UserProfileView({super.key, required this.userId});

  final String userId;

  @override
  UserProfileViewModel viewModelFactory() => UserProfileViewModel();

  @override
  void init(UserProfileViewModel viewModel) {
    super.init(viewModel);
    // This lifecycle method is also present in the ViewModel 
    // and do not need to be overridden here
    viewModel.loadUser(userId); // Called when view is mounted
  }

  @override
  void dispose(UserProfileViewModel viewModel) {
    // This lifecycle method is also present in the ViewModel 
    // and do not need to be overridden here
    viewModel.cancelSubscriptions(); // Called when view is unmounted
    super.dispose(viewModel);
  }

  @override
  Widget build(BuildContext context, UserProfileViewModel viewModel, Widget? child) {
    // ...
  }
}
```
### Child Optimization

Cache expensive widgets that don't need rebuilding:
```dart
class TodoListView extends ViewHandler<TodoListViewModel> {
  @override
  Widget? child(BuildContext context) {
    // This widget won't rebuild when ViewModel changes
    return const ExpensiveHeader();
  }

  @override
  Widget build(BuildContext context, TodoListViewModel vm, Widget? child) {
    return Column(
      children: [
        child!, // Reused across rebuilds
        Expanded(
          child: vm.todos.listen(
            builder: (context, todos, _) => TodoList(todos: todos),
          ),
        ),
      ],
    );
  }
}
```
### Navigation Control

Control back navigation with PopScope integration:
```dart
class FormView extends ViewHandler<FormViewModel> {
  @override
  bool get canPop => false; // Prevent back navigation

  @override
  PopInvokedContextWithResultCallback<dynamic>? get onPopInvokedWithResult =>
          (context, didPop, result) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (_) => const DiscardChangesDialog(),
          );
        }
      };

  // ...
}
```
---

## 🛠️ DevTools Integration

Inspect your ViewModels in real-time with the built-in DevTools extension.

### Setup

1. Enable the MVVM Core DevTools Extension:
    - In your Flutter app, navigate to Flutter DevTools
    - Go to Settings (<img src="https://raw.githubusercontent.com/flutter/devtools/master/packages/devtools_app/icons/app_bar/devtools_extensions.png" alt="DevTools Extension Icon" width="20"/>)
    - Enable the "MVVM Core" extension
    
2. Override `debugFillProperties` in your ViewModels:
    ```dart
    class MyViewModel extends ViewModel {
      final count = Reactive<int>(0);
      final user = ReactiveFuture<User>.idle();
    
      @override
      void debugFillProperties(DiagnosticPropertiesBuilder properties) {
        super.debugFillProperties(properties);
        properties.add(DiagnosticsProperty('count', count));
        properties.add(DiagnosticsProperty('user', user));
      }
    }
    ```
3. Open DevTools and look for the **MVVM Core** tab!
    <p align="center">
        <img src="https://raw.githubusercontent.com/rjs580/mvvm_core/main/assets/devtools_screenshot.png" alt="DevTools Extension" width="700"/>
    </p>

---

## 🧪 Testing

ViewModels are easy to test in isolation:
```dart
void main() {
  group('CounterViewModel', () {
    late CounterViewModel vm;

    setUp(() {
      vm = CounterViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('initial count is 0', () {
      expect(vm.count.value, equals(0));
    });

    test('increment increases count', () {
      vm.increment();
      expect(vm.count.value, equals(1));
    });

    test('notifies listeners on change', () {
      int notifications = 0;
      vm.count.addListener(() => notifications++);

      vm.increment();

      expect(notifications, equals(1));
    });
  });

  group('UserViewModel', () {
    late UserViewModel vm;
    late MockUserRepository mockRepository;

    setUp(() {
      mockRepository = MockUserRepository();
      vm = UserViewModel(repository: mockRepository);
    });

    test('loadUser sets loading then data state', () async {
      when(() => mockRepository.getUser('123'))
          .thenAnswer((_) async => User(id: '123', name: 'John'));

      expect(vm.user.value.isIdle, isTrue);

      final future = vm.loadUser('123');

      expect(vm.user.value.isLoading, isTrue);

      await future;

      expect(vm.user.value.hasData, isTrue);
      expect(vm.user.data?.name, equals('John'));
    });
  });
}
```
---

## 📊 Comparison

| Feature | MVVM Core | Bloc | Riverpod | Provider |
|---------|-----------|------|----------|----------|
| Learning Curve | 🟢 Easy | 🟡 Medium | 🟡 Medium | 🟢 Easy |
| Boilerplate | 🟢 Minimal | 🔴 High | 🟡 Medium | 🟢 Minimal |
| Async Handling | 🟢 Built-in | 🟡 Manual | 🟢 Built-in | 🔴 Manual |
| Collections | 🟢 Built-in | 🔴 Manual | 🔴 Manual | 🔴 Manual |
| DevTools | 🟢 Yes | 🟢 Yes | 🟢 Yes | 🟡 Basic |
| Code Generation | 🟢 Not needed | 🟡 Optional | 🟡 Optional | 🟢 Not needed |
| Dependencies | 🟢 Zero | 🟡 2+ | 🟡 2+ | 🟢 Zero |
| Type Safety | 🟢 Sealed classes | 🟢 Yes | 🟢 Yes | 🟡 Basic |

---

## 🔄 Migration Guide

### From setState
```dart
// Before
class _MyWidgetState extends State<MyWidget> {
  int count = 0;

  void increment() => setState(() => count++);

  @override
  Widget build(BuildContext context) {
    return Text('$count');
  }
}

// After
class CounterViewModel extends ViewModel {
  final count = Reactive<int>(0);

  void increment() => count.value++;
}

class CounterView extends ViewHandler<CounterViewModel> {
  @override
  CounterViewModel viewModelFactory() => CounterViewModel();

  @override
  Widget build(BuildContext context, CounterViewModel vm, Widget? child) {
    return vm.count.listen(
      builder: (context, count, _) => Text('$count'),
    );
  }
}
```
### From Provider/ChangeNotifier
```dart
// Before
class CounterProvider extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

// After
class CounterViewModel extends ViewModel {
  final count = Reactive<int>(0);

  void increment() => count.value++;
}
```
### From Bloc/Cubit
```dart
// Before
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
}

// After
class CounterViewModel extends ViewModel {
  final count = Reactive<int>(0);

  void increment() => count.value++;
}
```
---

## 📚 Examples

### Todo App
```dart
class TodoViewModel extends ViewModel {
  final todos = ReactiveList<Todo>([]);
  final filter = Reactive<TodoFilter>(TodoFilter.all);

  List<Todo> get filteredTodos =>
      switch (filter.value) {
        TodoFilter.all => todos.value,
        TodoFilter.active => todos.where((t) => !t.completed).toList(),
        TodoFilter.completed => todos.where((t) => t.completed).toList(),
      };

  void addTodo(String title) {
    todos.add(Todo(id: uuid(), title: title));
  }

  void toggleTodo(String id) {
    final index = todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      todos[index] = todos[index].copyWith(
        completed: !todos[index].completed,
      );
    }
  }

  void deleteTodo(String id) {
    todos.removeWhere((t) => t.id == id);
  }

  void clearCompleted() {
    todos.removeWhere((t) => t.completed);
  }
}
```
### Authentication Flow
```dart
class AuthViewModel extends ViewModel {
  final authState = ReactiveFuture<User?>.idle();
  final isLoggedIn = Reactive<bool>(false);

  Future<void> login(String email, String password) async {
    final user = await authState.run(
          () => authService.login(email, password),
    );

    if (user != null) {
      isLoggedIn.value = true;
    }
  }

  Future<void> logout() async {
    await authService.logout();
    isLoggedIn.value = false;
    authState.reset();
  }
}
```
### Search with Debounce
```dart
class SearchViewModel extends ViewModel {
  final query = Reactive<String>('');
  final results = ReactiveFuture<List<Item>>.idle();

  Timer? _debounceTimer;

  void onQueryChanged(String value) {
    query.value = value;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (value.isEmpty) {
        results.reset();
      } else {
        // Calling run() while a previous operation
        // is in progress will cancel the previous run
        results.run(() => searchService.search(value));
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```
---

## 📄 API Reference

See the [API documentation](https://pub.dev/documentation/mvvm_core/latest/) for detailed information on all classes and methods.

### Core Classes

| Class | Description |
|-------|-------------|
| `ViewModel` | Base class for all ViewModels |
| `ViewHandler<T>` | Widget that binds a ViewModel to a view |
| `Reactive<T>` | Reactive wrapper for synchronous values |
| `ReactiveFuture<T>` | Reactive wrapper for Future operations |
| `ReactiveStream<T>` | Reactive wrapper for Stream operations |
| `ReactiveList<E>` | Reactive List implementation |
| `ReactiveMap<K, V>` | Reactive Map implementation |
| `ReactiveSet<E>` | Reactive Set implementation |
| `AsyncState<T>` | Sealed class for async operation states |

### Builder Widgets

| Widget | Description |
|--------|-------------|
| `ReactiveBuilder<T>` | Rebuilds when a single property changes |
| `SelectReactiveBuilder<T, R>` | Rebuilds only when selected value changes |
| `MultiReactiveBuilder` | Rebuilds when any of multiple properties change |

---

## 💡 Contributions

- Want to help? Open an issue or submit a pull request!
- Improve the docs, add new features, or fix bugs
- Built with ❤️ for the Flutter community

---

<p align="center">
  <a href="https://github.com/rjs580/mvvm_core">
    <img src="https://img.shields.io/github/stars/rjs580/mvvm_core?style=social" alt="GitHub stars"/>
  </a>
  <a href="https://pub.dev/packages/mvvm_core">
    <img src="https://img.shields.io/pub/likes/mvvm_core" alt="Pub likes"/>
  </a>
</p>

<p align="center">
  If you find this package helpful, please ⭐ the repo!
</p>
