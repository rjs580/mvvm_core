import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:mvvm_core/mvvm_core.dart';

/// Provides DevTools integration for mvvm_core.
///
/// Call [MvvmDevToolsExtension.init] in your app's main() to enable
/// ViewModel inspection in DevTools.
///
/// ```dart
/// void main() {
///   MvvmDevToolsExtension.init();
///   runApp(MyApp());
/// }
/// ```
class MvvmDevToolsExtension {
  MvvmDevToolsExtension._();

  static bool _initialized = false;
  static final Map<int, WeakReference<ViewModel>> _viewModels = {};
  static int _nextId = 0;

  /// Initializes the DevTools extension.
  ///
  /// Call this in your app's main() before runApp().
  /// Only works in debug mode.
  static void init() {
    // Only initialize once and only in debug mode
    if (_initialized || !kDebugMode) return;
    _initialized = true;

    _registerServiceExtensions();
  }

  /// Registers a ViewModel for inspection in DevTools.
  static int registerViewModel(ViewModel viewModel) {
    if (!_initialized) return -1;

    final id = _nextId++;
    _viewModels[id] = WeakReference(viewModel);
    return id;
  }

  /// Unregisters a ViewModel when it's disposed.
  static void unregisterViewModel(int id) {
    _viewModels.remove(id);
  }

  /// Registers the service extensions that DevTools can call.
  static void _registerServiceExtensions() {
    // Extension: Get list of all ViewModels
    registerExtension('ext.mvvm_core.getViewModels', (method, params) async {
      _cleanupDisposedViewModels();

      final viewModelData = <Map<String, dynamic>>[];

      for (final entry in _viewModels.entries) {
        final vm = entry.value.target;
        if (vm != null) {
          viewModelData.add(_serializeViewModel(entry.key, vm));
        }
      }

      return ServiceExtensionResponse.result(
        jsonEncode({'viewModels': viewModelData}),
      );
    });

    // Extension: Get details of a specific ViewModel
    registerExtension('ext.mvvm_core.getViewModel', (method, params) async {
      final idParam = params['id'];
      if (idParam == null) {
        return ServiceExtensionResponse.error(
          ServiceExtensionResponse.invalidParams,
          'Missing required parameter: id',
        );
      }

      final id = int.tryParse(idParam);
      if (id == null) {
        return ServiceExtensionResponse.error(
          ServiceExtensionResponse.invalidParams,
          'Invalid id parameter',
        );
      }

      final vm = _viewModels[id]?.target;
      if (vm == null) {
        return ServiceExtensionResponse.error(
          ServiceExtensionResponse.extensionError,
          'ViewModel not found or disposed',
        );
      }

      return ServiceExtensionResponse.result(
        jsonEncode(_serializeViewModel(id, vm, detailed: true)),
      );
    });
  }

  /// Removes references to disposed ViewModels.
  static void _cleanupDisposedViewModels() {
    _viewModels.removeWhere((key, ref) => ref.target == null);
  }

  /// Converts a ViewModel to a JSON-serializable map.
  static Map<String, dynamic> _serializeViewModel(
    int id,
    ViewModel vm, {
    bool detailed = false,
  }) {
    final properties = <Map<String, dynamic>>[];

    // Use Flutter's diagnostics system to get properties
    final builder = DiagnosticPropertiesBuilder();
    vm.debugFillProperties(builder);

    for (final prop in builder.properties) {
      if (prop.name == null) continue;

      final propData = <String, dynamic>{
        'name': prop.name,
        'type': _getPropertyType(prop),
        'value': _getPropertyValue(prop),
      };

      if (detailed) {
        propData['description'] = prop.toDescription();
      }

      properties.add(propData);
    }

    return {
      'id': id,
      'type': vm.runtimeType.toString(),
      'mounted': vm.mounted,
      'properties': properties,
    };
  }

  static String _getPropertyType(DiagnosticsNode prop) {
    if (prop is DiagnosticsProperty) {
      final value = prop.value;
      if (value == null) return 'null';

      if (value is Reactive) return 'Reactive';
      if (value is ReactiveFuture) return 'ReactiveFuture';
      if (value is ReactiveStream) return 'ReactiveStream';
      if (value is ReactiveList) return 'ReactiveList';
      if (value is ReactiveMap) return 'ReactiveMap';
      if (value is ReactiveSet) return 'ReactiveSet';

      return value.runtimeType.toString();
    }
    return 'unknown';
  }

  static String _getPropertyValue(DiagnosticsNode prop) {
    if (prop is DiagnosticsProperty) {
      final value = prop.value;
      if (value == null) return 'null';

      if (value is ReactiveProperty) {
        return _serializeReactiveValue(value);
      }

      return _truncate(value.toString());
    }
    return prop.toDescription();
  }

  static String _serializeReactiveValue(ReactiveProperty property) {
    final value = property.value;

    if (value is AsyncState) {
      return value.when(
        idle: () => 'Idle',
        loading: () => 'Loading...',
        data: (d) => 'Data: ${_truncate(d.toString())}',
        error: (e, _) => 'Error: ${_truncate(e.toString())}',
        done: (d) => 'Done: ${_truncate(d.toString())}',
      );
    }

    if (value is List) return 'List (${value.length} items)';
    if (value is Map) return 'Map (${value.length} entries)';
    if (value is Set) return 'Set (${value.length} items)';

    return _truncate(value.toString());
  }

  static String _truncate(String str, [int maxLength = 50]) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}...';
  }
}
