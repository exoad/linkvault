import 'package:flutter/material.dart';

import '../../../animations/linkvault_motion.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/linkvault_design.dart';
import '../../../theme/linkvault_typography.dart';
import '../chat_runtime_status.dart';

/// Subtle status strip below the chat composer.
class ChatStatusBar extends StatelessWidget {
  const ChatStatusBar({
    super.key,
    required this.status,
    required this.label,
    this.onRetry,
    this.onTap,
  });

  final ChatRuntimeStatus status;
  final String label;
  final VoidCallback? onRetry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final showSpinner = ChatRuntimeStatusMapper.showsSpinner(status);
    final retryable = ChatRuntimeStatusMapper.isRetryable(status);
    final onTapHandler = retryable ? (onRetry ?? onTap) : onTap;

    Widget content = Padding(
      padding: EdgeInsets.fromLTRB(
        LinkvaultDesign.spaceLg,
        LinkvaultDesign.spaceXs,
        LinkvaultDesign.spaceLg,
        LinkvaultDesign.spaceXs + bottom,
      ),
      child: Row(
        children: [
          if (showSpinner) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: LinkvaultDesign.spaceSm),
          ] else if (status == ChatRuntimeStatus.ready) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: LinkvaultDesign.spaceSm),
          ],
          Expanded(
            child: aliveFadeSwap(
              value: label,
              duration: AppMotion.fast,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LinkvaultTypography.meta(scheme).copyWith(
                  color: scheme.onSurface.withValues(
                    alpha: retryable ? 0.72 : 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTapHandler != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapHandler,
          child: content,
        ),
      );
    }

    return content.statusEntrance(context);
  }
}
