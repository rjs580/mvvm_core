import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:mvvm_core/mvvm_core.dart';

/// Provides DevTools integration for mvvm_core.
///
/// The extension automatically initializes in debug mode when the first
/// ViewModel is registered. No manual initialization is required.
class MvvmDevToolsExtension {
  MvvmDevToolsExtension._();

  static bool _initialized = false;
  static final Map<int, _ViewModelEntry> _viewModels = {};
  static int _nextId = 0;

  /// Auto-initializes if needed and registers a ViewModel for inspection.
  static int registerViewModel(ViewModel viewModel) {
    // Auto-initialize on first registration (debug mode only)
    if (!kDebugMode) return -1;

    if (!_initialized) {
      _initialized = true;
      _registerServiceExtensions();
    }

    final id = _nextId++;
    final entry = _ViewModelEntry(viewModel, id);
    _viewModels[id] = entry;

    // Post an event so DevTools knows to refresh
    _postUpdateEvent();

    return id;
  }

  /// Unregisters a ViewModel when it's disposed.
  static void unregisterViewModel(int id) {
    if (id == -1) return;
    final entry = _viewModels.remove(id);
    entry?.dispose();
    _postUpdateEvent();
  }

  /// Posts an event that the DevTools extension can listen to.
  static void _postUpdateEvent({int? viewModelId}) {
    postEvent('ext.mvvm_core.update', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (viewModelId != null) 'viewModelId': viewModelId,
    });
  }

  /// Registers the service extensions that DevTools can call.
  static void _registerServiceExtensions() {
    // Extension: Get list of all ViewModels
    registerExtension('ext.mvvm_core.getViewModels', (method, params) async {
      _cleanupDisposedViewModels();

      final viewModelData = <Map<String, dynamic>>[];

      for (final entry in _viewModels.entries) {
        final vm = entry.value.viewModel.target;
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

      final vm = _viewModels[id]?.viewModel.target;
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
    final toRemove = <int>[];
    for (final entry in _viewModels.entries) {
      if (entry.value.viewModel.target == null) {
        entry.value.dispose();
        toRemove.add(entry.key);
      }
    }
    for (final id in toRemove) {
      _viewModels.remove(id);
    }
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

      properties.add(_serializeProperty(prop, detailed: detailed));
    }

    return {
      'id': id,
      'type': vm.runtimeType.toString(),
      'mounted': vm.mounted,
      'properties': properties,
    };
  }

  static Map<String, dynamic> _serializeProperty(
    DiagnosticsNode prop, {
    bool detailed = false,
  }) {
    final propData = <String, dynamic>{
      'name': prop.name,
      'type': _getPropertyType(prop),
      'value': _getPropertyValue(prop),
    };

    if (detailed) {
      propData['description'] = prop.toDescription();

      // Add collection items for detailed view
      if (prop is DiagnosticsProperty) {
        final value = prop.value;
        if (value is ReactiveList) {
          propData['items'] = _serializeList(value.value);
        } else if (value is ReactiveMap) {
          propData['entries'] = _serializeMap(value.value);
        } else if (value is ReactiveSet) {
          propData['items'] = _serializeSet(value.value);
        } else if (value is List) {
          propData['items'] = _serializeList(value);
        } else if (value is Map) {
          propData['entries'] = _serializeMap(value);
        } else if (value is Set) {
          propData['items'] = _serializeSet(value);
        }
      }
    }

    return propData;
  }

  static List<Map<String, dynamic>> _serializeList(List list) {
    return list
        .asMap()
        .entries
        .map(
          (e) => {
            'index': e.key,
            'value': _truncate(e.value.toString(), 100),
            'type': e.value.runtimeType.toString(),
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _serializeMap(Map map) {
    return map.entries
        .map(
          (e) => {
            'key': _truncate(e.key.toString(), 50),
            'value': _truncate(e.value.toString(), 100),
            'keyType': e.key.runtimeType.toString(),
            'valueType': e.value.runtimeType.toString(),
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _serializeSet(Set set) {
    return set
        .map(
          (e) => {
            'value': _truncate(e.toString(), 100),
            'type': e.runtimeType.toString(),
          },
        )
        .toList();
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

/// Internal class to manage ViewModel and its ReactiveProperty listeners.
class _ViewModelEntry {
  _ViewModelEntry(ViewModel vm, this.id) : viewModel = WeakReference(vm) {
    _setupListeners(vm);
  }

  final WeakReference<ViewModel> viewModel;
  final int id;
  final List<_ListenerRegistration> _listeners = [];

  void _setupListeners(ViewModel vm) {
    // Listen to ViewModel changes
    void onViewModelChanged() {
      MvvmDevToolsExtension._postUpdateEvent(viewModelId: id);
    }

    vm.addListener(onViewModelChanged);
    _listeners.add(_ListenerRegistration(vm, onViewModelChanged));

    // Find and listen to all ReactiveProperty instances
    final builder = DiagnosticPropertiesBuilder();
    vm.debugFillProperties(builder);

    for (final prop in builder.properties) {
      if (prop is DiagnosticsProperty) {
        final value = prop.value;
        if (value is ReactiveProperty) {
          void onPropertyChanged() {
            MvvmDevToolsExtension._postUpdateEvent(viewModelId: id);
          }

          value.addListener(onPropertyChanged);
          _listeners.add(_ListenerRegistration(value, onPropertyChanged));
        }
      }
    }
  }

  void dispose() {
    for (final registration in _listeners) {
      registration.removeListener();
    }
    _listeners.clear();
  }
}

/// Holds a reference to a Listenable and its callback for cleanup.
class _ListenerRegistration {
  _ListenerRegistration(this.listenable, this.callback);

  final Listenable listenable;
  final VoidCallback callback;

  void removeListener() {
    try {
      listenable.removeListener(callback);
    } catch (_) {
      // Listenable may already be disposed
    }
  }
}
