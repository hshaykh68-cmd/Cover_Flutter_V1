import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AppleStyleTopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool translucent;
  final Color? backgroundColor;

  const AppleStyleTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.translucent = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final barContent = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Leading widget (back button or custom leading)
              if (leading != null)
                Positioned(
                  left: 0,
                  child: leading!,
                ),
              if (showBackButton)
                Positioned(
                  left: 0,
                  child: _BackButton(
                    onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  ),
                ),
              // Trailing actions
              if (actions != null)
                Positioned(
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (translucent) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: (backgroundColor ?? Colors.black).withOpacity(0.65),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: barContent,
          ),
        ),
      );
    } else {
      return Container(
        color: backgroundColor ?? Colors.black,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 0.5,
            ),
          ),
        ),
        child: barContent,
      );
    }
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.chevron_back,
            size: 20,
            color: CupertinoColors.systemBlue,
          ),
          const SizedBox(width: 4),
          Text(
            'Back',
            style: TextStyle(
              color: CupertinoColors.systemBlue.resolveFrom(context),
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
