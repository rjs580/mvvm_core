# MVVM Core DevTools Extension

A Flutter DevTools extension for inspecting and debugging [mvvm_core](https://pub.dev/packages/mvvm_core) ViewModels.

## Features

- 📋 **View all active ViewModels** — See all registered ViewModels in your app
- 🔍 **Inspect properties** — View reactive properties and their current values
- 🔄 **Rebuild tracking** — Monitor how many times ViewModels and properties have updated
- ⚡ **Live updates** — Property changes reflect in real-time
- ⚠️ **Diagnostics warnings** — Get notified about missing property names

## Usage

1. Add `mvvm_core` to your Flutter app
2. Override `debugFillProperties()` in your ViewModels to expose properties
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
3. Open Flutter DevTools and navigate to the **MVVM Core** tab

## Links

- [mvvm_core on pub.dev](https://pub.dev/packages/mvvm_core)
- [GitHub Repository](https://github.com/rjs580/mvvm_core)
- [Report Issues](https://github.com/rjs580/mvvm_core/issues)