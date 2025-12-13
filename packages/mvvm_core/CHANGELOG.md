## 1.1.1

### Fixed
- Included prebuilt DevTools extension assets in the published package (the previous release missed the build step), ensuring the extension loads correctly after install.

## 1.1.0

### Added

- **Rebuild Tracking** — DevTools extension now displays rebuild counts for ViewModels and reactive properties
- Warning indicator in DevTools for properties missing a name in `debugFillProperties()`

### Changed

- Improved documentation

## 1.0.0

- Initial release
- `ViewModel` base class with lifecycle management
- `ViewHandler` for view-viewmodel binding
- Reactive primitives: `Reactive`, `ReactiveFuture`, `ReactiveStream`
- Reactive collections: `ReactiveList`, `ReactiveMap`, `ReactiveSet`
- Builder widgets: `ReactiveBuilder`, `SelectReactiveBuilder`, `MultiReactiveBuilder`
- Flutter DevTools integration