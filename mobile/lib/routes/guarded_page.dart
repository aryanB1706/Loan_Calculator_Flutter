import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/widgets/app_loader.dart';
import 'app_routes.dart';

/// A page that needs data passed through navigation arguments.
///
/// In the browser a refresh (or hot restart) reopens the current URL with no
/// arguments. Instead of crashing, such a page sends the user back to the
/// splash screen, which routes them to the right place.
GetPage<dynamic> guardedPage<T>({
  required String name,
  required Widget Function() page,
  required Bindings binding,
}) {
  return GetPage(
    name: name,
    page: () => Get.arguments is T ? page() : const _RestartPage(),
    binding: _GuardedBinding<T>(binding),
  );
}

class _GuardedBinding<T> extends Bindings {
  _GuardedBinding(this._binding);

  final Bindings _binding;

  @override
  void dependencies() {
    if (Get.arguments is T) {
      _binding.dependencies();
    }
  }
}

class _RestartPage extends StatefulWidget {
  const _RestartPage();

  @override
  State<_RestartPage> createState() => _RestartPageState();
}

class _RestartPageState extends State<_RestartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Get.offAllNamed(AppRoutes.splash),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppLoader());
  }
}
