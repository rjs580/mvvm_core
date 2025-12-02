# MVVM Core Example

This example demonstrates the usage of the `mvvm_core` package.

## Running the Example

```bash
cd example && flutter pub get && flutter run
```

## Examples Included

### 1. Counter
Basic usage of `Reactive<T>` for simple state management.

### 2. Todo List
Demonstrates `ReactiveList<T>` with:
- Adding/removing items
- Toggling item state
- Selective rebuilds with `select()`
- Batch operations

### 3. Async Data
Shows `ReactiveFuture<T>` with:
- Loading states
- Error handling
- Data display
- Refresh functionality