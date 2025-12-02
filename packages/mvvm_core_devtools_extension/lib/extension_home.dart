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

  @override
  void initState() {
    super.initState();
    _loadViewModels();
  }

  Future<void> _loadViewModels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use serviceManager.service to access the VmService
      final response = await serviceManager.service!.callServiceExtension(
        'ext.mvvm_core.getViewModels',
        isolateId: serviceManager.isolateManager.mainIsolate.value!.id,
      );

      if (response.json != null) {
        final data = response.json!;
        setState(() {
          _viewModels = List<Map<String, dynamic>>.from(data['viewModels']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectViewModel(Map<String, dynamic> vm) async {
    try {
      final response = await serviceManager.service!.callServiceExtension(
        'ext.mvvm_core.getViewModel',
        isolateId: serviceManager.isolateManager.mainIsolate.value!.id,
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_viewModels.isEmpty) {
      return _buildEmptyState();
    }

    // Use Row instead of Split for simplicity
    return Row(
      children: [
        SizedBox(width: 300, child: _buildViewModelList()),
        const VerticalDivider(width: 1),
        Expanded(child: _buildDetailsPanel()),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadViewModels,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No ViewModels found', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            'Make sure:\n'
            '• MvvmDevToolsExtension.init() is called in main()\n'
            '• You have active ViewHandler widgets',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadViewModels,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModelList() {
    return Column(
      children: [
        _buildHeader('ViewModels', onRefresh: _loadViewModels),
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
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.primaryContainer,
                leading: Icon(
                  mounted ? Icons.check_circle : Icons.cancel,
                  color: mounted ? Colors.green : Colors.red,
                  size: 18,
                ),
                title: Text(
                  vm['type'] as String,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
                subtitle: Text(
                  '${(vm['properties'] as List).length} properties',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => _selectViewModel(vm),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsPanel() {
    if (_selectedViewModel == null) {
      return const Center(
        child: Text(
          'Select a ViewModel to inspect',
          style: TextStyle(color: Colors.grey),
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
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: mounted ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              mounted ? 'MOUNTED' : 'DISPOSED',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          onRefresh: () => _selectViewModel(vm),
        ),
        Expanded(
          child: properties.isEmpty
              ? const Center(
                  child: Text(
                    'No properties exposed.\n'
                    'Override debugFillProperties() in your ViewModel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final prop = properties[index];
                    return _buildPropertyTile(prop);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    String title, {
    Widget? trailing,
    VoidCallback? onRefresh,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: onRefresh,
              tooltip: 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyTile(Map<String, dynamic> prop) {
    final name = prop['name'] as String;
    final type = prop['type'] as String;
    final value = prop['value'] as String;

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
      color = Colors.grey;
    }

    return ExpansionTile(
      leading: Icon(icon, size: 18, color: color),
      title: Text(
        name,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
      subtitle: Text(
        type,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: Colors.grey[600],
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}
