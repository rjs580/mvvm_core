import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_core/mvvm_core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MVVM Core Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================================
// Home Page - Navigation to Examples
// ============================================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MVVM Core Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          _ExampleTile(
            title: 'Counter',
            subtitle: 'Basic Reactive usage',
            icon: Icons.add_circle_outline,
            onTap: () => _navigate(context, const CounterView()),
          ),
          _ExampleTile(
            title: 'Todo List',
            subtitle: 'ReactiveList with CRUD operations',
            icon: Icons.checklist,
            onTap: () => _navigate(context, const TodoView()),
          ),
          _ExampleTile(
            title: 'Async Data',
            subtitle: 'ReactiveFuture with loading states',
            icon: Icons.cloud_download,
            onTap: () => _navigate(context, const UserView()),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ============================================================================
// Example 1: Counter - Basic Reactive Usage
// ============================================================================

class CounterViewModel extends ViewModel {
  final Reactive<int> count = Reactive<int>(0);

  void increment() => count.value++;
  void decrement() => count.value--;
  void reset() => count.value = 0;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('count', count));
  }
}

class CounterView extends ViewHandler<CounterViewModel> {
  const CounterView({super.key});

  @override
  CounterViewModel viewModelFactory() => CounterViewModel();

  @override
  Widget build(
    BuildContext context,
    CounterViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.reset,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Center(
        child: viewModel.count.listen(
          builder: (context, count, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
              const SizedBox(height: 16),
              Text('$count', style: Theme.of(context).textTheme.displayLarge),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'increment',
            onPressed: viewModel.increment,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'decrement',
            onPressed: viewModel.decrement,
            tooltip: 'Decrement',
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Example 2: Todo List - ReactiveList Usage
// ============================================================================

class Todo {
  Todo({required this.title, this.completed = false});

  final String title;
  final bool completed;

  Todo copyWith({String? title, bool? completed}) {
    return Todo(
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() => 'Todo(title: $title, completed: $completed)';
}

class TodoViewModel extends ViewModel {
  final ReactiveList<Todo> todos = ReactiveList<Todo>([
    Todo(title: 'Learn MVVM Core'),
    Todo(title: 'Build an awesome app'),
    Todo(title: 'Share with the community'),
  ]);

  final Reactive<String> newTodoText = Reactive<String>('');

  int get completedCount => todos.where((t) => t.completed).length;
  int get totalCount => todos.length;

  void addTodo() {
    if (newTodoText.value.trim().isEmpty) return;
    todos.add(Todo(title: newTodoText.value.trim()));
    newTodoText.value = '';
  }

  void toggleTodo(int index) {
    todos[index] = todos[index].copyWith(completed: !todos[index].completed);
  }

  void deleteTodo(int index) {
    todos.removeAt(index);
  }

  void clearCompleted() {
    todos.removeWhere((todo) => todo.completed);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('todos', todos));
    properties.add(IntProperty('completedCount', completedCount));
  }
}

class TodoView extends ViewHandler<TodoViewModel> {
  const TodoView({super.key});

  @override
  TodoViewModel viewModelFactory() => TodoViewModel();

  @override
  Widget build(BuildContext context, TodoViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Only rebuild this part when todos change
          viewModel.todos.select(
            selector: (todos) => todos.any((t) => t.completed),
            builder: (context, hasCompleted) => IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: hasCompleted ? viewModel.clearCompleted : null,
              tooltip: 'Clear completed',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Input field
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Add a new todo...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => viewModel.newTodoText.value = value,
                    onSubmitted: (_) => viewModel.addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                viewModel.newTodoText.listen(
                  builder: (context, text, _) => IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: text.trim().isNotEmpty
                        ? viewModel.addTodo
                        : null,
                  ),
                ),
              ],
            ),
          ),

          // Stats bar
          viewModel.todos.listen(
            builder: (context, todos, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${viewModel.completedCount}/${viewModel.totalCount} completed',
                  ),
                  if (todos.isEmpty)
                    const Text('Add your first todo!')
                  else if (viewModel.completedCount == viewModel.totalCount)
                    const Text('🎉 All done!'),
                ],
              ),
            ),
          ),

          // Todo list
          Expanded(
            child: viewModel.todos.listen(
              builder: (context, todos, _) => todos.isEmpty
                  ? const Center(child: Text('No todos yet'))
                  : ListView.builder(
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        return ListTile(
                          leading: Checkbox(
                            value: todo.completed,
                            onChanged: (_) => viewModel.toggleTodo(index),
                          ),
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => viewModel.deleteTodo(index),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Example 3: Async Data - ReactiveFuture Usage
// ============================================================================

class User {
  User({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}

class UserViewModel extends ViewModel {
  final ReactiveFuture<User> user = ReactiveFuture<User>.idle();

  @override
  void init(BuildContext context) {
    super.init(context);
    loadUser();
  }

  Future<void> loadUser() async {
    await user.run(() async {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random success/failure
      if (DateTime.now().millisecond % 5 == 0) {
        throw Exception('Network error');
      }

      return User(id: 1, name: 'John Doe', email: 'john.doe@example.com');
    });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('user', user));
  }
}

class UserView extends ViewHandler<UserViewModel> {
  const UserView({super.key});

  @override
  UserViewModel viewModelFactory() => UserViewModel();

  @override
  Widget build(BuildContext context, UserViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Async Data'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.loadUser,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Center(
        child: viewModel.user.listenWhen(
          idle: () => ElevatedButton(
            onPressed: viewModel.loadUser,
            child: const Text('Load User'),
          ),
          loading: () => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading user...'),
            ],
          ),
          data: (user) => Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      user.name[0],
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('User ID: ${user.id}'),
                ],
              ),
            ),
          ),
          error: (error, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load user',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: viewModel.loadUser,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
