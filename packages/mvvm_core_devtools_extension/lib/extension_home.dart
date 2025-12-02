import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

class ExtensionHome extends StatefulWidget {
  const ExtensionHome({super.key});

  @override
  State<ExtensionHome> createState() => _ExtensionHomeState();
}

class _ExtensionHomeState extends State<ExtensionHome> {
  List<Map<String, dynamic>> _viewModels = [];
  Map<String, dynamic>? _selectedViewModel;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _waitForServiceAndLoad();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _waitForServiceAndLoad() async {
    setState(() {
      _isLoading = true;
    });

    await serviceManager.onServiceAvailable;

    final isolateManager = serviceManager.isolateManager;
    while (isolateManager.mainIsolate.value == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Subscribe to update events from the target app
    _subscribeToUpdates();

    if (mounted) {
      await _loadViewModelsWithRetry();
    }
  }

  Future<void> _loadViewModelsWithRetry() async {
    const maxRetries = 10;
    const initialDelay = Duration(milliseconds: 200);

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final service = serviceManager.service;
        final isolateId = serviceManager.isolateManager.mainIsolate.value?.id;

        if (service == null || isolateId == null) {
          throw Exception('Service not connected');
        }

        final response = await service.callServiceExtension(
          'ext.mvvm_core.getViewModels',
          isolateId: isolateId,
        );

        if (response.json != null) {
          final data = response.json!;
          final newViewModels = List<Map<String, dynamic>>.from(
            data['viewModels'],
          );

          if (mounted) {
            setState(() {
              _viewModels = newViewModels;
              _isLoading = false;
              _error = null;
            });
          }
          return; // Success, exit retry loop
        }
      } catch (e) {
        final isLastAttempt = attempt == maxRetries - 1;

        if (e.toString().contains('Unknown method') && !isLastAttempt) {
          // Service extension not yet registered, wait and retry
          final delay = initialDelay * (attempt + 1);
          await Future.delayed(delay);
          continue;
        }

        if (mounted) {
          setState(() {
            _error = isLastAttempt
                ? 'Could not connect to mvvm_core extension.\n'
                      'Make sure your app has active ViewHandler widgets.'
                : e.toString();
            _isLoading = false;
          });
        }

        if (isLastAttempt) return;
      }
    }
  }

  void _subscribeToUpdates() {
    final service = serviceManager.service;
    if (service == null) return;

    _eventSubscription = service.onExtensionEvent.listen((event) {
      if (event.extensionKind == 'ext.mvvm_core.update') {
        final data = event.extensionData?.data;
        final updatedId = data?['viewModelId'];

        // Refresh the list and handle selection
        _loadViewModels(silent: true).then((_) {
          // If we're viewing the updated ViewModel, refresh its details
          if (_selectedViewModel != null &&
              updatedId == _selectedViewModel!['id']) {
            _selectViewModel(_selectedViewModel!, silent: true);
          }
        });
      }
    });
  }

  Future<void> _loadViewModels({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final service = serviceManager.service;
      final isolateId = serviceManager.isolateManager.mainIsolate.value?.id;

      if (service == null || isolateId == null) {
        setState(() {
          _error =
              'Service not connected. Please ensure the target app is running.';
          _isLoading = false;
        });
        return;
      }

      final response = await service.callServiceExtension(
        'ext.mvvm_core.getViewModels',
        isolateId: isolateId,
      );

      if (response.json != null) {
        final data = response.json!;
        final newViewModels = List<Map<String, dynamic>>.from(
          data['viewModels'],
        );

        setState(() {
          _viewModels = newViewModels;
          _isLoading = false;

          // Check if selected ViewModel still exists
          if (_selectedViewModel != null) {
            final selectedId = _selectedViewModel!['id'];
            final stillExists = newViewModels.any(
              (vm) => vm['id'] == selectedId,
            );

            if (!stillExists) {
              // Selected ViewModel was disposed, select first one if available
              if (newViewModels.isNotEmpty) {
                _selectViewModel(newViewModels.first, silent: true);
              } else {
                _selectedViewModel = null;
              }
            }
          }
        });
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectViewModel(
    Map<String, dynamic> vm, {
    bool silent = false,
  }) async {
    try {
      final service = serviceManager.service;
      final isolateId = serviceManager.isolateManager.mainIsolate.value?.id;

      if (service == null || isolateId == null) return;

      final response = await service.callServiceExtension(
        'ext.mvvm_core.getViewModel',
        isolateId: isolateId,
        args: {'id': vm['id'].toString()},
      );

      if (response.json != null) {
        setState(() {
          _selectedViewModel = response.json!;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(isDark);
    }

    if (_viewModels.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Row(
      children: [
        SizedBox(width: 300, child: _buildViewModelList(isDark)),
        VerticalDivider(
          width: 1,
          color: isDark ? Colors.grey[700] : Colors.grey[300],
        ),
        Expanded(child: _buildDetailsPanel(isDark)),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[isDark ? 300 : 600],
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $_error',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadViewModels,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No ViewModels Registered',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ViewModels will appear here once your app\ncreates widgets using ViewHandler.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadViewModels,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModelList(bool isDark) {
    return Column(
      children: [
        _buildHeader('ViewModels', isDark, onRefresh: _loadViewModels),
        Expanded(
          child: ListView.builder(
            itemCount: _viewModels.length,
            itemBuilder: (context, index) {
              final vm = _viewModels[index];
              final isSelected = _selectedViewModel?['id'] == vm['id'];
              final mounted = vm['mounted'] as bool;

              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: isDark
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.primaryContainer,
                leading: Icon(
                  mounted ? Icons.check_circle : Icons.cancel,
                  color: mounted ? Colors.green : Colors.red,
                  size: 18,
                ),
                title: Text(
                  vm['type'] as String,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  '${(vm['properties'] as List).length} properties',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                onTap: () => _selectViewModel(vm),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsPanel(bool isDark) {
    if (_selectedViewModel == null) {
      return Center(
        child: Text(
          'Select a ViewModel to inspect',
          style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey),
        ),
      );
    }

    final vm = _selectedViewModel!;
    final properties = List<Map<String, dynamic>>.from(vm['properties']);
    final mounted = vm['mounted'] as bool;

    return Column(
      children: [
        _buildHeader(
          vm['type'] as String,
          isDark,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: mounted ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              mounted ? 'MOUNTED' : 'DISPOSED',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onRefresh: () => _selectViewModel(vm),
        ),
        Expanded(
          child: properties.isEmpty
              ? Center(
                  child: Text(
                    'No properties exposed.\n'
                    'Override debugFillProperties() in your ViewModel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final prop = properties[index];
                    return _buildPropertyTile(prop, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    String title,
    bool isDark, {
    Widget? trailing,
    VoidCallback? onRefresh,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              onPressed: onRefresh,
              tooltip: 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyTile(Map<String, dynamic> prop, bool isDark) {
    final name = prop['name'] as String;
    final type = prop['type'] as String;
    final value = prop['value'] as String;
    final items = prop['items'] as List?;
    final entries = prop['entries'] as List?;

    final bool isCollection = items != null || entries != null;

    IconData icon;
    Color color;

    if (type.contains('Future') || type.contains('Stream')) {
      icon = Icons.sync;
      color = Colors.orange;
    } else if (type.contains('List') ||
        type.contains('Map') ||
        type.contains('Set')) {
      icon = Icons.list;
      color = Colors.purple;
    } else if (type.startsWith('Reactive')) {
      icon = Icons.bolt;
      color = Colors.blue;
    } else {
      icon = Icons.info_outline;
      color = isDark ? Colors.grey[400]! : Colors.grey;
    }

    // Use simple ListTile for non-collection properties
    if (!isCollection) {
      return _buildSimplePropertyTile(
        name: name,
        type: type,
        value: value,
        icon: icon,
        color: color,
        isDark: isDark,
      );
    }

    // Use ExpansionTile for collections
    return ExpansionTile(
      leading: Icon(icon, size: 18, color: color),
      title: Text(
        name,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        '$type • $value',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      children: [
        if (items != null) _buildCollectionItems(items, isDark),
        if (entries != null) _buildMapEntries(entries, isDark),
      ],
    );
  }

  Widget _buildSimplePropertyTile({
    required String name,
    required String type,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: SelectableText(
                    value,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionItems(List items, bool isDark) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text(
          '(empty)',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...items.take(50).map((item) {
            final map = item as Map<String, dynamic>;
            final index = map['index'];
            final value = map['value'] as String;
            final type = map['type'] as String;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index != null)
                    SizedBox(
                      width: 40,
                      child: Text(
                        '[$index]',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (items.length > 50)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '... and ${items.length - 50} more items',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapEntries(List entries, bool isDark) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text(
          '(empty)',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...entries.take(50).map((entry) {
            final map = entry as Map<String, dynamic>;
            final key = map['key'] as String;
            final value = map['value'] as String;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.purple[300] : Colors.purple[700],
                    ),
                  ),
                  Text(
                    ': ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (entries.length > 50)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '... and ${entries.length - 50} more entries',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
