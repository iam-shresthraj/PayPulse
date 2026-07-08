import 'package:flutter/material.dart';

bool _dialogShowing = false;

/// Shows a dialog only if no other dialog is currently being shown,
/// preventing duplicate overlays from multiple rapid taps.
Future<T?> showSingleDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = false,
  bool barrierDismissible = true,
  Color? barrierColor,
}) async {
  if (_dialogShowing) return null;
  _dialogShowing = true;
  try {
    return await showDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: builder,
    );
  } finally {
    _dialogShowing = false;
  }
}
