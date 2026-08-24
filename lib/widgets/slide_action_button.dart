import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlideActionButton extends StatefulWidget {
  const SlideActionButton({
    super.key,
    required this.label,
    required this.onCompleted,
    this.successLabel,
    this.onError,
    this.icon = Icons.arrow_forward_ios_rounded,
    this.height = 62,
    this.color = const Color(0xFF7C4DFF),
  });

  final String label;
  final String? successLabel;
  final Future<void> Function() onCompleted;
  final void Function(Object error)? onError;
  final IconData icon;
  final double height;
  final Color color;

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton>
    with TickerProviderStateMixin {
  late final AnimationController _resetController;
  late final AnimationController _pulseController;
  late Animation<double> _resetAnim;

  double _dragExtent = 0;
  bool _busy = false;
  bool _done = false;
  bool _hapticPassed = false;

  static const double _thumbSize = 56;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _resetAnim = AlwaysStoppedAnimation(0);
    _resetController.addListener(() {
      if (!mounted) return;
      setState(() {
        _dragExtent = _resetAnim.value.clamp(0.0, double.infinity).toDouble();
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _snapBack() {
    _hapticPassed = false;
    _resetAnim = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetController.forward(from: 0);
  }

  void _onDragStart(DragStartDetails details) {
    if (_busy || _done) return;
    _resetController.stop();
    HapticFeedback.selectionClick();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_busy || _done) return;
    setState(() {
      _dragExtent =
          (_dragExtent + details.delta.dx).clamp(0.0, maxDrag).toDouble();
    });

    if (!_hapticPassed && _dragExtent >= maxDrag * 0.82) {
      _hapticPassed = true;
      HapticFeedback.mediumImpact();
    } else if (_hapticPassed && _dragExtent < maxDrag * 0.82) {
      _hapticPassed = false;
    }
  }

  Future<void> _onDragEnd(DragEndDetails details, double maxDrag) async {
    if (_busy || _done) return;

    final fling = (details.primaryVelocity ?? 0) > 650;
    final reached = _dragExtent >= maxDrag * 0.82 || (fling && _dragExtent > maxDrag * 0.45);

    if (!reached) {
      _snapBack();
      return;
    }

    setState(() {
      _busy = true;
      _dragExtent = maxDrag;
    });
    HapticFeedback.heavyImpact();

    bool succeeded = false;
    Object? failure;
    try {
      await widget.onCompleted();
      succeeded = true;
    } catch (e) {
      failure = e;
      succeeded = false;
    }

    if (!mounted) return;

    if (succeeded) {
      setState(() => _done = true);
    } else {
      setState(() => _busy = false);
      _snapBack();
      if (widget.onError != null && failure != null) {
        widget.onError!(failure);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.height / 2);

    if (_done) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: 1,
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withValues(alpha: 0.95),
                widget.color.withValues(alpha: 0.70),
              ],
            ),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                widget.successLabel ?? "DONE",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxDrag = trackWidth - _thumbSize - 8;
        final progress = maxDrag <= 0 ? 0.0 : (_dragExtent / maxDrag);

        return GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
          onHorizontalDragEnd: (d) => _onDragEnd(d, maxDrag),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final t = _pulseController.value;

              return Container(
                width: trackWidth,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      widget.color.withValues(alpha: 0.28 + progress * 0.25),
                      widget.color.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: radius,
                  border: Border.all(
                    color: widget.color
                        .withValues(alpha: 0.50 + progress * 0.40),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color
                          .withValues(alpha: 0.20 + progress * 0.30),
                      blurRadius: 14 + progress * 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4 + _dragExtent + _thumbSize / 2,
                      child: ClipRRect(
                        borderRadius: radius,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withValues(alpha: 0.42),
                                widget.color.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(left: 66 + progress * 40),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: _busy ? 0.55 : (1.0 - progress * 0.55),
                            child: _busy
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          "Processing…",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    widget.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.3,
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 22 + (1 - t.clamp(0.0, 1.0).toDouble()) * 26,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Opacity(
                          opacity:
                              (progress < 0.15 && !_busy ? 0.65 : 0.0) *
                                  (0.5 +
                                      0.5 *
                                          (t < 0.5 ? t * 2 : (1 - t) * 2)),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 4 + _dragExtent,
                      top: (widget.height - _thumbSize) / 2,
                      child: Transform.scale(
                        scale: 1.0 + progress * 0.08,
                        child: Container(
                          width: _thumbSize,
                          height: _thumbSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(widget.color, Colors.white, 0.18)!,
                                Color.lerp(widget.color, Colors.black, 0.32)!,
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.60),
                                blurRadius: 18 + progress * 8,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _busy
                                ? const SizedBox(
                                    key: ValueKey('spinner'),
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : Icon(
                                    progress >= 0.82
                                        ? Icons.check_rounded
                                        : widget.icon,
                                    key: ValueKey(progress >= 0.82),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
