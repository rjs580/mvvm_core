# MVVM Core

A lightweight, powerful MVVM state management library for Flutter.

See [packages/mvvm_core](packages/mvvm_core) for the main package.

## Repository Structure
```text
packages/
├── mvvm_core/ # Main package (published to pub.dev)
└── mvvm_core_devtools_extension/ # DevTools extension source
example/ # Example app
```

## Development

### Build DevTools Extension

```bash
cd packages/mvvm_core_devtools_extension
```

```bash
flutter pub get
```

```bash
dart run devtools_extensions build_and_copy --source=. --dest=../mvvm_core/extension/devtools
```