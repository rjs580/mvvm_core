import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:mvvm_core_devtools_extension/extension_home.dart';

void main() {
  runApp(const MvvmCoreDevToolsExtension());
}

class MvvmCoreDevToolsExtension extends StatelessWidget {
  const MvvmCoreDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: ExtensionHome());
  }
}
