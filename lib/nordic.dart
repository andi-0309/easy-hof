import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const fjord = Color(0xFF063C49);
const sun = Color(0xFFFFAA5B);

ThemeData nordicTheme(Brightness brightness, {bool wear = false}) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF007C90),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFF72E0EB) : const Color(0xFF007C90),
        onPrimary: dark ? const Color(0xFF0B303B) : Colors.white,
        primaryContainer: dark
            ? const Color(0xFF155564)
            : const Color(0xFFD6F4F7),
        onPrimaryContainer: dark ? const Color(0xFFE8F3F4) : fjord,
        secondary: sun,
        onSecondary: fjord,
        surface: dark ? const Color(0xFF0B303B) : const Color(0xFFF0FAFC),
        onSurface: dark ? const Color(0xFFE8F3F4) : fjord,
        onSurfaceVariant: dark
            ? const Color(0xFFBBE7EE)
            : const Color(0xFF397583),
        outline: dark ? const Color(0xFFBBE7EE) : const Color(0xFF5B95A2),
        error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB33B32),
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
  );
  final text = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  TextStyle heading(TextStyle? style, double size) => style!.copyWith(
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w600,
    fontSize: size,
    letterSpacing: -0.6,
    height: 1.25,
  );
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: text.copyWith(
      headlineLarge: heading(text.headlineLarge, 28),
      headlineMedium: heading(text.headlineMedium, 26),
      titleLarge: heading(text.titleLarge, 20),
      titleMedium: heading(text.titleMedium, 18),
      bodyLarge: text.bodyLarge!.copyWith(height: 1.5),
      bodyMedium: text.bodyMedium!.copyWith(
        fontSize: wear ? 14 : 16,
        height: 1.5,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF155564) : Colors.white,
      elevation: wear ? 1 : 5,
      shadowColor: fjord.withValues(alpha: .22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? const Color(0xFF87A5B2) : const Color(0xFFD6F4F7),
          width: .7,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _frameworkButtonStyle(scheme, wear),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _frameworkButtonStyle(scheme, wear),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _frameworkButtonStyle(scheme, wear),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFC3F2F8),
        foregroundColor: fjord,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: const Color(0xFF197F94),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? sun
            : const Color(0xFFC3F2F8),
      ),
      trackColor: WidgetStatePropertyAll(scheme.primaryContainer),
      trackOutlineColor: WidgetStatePropertyAll(scheme.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface.withValues(alpha: .85),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    ),
  );
}

ButtonStyle _frameworkButtonStyle(ColorScheme scheme, bool wear) =>
    TextButton.styleFrom(
      backgroundColor: const Color(0xFFC3F2F8),
      foregroundColor: fjord,
      disabledBackgroundColor: const Color(0xFF9DD8E1),
      disabledForegroundColor: const Color(0xFF397583),
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xFF197F94),
      elevation: 4,
      minimumSize: Size(40, wear ? 40 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF58ABBB)),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );

/// Resolution-independent ridgelines appear behind every route, including Wear OS.
class NordicBackdrop extends StatelessWidget {
  const NordicBackdrop({super.key, required this.child, this.breath});
  final ValueListenable<double>? breath;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value:
        (Theme.of(context).brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Theme.of(context).colorScheme.surface,
            ),
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: ValueListenableBuilder<double>(
                valueListenable: breath ?? const AlwaysStoppedAnimation(0.0),
                builder: (context, amount, _) => TweenAnimationBuilder<double>(
                  tween: Tween(
                    end: MediaQuery.disableAnimationsOf(context) ? 0 : amount,
                  ),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, _) => CustomPaint(
                    painter: MountainPainter(
                      dark: Theme.of(context).brightness == Brightness.dark,
                      breath: value,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}

/// A single scenic background: layered snowy ridges, foothills, trees and mist.
/// Coordinates are normalized so no bitmap or foreground illustration is needed.
class MountainPainter extends CustomPainter {
  const MountainPainter({required this.dark, this.breath = 0});
  final bool dark;
  final double breath;

  Path polygon(Size s, List<Offset> points) {
    final path = Path()
      ..moveTo(points.first.dx * s.width, points.first.dy * s.height);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx * s.width, p.dy * s.height);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final compact = w < 260;
    final band = Rect.fromLTWH(
      0,
      h - h * (compact ? .38 : .235),
      w,
      h * (compact ? .38 : .235),
    );
    final skyTop = dark ? const Color(0xFF123D4B) : const Color(0xFFF0FAFC);
    final skyBottom = dark ? const Color(0xFF0B303B) : const Color(0xFFEAF7F9);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyBottom],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.translate(band.left, band.top);
    final s = band.size;
    final atmosphere = Rect.fromLTWH(0, -s.height * .4, w, s.height * 1.7);
    canvas.saveLayer(atmosphere, Paint());
    final sw = s.width, sh = s.height;
    final sunCenter = Offset(sw * .77 + breath * 6, sh * .22 - breath * 18);
    canvas.drawCircle(
      sunCenter,
      sw * .12,
      Paint()
        ..shader = RadialGradient(
          colors: dark
              ? [const Color(0xFFFFC477), const Color(0xFFFF9D42)]
              : [const Color(0xFFFFD49A), const Color(0xFFFFA04A)],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: sw * .12)),
    );
    canvas.save();
    canvas.translate(-breath * 4.5, -breath * 6);
    final distant = Path()
      ..moveTo(0, sh * .63)
      ..lineTo(sw * .15, sh * .35)
      ..lineTo(sw * .31, sh * .54)
      ..lineTo(sw * .54, sh * .22)
      ..lineTo(sw * .72, sh * .48)
      ..lineTo(sw * .90, sh * .30)
      ..lineTo(sw, sh * .47)
      ..lineTo(sw, sh)
      ..lineTo(0, sh)
      ..close();
    canvas.drawPath(
      distant,
      Paint()..color = dark ? const Color(0xFF417F92) : const Color(0xFFB9E0E8),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(breath * 6, -breath * 12);
    final peaks = [
      const [
        Offset(-.12, .65),
        Offset(.06, .34),
        Offset(.115, .29),
        Offset(.21, .055),
        Offset(.25, .18),
        Offset(.31, .26),
        Offset(.37, .43),
        Offset(.47, .61),
        Offset(.57, .82),
        Offset(-.12, .94),
      ],
      const [
        Offset(.42, .78),
        Offset(.55, .51),
        Offset(.67, .34),
        Offset(.735, .17),
        Offset(.805, .12),
        Offset(.88, .29),
        Offset(.96, .40),
        Offset(1.12, .71),
        Offset(1.12, .96),
      ],
    ];
    for (var i = 0; i < peaks.length; i++) {
      final mountain = polygon(s, peaks[i]);
      canvas.drawPath(
        mountain,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [const Color(0xFF7FC7D5), const Color(0xFF33869A)]
                : [const Color(0xFF83C6D4), const Color(0xFF50A4B8)],
          ).createShader(Offset.zero & s),
      );
    }
    final snow = dark ? const Color(0xFFD9EDF0) : const Color(0xFFFFF8EE);
    canvas.drawPath(
      polygon(s, const [
        Offset(.21, .055),
        Offset(.25, .18),
        Offset(.31, .26),
        Offset(.37, .43),
        Offset(.29, .34),
        Offset(.263, .37),
        Offset(.22, .23),
        Offset(.20, .27),
        Offset(.17, .20),
        Offset(.19, .15),
      ]),
      Paint()..color = snow,
    );
    canvas.drawPath(
      polygon(s, const [
        Offset(.805, .12),
        Offset(.88, .29),
        Offset(.96, .40),
        Offset(.89, .35),
        Offset(.85, .38),
        Offset(.82, .29),
        Offset(.77, .32),
        Offset(.80, .21),
        Offset(.75, .25),
      ]),
      Paint()..color = snow,
    );
    final shadow = Paint()
      ..color = (dark ? const Color(0xFF136778) : const Color(0xFF2F91A6))
          .withValues(alpha: .55);
    for (final facet in [
      const [
        Offset(.21, .055),
        Offset(.19, .29),
        Offset(.08, .58),
        Offset(.25, .36),
        Offset(.20, .44),
        Offset(.31, .66),
        Offset(.18, .72),
      ],
      const [
        Offset(.805, .12),
        Offset(.81, .35),
        Offset(.70, .62),
        Offset(.88, .44),
        Offset(.79, .67),
        Offset(.96, .62),
      ],
      const [
        Offset(.115, .29),
        Offset(.06, .56),
        Offset(-.02, .63),
        Offset(.09, .50),
      ],
    ]) {
      canvas.drawPath(polygon(s, facet), shadow);
    }
    canvas.restore();
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate((i - 1) * breath * 4.5, -breath * (i + 1) * 3);
      final y = sh * (.49 + i * .15);
      final hills = Path()
        ..moveTo(-sw * .08, sh)
        ..lineTo(-sw * .08, y + sh * .13)
        ..cubicTo(
          sw * .12,
          y - sh * .12,
          sw * .18,
          y - sh * .06,
          sw * .35,
          y + sh * .08,
        )
        ..cubicTo(
          sw * .56,
          y + sh * .28,
          sw * .69,
          y - sh * .16,
          sw * 1.06,
          y + sh * .01,
        )
        ..lineTo(sw * 1.06, sh * 1.1)
        ..lineTo(-sw * .08, sh * 1.1)
        ..close();
      final colors = dark
          ? [
              const Color(0xFF358799),
              const Color(0xFF246E80),
              const Color(0xFF145465),
            ]
          : [
              const Color(0xFF75BBCB),
              const Color(0xFF4095A9),
              const Color(0xFF236F82),
            ];
      canvas.drawPath(
        hills,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors[i], colors[i].withValues(alpha: .72)],
          ).createShader(Offset.zero & s),
      );
      canvas.restore();
    }
    void tree(double x, double ground, double height) {
      final width = height * .43;
      final path = Path()
        ..moveTo(x, ground - height)
        ..lineTo(x - width * .38, ground - height * .55)
        ..lineTo(x - width * .16, ground - height * .58)
        ..lineTo(x - width * .58, ground - height * .26)
        ..lineTo(x - width * .27, ground - height * .29)
        ..lineTo(x - width * .72, ground - height * .05)
        ..lineTo(x - width * .07, ground - height * .10)
        ..lineTo(x - width * .07, ground)
        ..lineTo(x + width * .07, ground)
        ..lineTo(x + width * .07, ground - height * .10)
        ..lineTo(x + width * .72, ground - height * .05)
        ..lineTo(x + width * .27, ground - height * .29)
        ..lineTo(x + width * .58, ground - height * .26)
        ..lineTo(x + width * .16, ground - height * .58)
        ..lineTo(x + width * .38, ground - height * .55)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = dark ? const Color(0xFF0D485A) : const Color(0xFF1A6174),
      );
    }

    for (var i = 0; i < 34; i++) {
      final x = sw * i / 33;
      final edge = (x / sw - .5).abs() * 2;
      final ground = sh * (.97 - edge * .13);
      final height =
          sh *
          (.035 + math.pow(edge, 2) * (.12 + .06 * math.sin(i * 2.7).abs()));
      tree(x, ground, height);
    }
    tree(sw * .07, sh * .89, sh * .29);
    tree(sw * .115, sh * .91, sh * .23);
    tree(sw * .88, sh * .90, sh * .24);
    tree(sw * .94, sh * .88, sh * .31);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(MountainPainter old) =>
      old.dark != dark || old.breath != breath;
}

class NordicCard extends StatelessWidget {
  const NordicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF216E7D), const Color(0xFF154957)]
              : [Colors.white.withValues(alpha: .97), const Color(0xFFE7F7FA)],
        ),
        border: Border.all(
          color: (dark ? const Color(0xFF72E0EB) : Colors.white).withValues(
            alpha: .55,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: fjord.withValues(alpha: dark ? .35 : .13),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (dark ? Colors.black : const Color(0xFFACCDD0)).withValues(
              alpha: .25,
            ),
            offset: const Offset(0, 3),
            blurRadius: 1,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

enum NordicTone { sun, ice, petrol }

List<Color> nordicButtonColors(NordicTone tone, {bool disabled = false}) =>
    switch (tone) {
      NordicTone.sun =>
        disabled
            ? const [Color(0xFFFFDEAD), Color(0xFFFFB361)]
            : const [Color(0xFFFFC05A), Color(0xFFFF8B17)],
      NordicTone.ice =>
        disabled
            ? const [Color(0xFFD8F3F7), Color(0xFF9DD8E1)]
            : const [Color(0xFFC3F2F8), Color(0xFF51B9CD)],
      NordicTone.petrol =>
        disabled
            ? const [Color(0xFF7FC1CC), Color(0xFF3F899A)]
            : const [Color(0xFF259CAF), Color(0xFF006379)],
    };

/// One opaque 3D surface for every app-owned action. Material has zero
/// elevation and tint so a transparent elevated Material cannot grey the fill.
class NordicButton extends StatefulWidget {
  const NordicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tone = NordicTone.ice,
    this.height = 56,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.radius = 24,
    this.minWidth = 48,
  }) : icon = null,
       label = null;
  const NordicButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.tone = NordicTone.ice,
    this.height = 56,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.radius = 24,
    this.minWidth = 48,
  }) : child = null;
  final VoidCallback? onPressed;
  final Widget? child, icon, label;
  final NordicTone tone;
  final double height, fontSize, radius, minWidth;
  final EdgeInsetsGeometry padding;
  @override
  State<NordicButton> createState() => _NordicButtonState();
}

class _NordicButtonState extends State<NordicButton> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final foreground = widget.tone == NordicTone.petrol ? Colors.white : fjord;
    final ridge = switch (widget.tone) {
      NordicTone.sun => const Color(0xFFB95300),
      NordicTone.ice => const Color(0xFF197F94),
      NordicTone.petrol => const Color(0xFF003D50),
    };
    final radius = BorderRadius.circular(widget.radius);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: AnimatedContainer(
          duration: Duration(
            milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 90,
          ),
          transform: Matrix4.translationValues(0, down && enabled ? 3 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: nordicButtonColors(widget.tone, disabled: !enabled),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: .5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: ridge.withValues(alpha: enabled ? 1 : .4),
                offset: Offset(0, down ? 1 : 4),
              ),
              if (enabled)
                BoxShadow(
                  color: ridge.withValues(alpha: .18),
                  blurRadius: 12,
                  offset: const Offset(0, 7),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: radius,
              splashColor: Colors.white.withValues(alpha: .2),
              highlightColor: Colors.white.withValues(alpha: .10),
              onHighlightChanged: enabled
                  ? (value) => setState(() => down = value)
                  : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: widget.minWidth,
                  minHeight: widget.height,
                ),
                child: Padding(
                  padding: widget.padding,
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: IconTheme.merge(
                      data: IconThemeData(
                        color: foreground.withValues(alpha: enabled ? 1 : .65),
                      ),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w700,
                          color: foreground.withValues(
                            alpha: enabled ? 1 : .65,
                          ),
                        ),
                        child: widget.icon == null
                            ? widget.child!
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  widget.icon!,
                                  const SizedBox(width: 8),
                                  Flexible(child: widget.label!),
                                ],
                              ),
                      ),
                    ),
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

class SunButton extends StatelessWidget {
  const SunButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.play_arrow_rounded,
    this.secondary = false,
    this.large = false,
    this.deep = false,
    this.height,
  });
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool secondary, large, deep;
  final double? height;
  @override
  Widget build(BuildContext context) => NordicButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
    tone: deep
        ? NordicTone.petrol
        : secondary
        ? NordicTone.ice
        : NordicTone.sun,
    height: height ?? (large ? 76 : 56),
    fontSize: large ? 21 : 16,
    radius: 32,
  );
}

class NordicIconButton extends StatelessWidget {
  const NordicIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.iconSize = 24,
    this.padding,
    this.constraints,
    this.visualDensity,
  });
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final VisualDensity? visualDensity;
  @override
  Widget build(BuildContext context) {
    final small = visualDensity == VisualDensity.compact;
    final size = constraints?.minWidth ?? (small ? 40.0 : 48.0);
    final symbol = icon is Icon
        ? Icon(
            (icon as Icon).icon,
            size: (icon as Icon).size ?? iconSize,
            color: fjord,
            semanticLabel: (icon as Icon).semanticLabel,
          )
        : icon;
    final button = NordicButton(
      onPressed: onPressed,
      height: size - 2,
      minWidth: size - 2,
      radius: 16,
      padding: padding ?? EdgeInsets.all(small ? 8 : 10),
      child: symbol,
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class NordicSegmented<T> extends StatelessWidget {
  const NordicSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.showSelectedIcon = false,
  });
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final bool showSelectedIcon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < segments.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            selected: selected.contains(segments[i].value),
            child: NordicButton(
              onPressed: onSelectionChanged == null || !segments[i].enabled
                  ? null
                  : () => onSelectionChanged!({segments[i].value}),
              tone: selected.contains(segments[i].value)
                  ? NordicTone.petrol
                  : NordicTone.ice,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: segments[i].label ?? Text('${segments[i].value}'),
            ),
          ),
        ),
      ],
    ],
  );
}

class NordicDropdown<T> extends StatelessWidget {
  const NordicDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = true,
    this.height = 56,
  });
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final double height;
  @override
  Widget build(BuildContext context) => NordicButton(
    onPressed: onChanged == null
        ? null
        : () async {
            final choice = await showDialog<T>(
              context: context,
              builder: (context) => SimpleDialog(
                insetPadding: const EdgeInsets.all(12),
                contentPadding: const EdgeInsets.all(12),
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: NordicButton(
                        tone: item.value == value
                            ? NordicTone.petrol
                            : NordicTone.ice,
                        onPressed: !item.enabled
                            ? null
                            : () => Navigator.pop(context, item.value),
                        child: item.child,
                      ),
                    ),
                ],
              ),
            );
            if (choice != null) onChanged?.call(choice);
          },
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: items.firstWhere((item) => item.value == value).child),
        const SizedBox(width: 8),
        const Icon(Icons.expand_more_rounded),
      ],
    ),
  );
}

class NordicNavigationBar extends StatelessWidget {
  const NordicNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: nordicPageWidth),
      child: ColoredBox(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Semantics(
                        selected: i == selectedIndex,
                        child: NordicButton(
                          onPressed: () => onDestinationSelected(i),
                          tone: i == selectedIndex
                              ? NordicTone.petrol
                              : NordicTone.ice,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 9,
                          ),
                          height: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              destinations[i].icon,
                              const SizedBox(height: 4),
                              Text(
                                destinations[i].label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shared phone grid for headers, route content and fixed actions.
const nordicPageWidth = 560.0;
const nordicPageInset = 24.0;

class NordicAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NordicAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight = 56,
  });
  final Widget title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final double toolbarHeight;
  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
  @override
  Widget build(BuildContext context) {
    final back = automaticallyImplyLeading && Navigator.canPop(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: nordicPageWidth),
        child: AppBar(
          toolbarHeight: toolbarHeight,
          automaticallyImplyLeading: false,
          titleSpacing: back ? 12 : nordicPageInset,
          title: title,
          leadingWidth: back ? 72 : null,
          leading: back
              ? Padding(
                  padding: const EdgeInsets.only(left: nordicPageInset),
                  child: Center(
                    child: NordicIconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                )
              : null,
          actionsPadding: const EdgeInsets.only(right: nordicPageInset),
          actions: actions,
        ),
      ),
    );
  }
}
