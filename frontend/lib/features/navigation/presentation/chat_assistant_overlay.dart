/// Persistent floating action button, present above every tab/route -
/// the Flipkart-style chat bubble. Wrapping AppShell in this (rather than
/// putting it inside each page) means it survives tab switches and keeps
/// its own state once the real AI Assistance feature replaces the
/// placeholder onTap below.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/auth/auth_notifier.dart';
import 'package:swaransh_academy/features/ai_assistant/data/ai_assistant_notifier.dart';
import 'package:swaransh_academy/features/ai_assistant/widgets/markdown_renderer.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_typography.dart';

// ── Layout constants ────────────────────────────────────────────────────────
const double _kIconSize = 50;
const double _kNotchRadius = _kIconSize / 2 + 10; // 40 — matches clipper
const double _kDesktopWidth = 400;
const double kMobileBreakpoint = 700;

//?
final nameProvider = Provider<String?>((ref) {
  // 1. Extract the name safely
  final authState = ref.watch(authProvider);

  // Safely extract the display name regardless of loading/data/error states
  final userName = authState.maybeWhen(
    data: (user) => user.displayName,
    orElse: () => 'there',
  );
  return userName;
});

double _floatingBottom(
  BuildContext context,
  bool isMobile,
  double bottomNavHeight,
) {
  final keyboard = MediaQuery.viewInsetsOf(context).bottom;
  final systemBottom = MediaQuery.paddingOf(context).bottom;

  // When keyboard is visible, push above keyboard with a small 12px margin
  if (keyboard > 0) {
    return keyboard + 12;
  }

  // Base elevation off the bottom bar height + safe area bottom inset + margin
  final navSpace = isMobile ? bottomNavHeight : 0.0;
  return systemBottom + navSpace + 12.0;
}

/// Wraps every screen in the shell. Manages the FAB + sliding chat panel.
/// Already inside MaterialApp via StatefulShellRoute — full Material tree access.
class ChatAssistantOverlay extends ConsumerStatefulWidget {
  const ChatAssistantOverlay({
    super.key,
    required this.child,
    this.bottomNavHeight = 64,
  });

  final Widget child;
  final double bottomNavHeight;

  @override
  ConsumerState<ChatAssistantOverlay> createState() =>
      _ChatAssistantOverlayState();
}

class _ChatAssistantOverlayState extends ConsumerState<ChatAssistantOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  bool _isOpen = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _ctrl.forward() : _ctrl.reverse();
    if (!_isOpen) _inputFocus.unfocus();
  }

  void _close() {
    if (_isOpen) _toggle();
  }

  void _send() {
    debugPrint("Send button called");
    final text = _inputCtrl.text.trim();
    final name = ref.watch(nameProvider);
    if (text.isEmpty) return;
    _inputCtrl.clear();
    _inputFocus.unfocus();
    ref.read(aiAssistantProvider.notifier).askAssistant(text, name);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < kMobileBreakpoint;
        return Stack(
          fit: StackFit.expand,
          children: [
            // ① The actual page content
            widget.child,

            // ② Backdrop scrim (both layouts)
            if (_isOpen)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _anim,
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(
                      color: const Color.fromARGB(
                        255,
                        250,
                        248,
                        248,
                      ).withOpacity(0.18),
                    ),
                  ),
                ),
              ),

            // ③ Chat panel
            if (isMobile) _mobilePanel(constraints) else _desktopPanel(),

            // ④ FAB — hidden on desktop when panel is open
            if (!(isMobile == false && _isOpen)) _fab(isMobile),
          ],
        );
      },
    );
  }

  // ── Mobile panel ──────────────────────────────────────────────────────────
  Widget _mobilePanel(BoxConstraints constraints) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final panelH =
        constraints.maxHeight -
        widget.bottomNavHeight -
        (keyboardInset == 0 ? 0 : keyboardInset - 60);
    debugPrint("Is open: $_isOpen");
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      top: 0,
      height: panelH,
      child: IgnorePointer(
        ignoring: !_isOpen,
        child: ScaleTransition(
          scale: _anim,
          alignment: Alignment.bottomRight,
          child: FadeTransition(
            opacity: _anim,
            child: ClipPath(
              clipper: _NotchedClipper(notchRadius: _kNotchRadius),
              child: _PanelSurface(
                inputCtrl: _inputCtrl,
                inputFocus: _inputFocus,
                scrollCtrl: _scrollCtrl,
                isDesktop: false,
                onSend: _send,
                onClose: null,
                bottomNavHeight: widget.bottomNavHeight,
                inputRightPadding: _kIconSize + 8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Desktop panel ─────────────────────────────────────────────────────────
  Widget _desktopPanel() {
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: _kDesktopWidth,
      child: IgnorePointer(
        ignoring: !_isOpen,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(_anim),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: _PanelSurface(
              inputCtrl: _inputCtrl,
              inputFocus: _inputFocus,
              scrollCtrl: _scrollCtrl,
              onSend: _send,
              onClose: _close, // X button closes on desktop
              inputRightPadding: 12,
              bottomNavHeight: widget.bottomNavHeight,
              isDesktop: true, // no notch on desktop
            ),
          ),
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _fab(bool isMobile) {
    //? This function toggles chat pannel on mobile  (on/off)
    debugPrint("FAB called ...");
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    debugPrint(" ================== Keyboard height: $keyboardHeight");

    //* Phone's bottom bar ...
    //final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      right: 16,
      //(bottomInset/2) +
      //  (isMobile ? widget.bottomNavHeight + 30 : 0) +
      //(keyboardHeight == 0 ? keyboardHeight : keyboardHeight - 80)
      bottom: _floatingBottom(context, isMobile, widget.bottomNavHeight),

      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: _kIconSize,
          height: _kIconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Image.asset(
              'assets/chat_assistant_icon.png',

              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Panel surface (shared between mobile & desktop) ───────────────────────────

class _PanelSurface extends StatelessWidget {
  const _PanelSurface({
    required this.inputCtrl,
    required this.inputFocus,
    required this.scrollCtrl,
    required this.onSend,
    required this.inputRightPadding,
    required this.isDesktop,
    required this.bottomNavHeight,

    this.onClose,
  });

  final isDesktop;
  final TextEditingController inputCtrl;
  final FocusNode inputFocus;
  final ScrollController scrollCtrl;
  final VoidCallback onSend;
  final VoidCallback? onClose;
  final double inputRightPadding;
  final double bottomNavHeight;

  @override
  Widget build(BuildContext context) {
    final isMobile = !isDesktop;
    debugPrint("Inside Pannel Surface");
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Material(
          type: MaterialType.transparency, // <-- only for Material context
          child: ClipPath(
            clipper: _NotchedClipper(
              notchRadius: (isDesktop) ? 0 : 35,
              cornerRadius: 40,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),

                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(.38),
                      Colors.white.withOpacity(.18),
                    ],
                  ),

                  border: Border.all(
                    color: Colors.white.withOpacity(.80),
                    width: 1.6,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _Header(onClose: onClose),
                      Divider(height: 1, color: Colors.white.withOpacity(.18)),
                      Expanded(child: _MessageList(scrollCtrl: scrollCtrl)),
                      _InputBar(
                        controller: inputCtrl,
                        focusNode: inputFocus,
                        onSend: onSend,
                        rightPadding: inputRightPadding,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  //* App Bar Title
  const _Header({this.onClose});
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          // CircleAvatar(
          //   radius: 16,
          //   backgroundColor: AppColors.gold,
          //   child: const Icon(
          //     Icons.headset_mic_rounded,
          //     size: 18,
          //     color: AppColors.navy,
          //   ),
          // ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sargam · AI Assistant',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.goldLight,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textOnNavy,
              ),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}

// ── Message list ─────────────────────────────────────────────────────────────
class _MessageList extends ConsumerWidget {
  const _MessageList({required this.scrollCtrl});
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(nameProvider);
    final name = userName ?? 'there';
    final greeting =
        'Hello ${name.split(' ').first}, I am Sargam.\n\nHow can I assist you today? 🤗';

    ref.listen(aiAssistantProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollCtrl.hasClients) {
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    });

    final history = ref.watch(aiAssistantProvider).valueOrNull ?? [];
    // Single source of truth for both InputBar and MessageList
    final isStreaming = ref.watch(isStreamingProvider);
    final agentStatus = ref.watch(agentStatusProvider);

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _Bubble(text: greeting, isUser: false),

        for (int i = 0; i < history.length; i++)
          // Hide empty assistant bubble while waiting for the first token stream
          if (!(i == history.length - 1 &&
              isStreaming &&
              (history[i]['content'] ?? '').isEmpty))
            _Bubble(
              text: history[i]['content'] ?? '',
              isUser: history[i]['role'] == 'user',
            ),

        if (isStreaming &&
            (history.isEmpty || (history.last['content'] ?? '').isEmpty))
          TypingBubble(status: agentStatus),
      ],
    );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isUser});
  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.goldLight
            : AppColors.navyDark.withOpacity(0.65),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
      ),
      child: ChatMarkdown(text: text, isUser: isUser),
    );

    if (isUser) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          child: Image.asset(
            'assets/chat_assistant_icon.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(child: bubble),
      ],
    );
  }
}

// ── Typing indicator (used while streaming) ───────────────────────────────────

// Dummy Color class for demonstration (re-use your existing AppColors)

class TypingBubble extends StatefulWidget {
  final String? status;

  const TypingBubble({super.key, this.status});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _dotController;

  // Real backend trace history
  final List<String> _receivedSteps = [];

  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    if (widget.status != null && widget.status!.trim().isNotEmpty) {
      _receivedSteps.add(widget.status!.trim());
    }
  }

  @override
  void didUpdateWidget(covariant TypingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Append each new status as it arrives from SSE
    if (widget.status != null &&
        widget.status!.trim().isNotEmpty &&
        widget.status != oldWidget.status) {
      final newStatus = widget.status!.trim();
      if (!_receivedSteps.contains(newStatus)) {
        setState(() {
          _receivedSteps.add(newStatus);
        });
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.transparent,
          child: Image.asset(
            'assets/chat_assistant_icon.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.smart_toy_outlined,
              size: 20,
              color: AppColors.gold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _receivedSteps.isEmpty && widget.status == null
                ? _buildTypingBubble()
                : _buildVerticalTimelineBubble(),
          ),
        ),
      ],
    );
  }

  // Standard 3-Dot fallback before status arrives
  Widget _buildTypingBubble() {
    return Container(
      key: const ValueKey('typing'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.navyDark.withOpacity(0.65),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SizedBox(
        width: 28,
        height: 16,
        child: AnimatedBuilder(
          animation: _dotController,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (index) {
                final delay = index * 0.18;
                final progress = ((_dotController.value - delay) % 1.0).clamp(
                  0.0,
                  1.0,
                );
                final dy = -4.0 * math.sin(progress * math.pi);

                return Transform.translate(
                  offset: Offset(0, dy),
                  child: const CircleAvatar(
                    radius: 3.5,
                    backgroundColor: AppColors.ivory,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  // Vertical Timeline HUD (Default Open, No Collapsing)
  Widget _buildVerticalTimelineBubble() {
    final steps = _receivedSteps.isNotEmpty
        ? _receivedSteps
        : [widget.status ?? "Working on it..."];

    return Container(
      key: ValueKey('timeline-${steps.length}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.navyDark.withOpacity(0.85),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (index) {
          final isLast = index == steps.length - 1;
          final isCompleted = !isLast;

          return _buildTimelineCheckpointRow(
            text: steps[index],
            isCompleted: isCompleted,
            isLast: isLast,
          );
        }),
      ),
    );
  }

  Widget _buildTimelineCheckpointRow({
    required String text,
    required bool isCompleted,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── The vertical checkpoint track (Indicator node + line) ──
          Column(
            children: [
              const SizedBox(height: 2),
              _buildCheckpointNode(isCompleted),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: AppColors.gold.withOpacity(0.25),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // ── Checkpoint label ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: isCompleted
                  ? Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Monospace',
                        color: AppColors.ivoryDeep.withOpacity(0.55),
                      ),
                    )
                  : _buildShimmerText(text),
            ),
          ),
        ],
      ),
    );
  }

  // Node: Checked icon when complete, pulsing radar halo when currently active
  Widget _buildCheckpointNode(bool isCompleted) {
    if (isCompleted) {
      return Icon(
        Icons.check_circle_rounded,
        size: 13,
        color: AppColors.gold.withOpacity(0.7),
      );
    }

    // Active Node with breathing pulse
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final scale = 1.0 + 0.25 * math.sin(_shimmerController.value * math.pi);
        final opacity =
            0.3 + 0.7 * math.sin(_shimmerController.value * math.pi);

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(opacity * 0.25),
                ),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold,
              ),
            ),
          ],
        );
      },
    );
  }

  // Shimmer effect for current active step
  Widget _buildShimmerText(String text) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final width = bounds.width;
            if (width <= 0) {
              return const LinearGradient(
                colors: [AppColors.ivoryDeep, AppColors.ivoryDeep],
              ).createShader(bounds);
            }

            final start = -width + (width * 2 * _shimmerController.value);
            final end = start + width * 0.7;

            return LinearGradient(
              colors: const [
                AppColors.ivoryDeep,
                AppColors.goldLight,
                AppColors.ivoryDeep,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(
              Rect.fromLTWH(
                start,
                0,
                math.max(0.1, end - start),
                bounds.height,
              ),
            );
          },
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Monospace',
              color: AppColors.ivoryDeep,
            ),
          ),
        );
      },
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────
class _InputBar extends ConsumerWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.rightPadding,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  /// On mobile: set to (_kIconSize + 8) to keep content clear of the notch.
  /// On desktop: 12 (normal padding).
  final double rightPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStreaming = ref.watch(isStreamingProvider);
    debugPrint("STREAMING STATUS FROM INPUT BAR:$isStreaming");
    debugPrint("Inside Input Bar");
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, rightPadding, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ), // Removed vertical padding from container
              decoration: BoxDecoration(
                color: AppColors.ivory.withOpacity(0.92),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  // 1. Removes all borders across normal, focused, and enabled states
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,

                  hintText: 'Ask Sargam…',
                  filled: true,
                  fillColor: Colors.transparent,

                  // 2. Adjust these numbers to get the perfect thickness (e.g., 12 or 14)
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (isStreaming) {
                ref.read(aiAssistantProvider.notifier).stopStreaming();
                debugPrint("Stopped Stream...");
              } else {
                onSend();
              }
            },
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.textOnNavy,
              child: isStreaming
                  ? Icon(Icons.stop_rounded, size: 30, color: AppColors.navy)
                  : Icon(Icons.send_rounded, size: 20, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile notch clipper ──────────────────────────────────────────────────────
class _NotchedClipper extends CustomClipper<Path> {
  const _NotchedClipper({required this.notchRadius, this.cornerRadius = 28});
  final double notchRadius;
  final double cornerRadius;

  @override
  Path getClip(Size size) {
    final panel = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(cornerRadius),
        ),
      );

    final notch = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width - 25, size.height - 10),
          radius: notchRadius,
        ),
      );
    return Path.combine(PathOperation.difference, panel, notch);
  }

  @override
  bool shouldReclip(covariant _NotchedClipper old) =>
      old.notchRadius != notchRadius || old.cornerRadius != cornerRadius;
}
