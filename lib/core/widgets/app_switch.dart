import 'package:flutter/material.dart';

import '../utils/haptics.dart';

/// The app's toggle: the platform switch (Cupertino on iOS, Material
/// elsewhere) plus the same haptic buzz every other control gives —
/// a bare `Switch.adaptive` flips silently.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Switch.adaptive(
      value: value,
      onChanged: onChanged == null
          ? null
          : (v) {
              AppHaptics.selection();
              onChanged(v);
            },
    );
  }
}
