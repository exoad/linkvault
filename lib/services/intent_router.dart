import 'dart:io';

import 'package:flutter/widgets.dart';

import '../hub/hub_module.dart';
import '../hub/hub_registry.dart';
import '../platform/app_api.g.dart';

/// Routes external Android intents (share, process-text, launcher shortcuts)
/// to the first registered [IntentAware] hub module that accepts them.
///
/// Cold start uses a pull (`getInitialIntent`) to avoid a startup race; warm
/// deliveries arrive via the [FlutterIntentApi] callback ([onIntent]).
class IntentRouter implements FlutterIntentApi {
  IntentRouter({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  static const _maxDispatchAttempts = 20;

  /// Registers this router to receive warm-start intents from Kotlin.
  void attach() {
    if (!Platform.isAndroid) return;
    FlutterIntentApi.setUp(this);
  }

  /// Pulls and dispatches the intent that launched the app, if any.
  Future<void> handleInitialIntent() async {
    if (!Platform.isAndroid) return;
    try {
      final initial = await IntentHostApi().getInitialIntent();
      if (initial != null) dispatch(initial);
    } catch (_) {
      // No host handler (e.g. non-Android) or nothing pending — ignore.
    }
  }

  @override
  void onIntent(IncomingIntent intent) => dispatch(intent);

  /// Resolves a handler and presents it, retrying across frames until the
  /// navigator is mounted (cold start can deliver before the first frame).
  void dispatch(IncomingIntent intent, {int attempt = 0}) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      if (attempt >= _maxDispatchAttempts) return;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => dispatch(intent, attempt: attempt + 1),
      );
      return;
    }
    final handler = resolveHandler(intent);
    handler?.handleIntent(context, intent);
  }

  /// Picks the module that should handle [intent]: a matching hinted module
  /// first, otherwise the first registered [IntentAware] that accepts it.
  @visibleForTesting
  IntentAware? resolveHandler(IncomingIntent intent) {
    final hintedId = intent.targetModuleId;
    if (hintedId != null) {
      final hinted = HubRegistry.findById(hintedId);
      if (hinted is IntentAware) {
        final aware = hinted as IntentAware;
        if (aware.canHandle(intent)) return aware;
      }
    }
    for (final module in HubRegistry.modules) {
      if (module is IntentAware) {
        final aware = module as IntentAware;
        if (aware.canHandle(intent)) return aware;
      }
    }
    return null;
  }
}
