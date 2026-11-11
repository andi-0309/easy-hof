import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rotary.dart';

/// App-scoped protection from wet touches. Real crown input unlocks it.
class WearWaterLock extends StatefulWidget {
  const WearWaterLock({
    super.key,
    required this.activeId,
    required this.child,
    this.language = 'en',
  });
  final String? activeId;
  final Widget child;
  final String language;
  static bool lockedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WaterLockScope>()?.locked ??
      false;
  @override
  State<WearWaterLock> createState() => _WearWaterLockState();
}

class _WearWaterLockState extends State<WearWaterLock> {
  late bool locked;
  double progress = 0;
  Timer? reset;
  StreamSubscription<double>? subscription;
  @override
  void initState() {
    super.initState();
    locked = widget.activeId != null;
    subscription = Rotary.events.listen((delta) {
      if (!mounted || !locked || ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      reset?.cancel();
      setState(() {
        progress = (progress + delta.abs() / 240).clamp(0, 1);
        if (progress >= 1) {
          locked = false;
          progress = 0;
          HapticFeedback.selectionClick();
        }
      });
      reset = Timer(const Duration(seconds: 3), () {
        if (mounted && locked) setState(() => progress = 0);
      });
    });
  }

  @override
  void didUpdateWidget(covariant WearWaterLock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeId != widget.activeId) {
      locked = widget.activeId != null;
      progress = 0;
      reset?.cancel();
    }
  }

  @override
  void dispose() {
    reset?.cancel();
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _WaterLockScope(
    locked: locked,
    child: Stack(
      children: [
        IgnorePointer(ignoring: locked, child: widget.child),
        if (locked)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 77,
                alignment: const Alignment(0, -.25),
                child: Semantics(
                  label: widget.language == 'de'
                      ? 'Wassersperre'
                      : 'Water lock',
                  hint: widget.language == 'de'
                      ? 'Krone zum Entsperren drehen'
                      : 'Rotate the crown to unlock',
                  child: SizedBox.square(
                    dimension: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .18),
                        ),
                        Icon(
                          Icons.lock_rounded,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _WaterLockScope extends InheritedWidget {
  const _WaterLockScope({required this.locked, required super.child});
  final bool locked;
  @override
  bool updateShouldNotify(_WaterLockScope oldWidget) =>
      oldWidget.locked != locked;
}
