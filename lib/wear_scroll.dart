import 'dart:async';
import 'package:flutter/material.dart';
import 'rotary.dart';
import 'water_lock.dart';

/// Only the top route consumes the crown, including confirmation text.
class WearScroll extends StatefulWidget {
  const WearScroll({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  static Stream<double> get events => Rotary.events;
  @override
  State<WearScroll> createState() => _WearScrollState();
}

class _WearScrollState extends State<WearScroll> {
  final controller = ScrollController();
  StreamSubscription<double>? subscription;
  bool locked = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    locked = WearWaterLock.lockedOf(context);
  }

  @override
  void initState() {
    super.initState();
    subscription = WearScroll.events.listen((delta) {
      if (!mounted ||
          !controller.hasClients ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      if (locked) return;
      final position = controller.position;
      controller.jumpTo(
        (controller.offset + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    controller: controller,
    padding: widget.padding,
    children: widget.children,
  );
}
