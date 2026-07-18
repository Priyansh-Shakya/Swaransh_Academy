// ai_assistant_overlay.dart
//
// USAGE:
// Wrap this around whatever sits *above* your bottom nav bar — typically
// your root shell (the widget that hosts BottomNavigationBar/NavigationBar
// + the current tab's body). It needs to sit above the nav bar in the tree
// so the panel + icon float over every screen, e.g.:
//
//   Scaffold(
//     body: AiAssistantOverlay(
//       bottomNavHeight: 64, // match your actual nav bar height
//       child: currentTabBody,
//     ),
//     bottomNavigationBar: MyBottomNav(),
//   )
//
// ADJUST THE IMPORT PATHS BELOW to match your project structure.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/ai_assistant/data/ai_assistant_notifier.dart';

import '../../../core/theme/app_colors.dart';

/// Diameter of the floating launcher icon / notch cut into the panel.
const double _kIconSize = 60;

class AiAssistantOverlay extends ConsumerStatefulWidget {
  final Widget child;

  /// Height of your bottom navigation bar — the panel stops exactly here.
  final double bottomNavHeight;

  const AiAssistantOverlay({
    super.key,
    required this.child,
    this.bottomNavHeight = 64,
  });

  @override
  ConsumerState<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends ConsumerState<AiAssistantOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  bool _isOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _inputFocus.unfocus();
      _controller.reverse();
    }
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();

    ref.read(aiAssistantProvider.notifier).askAssistant(text);

    // ---------------------------------------------------------------------
    // STREAMING PLACEHOLDER — swap the call above for this once the backend
    // supports token streaming. Sketch:
    //
    // final stream = ref.read(aiAssistantApiServiceProvider)
    //     .askAssistantStream(AssistanceQuery(
    //       query: text,
    //       conversationHistory: ref.read(aiAssistantProvider).valueOrNull ?? [],
    //     ));
    //
    // // Append an empty assistant message immediately, then patch it as
    // // chunks arrive (requires a small addition to the notifier, e.g.
    // // `appendToLastAssistantMessage(String chunk)`).
    // await for (final chunk in stream) {
    //   ref.read(aiAssistantProvider.notifier).appendToLastAssistantMessage(chunk);
    //   _scrollToBottom();
    // }
    // ---------------------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelHeight = constraints.maxHeight - widget.bottomNavHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,

            // Scrim behind the panel — tap to close, lets the screen show
            // through faintly (point 1: opaque-but-hinting, not fully solid).
            if (_isOpen)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: panelHeight,
                child: FadeTransition(
                  opacity: _anim,
                  child: GestureDetector(
                    onTap: _toggle,
                    child: Container(color: Colors.black.withOpacity(0.12)),
                  ),
                ),
              ),

            // The chat panel itself.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: panelHeight,
              child: IgnorePointer(
                ignoring: !_isOpen,
                child: ScaleTransition(
                  scale: _anim,
                  alignment: Alignment.bottomRight,
                  child: FadeTransition(
                    opacity: _anim,
                    child: ClipPath(
                      clipper: _NotchedPanelClipper(
                        notchRadius: _kIconSize / 2 + 10,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          color: AppColors.navy.withOpacity(0.90),
                          child: SafeArea(
                            bottom: false,
                            child: _ChatPanelBody(
                              inputCtrl: _inputCtrl,
                              inputFocus: _inputFocus,
                              scrollCtrl: _scrollCtrl,
                              onSend: _send,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Floating launcher / close icon — sits inside the notch.
            Positioned(
              right: 16,
              bottom: widget.bottomNavHeight + 10,
              child: GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: _kIconSize,
                  height: _kIconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isOpen ? Icons.close_rounded : Icons.headset_mic_rounded,
                      key: ValueKey(_isOpen),
                      color: AppColors.textOnGold,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Cuts a full rounded-rect down to a circular notch at the bottom-right,
/// so the launcher icon appears to "poke through" the panel (point 2).
class _NotchedPanelClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double cornerRadius;

  _NotchedPanelClipper({required this.notchRadius, this.cornerRadius = 28});

  @override
  Path getClip(Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(cornerRadius),
    );
    final rectPath = Path()..addRRect(rrect);

    final notchCenter = Offset(
      size.width - (notchRadius),
      size.height - (notchRadius),
    );
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: notchCenter, radius: notchRadius));

    return Path.combine(PathOperation.difference, rectPath, circlePath);
  }

  @override
  bool shouldReclip(covariant _NotchedPanelClipper oldClipper) =>
      oldClipper.notchRadius != notchRadius ||
      oldClipper.cornerRadius != cornerRadius;
}

class _ChatPanelBody extends ConsumerWidget {
  final TextEditingController inputCtrl;
  final FocusNode inputFocus;
  final ScrollController scrollCtrl;
  final VoidCallback onSend;

  const _ChatPanelBody({
    required this.inputCtrl,
    required this.inputFocus,
    required this.scrollCtrl,
    required this.onSend,
  });

  static const _greeting = 'Hello, I am Sargam.\nHow can i assist you today? ☺';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(aiAssistantProvider);
    final history = asyncHistory.valueOrNull ?? const [];
    final isSending = asyncHistory.isLoading;

    return Column(
      children: [
        _Header(),
        const Divider(height: 1, color: Colors.white24),
        Expanded(
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _Bubble(text: _greeting, isUser: false),
              for (final msg in history)
                _Bubble(
                  text: msg['content'] ?? '',
                  isUser: msg['role'] == 'user',
                ),
              if (isSending) const _TypingBubble(),
            ],
          ),
        ),
        _InputBar(controller: inputCtrl, focusNode: inputFocus, onSend: onSend),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.gold,
            child: Icon(
              Icons.headset_mic_rounded,
              size: 18,
              color: AppColors.textOnGold,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Sargam · AI Assistant',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textOnNavy,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bg = isUser
        ? AppColors.goldLight
        : AppColors.ivoryDeep.withOpacity(0.14);
    final fg = isUser ? AppColors.textOnGold : AppColors.textOnNavy;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? bg : AppColors.navyDark.withOpacity(0.55),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: fg, height: 1.35),
      ),
    );

    if (isUser) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.gold,
          child: Icon(
            Icons.headset_mic_rounded,
            size: 15,
            color: AppColors.textOnGold,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(child: bubble),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.gold,
          child: Icon(
            Icons.headset_mic_rounded,
            size: 15,
            color: AppColors.textOnGold,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.navyDark.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 22,
            height: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (_) => CircleAvatar(
                  radius: 3,
                  backgroundColor: AppColors.ivory.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.ivory.withOpacity(0.92),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ask Sargam…',
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.gold,
              child: Icon(
                Icons.send_rounded,
                size: 20,
                color: AppColors.textOnGold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
