import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Versione ridotta per Android: la barra del titolo desktop non esiste più.
/// Resta solo lo stato di schermo intero, usato dal player e da altri widget.
class AnymeXTitleBar {
  static final ValueNotifier<bool> isFullScreen = ValueNotifier(false);
  static final ValueNotifier<bool> isMaximized = ValueNotifier(false);

  static Future<void> initialize() async {}

  static Widget titleBar() => const SizedBox.shrink();

  static Future<void> setFullScreen(bool enable) async {
    isFullScreen.value = enable;
  }

  static Future<void> toggleFullScreen() async {
    isFullScreen.value = !isFullScreen.value;
  }
}
