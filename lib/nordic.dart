import 'dart:math' as math;
import 'package:flutter/material.dart';
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
      style: FilledButton.styleFrom(
        minimumSize: Size(48, wear ? 48 : 56),
        elevation: 5,
        shadowColor: fjord.withValues(alpha: .45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.primary.withValues(alpha: .35),
            width: 1.5,
          ),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(48, wear ? 48 : 56),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 4,
        shadowColor: fjord.withValues(alpha: .35),
        side: BorderSide(
          color: scheme.primary.withValues(alpha: .35),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: wear ? 12 : 20, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface.withValues(alpha: .85),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(16),
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

/// Resolution-independent ridgelines appear behind every route, including Wear OS.
class NordicBackdrop extends StatelessWidget {
  const NordicBackdrop({super.key, required this.child});
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
              child: CustomPaint(
                painter: MountainPainter(
                  dark: Theme.of(context).brightness == Brightness.dark,
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
  const MountainPainter({required this.dark});
  final bool dark;

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
      h * (compact ? .57 : .405),
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
    final sunCenter = Offset(sw * .77, sh * .22);
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
    for (var i = 0; i < 3; i++) {
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
    // Mist dissolves the bottom of the landscape back into the page.
    canvas.drawRect(
      atmosphere,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, .68, 1],
        ).createShader(Rect.fromLTWH(0, 0, sw, sh * 1.13)),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(MountainPainter old) => old.dark != dark;
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

class SunButton extends StatefulWidget {
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
  final bool secondary;
  final bool large;
  final bool deep;
  final double? height;
  @override
  State<SunButton> createState() => _SunButtonState();
}

class _SunButtonState extends State<SunButton> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Listener(
        onPointerDown: disabled ? null : (_) => setState(() => down = true),
        onPointerUp: (_) => setState(() => down = false),
        onPointerCancel: (_) => setState(() => down = false),
        child: AnimatedContainer(
          duration: Duration(milliseconds: reduced ? 0 : 100),
          transform: Matrix4.translationValues(0, down && !disabled ? 3 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: disabled
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.deep
                        ? [const Color(0xFF36A2B3), const Color(0xFF086B7E)]
                        : widget.secondary
                        ? [const Color(0xFFB1EBF1), const Color(0xFF56BDCE)]
                        : [const Color(0xFFFFD49A), sun],
                  ),
            color: disabled ? const Color(0xFFD3D9D9) : null,
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: widget.deep
                          ? const Color(0xFF024C5D)
                          : widget.secondary
                          ? const Color(0xFF346B79)
                          : const Color(0xFFA95729),
                      offset: Offset(0, down ? 1 : 4),
                    ),
                  ],
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: Size(48, widget.height ?? (widget.large ? 76 : 56)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              textStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: widget.large ? 21 : 16,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: widget.deep ? Colors.white : fjord,
              disabledForegroundColor: const Color(0xFF397583),
            ),
            onPressed: widget.onPressed,
            icon: Icon(widget.icon),
            label: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
