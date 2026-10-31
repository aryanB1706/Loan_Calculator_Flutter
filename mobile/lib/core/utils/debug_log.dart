import 'package:flutter/foundation.dart';

/// Unexpected errors are shown to the user as a friendly message, so this
/// prints the real cause in the debug console only.
void logUnexpectedError(String where, Object error, StackTrace stack) {
  if (kDebugMode) {
    debugPrint('[ERROR] $where: $error\n$stack');
  }
}
