import 'package:flutter/material.dart';

const fjord = Color(0xFF102F3A);
const sun = Color(0xFFFFAA5B);

ThemeData nordicTheme(Brightness brightness, {bool wear = false}) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF075B68),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFF94D7DF) : const Color(0xFF075B68),
        onPrimary: dark ? const Color(0xFF081821) : Colors.white,
        primaryContainer: dark
            ? const Color(0xFF193644)
            : const Color(0xFFCEE8EE),
        onPrimaryContainer: dark ? const Color(0xFFE8F3F4) : fjord,
        secondary: sun,
        onSecondary: fjord,
        surface: dark ? const Color(0xFF081821) : const Color(0xFFEFF5F5),
        onSurface: dark ? const Color(0xFFE8F3F4) : fjord,
        onSurfaceVariant: dark
            ? const Color(0xFFADC2C8)
            : const Color(0xFF405C66),
        outline: dark ? const Color(0xFFADC2C8) : const Color(0xFF637F89),
        error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB33B32),
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
  );
  final text = base.textTheme;
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
      color: dark ? const Color(0xFF193644) : Colors.white,
      elevation: wear ? 1 : 5,
      shadowColor: fjord.withValues(alpha: .22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? const Color(0xFF87A5B2) : const Color(0xFFCEE8EE),
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
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: MountainPainter(
                dark: Theme.of(context).brightness == Brightness.dark,
                subtle: true,
              ),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

class MountainPainter extends CustomPainter {
  const MountainPainter({
    required this.dark,
    this.subtle = false,
    this.transparentSky = false,
  });
  final bool dark;
  final bool subtle;
  final bool transparentSky;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? [const Color(0xFF102F3A), const Color(0xFF081821)]
            : [const Color(0xFFE4F1F1), const Color(0xFFF7F6EF)],
      ).createShader(Offset.zero & size);
    if (!subtle && !transparentSky) canvas.drawRect(Offset.zero & size, sky);
    canvas.drawCircle(
      Offset(w * .79, h * (subtle ? .16 : .24)),
      w * (subtle ? .13 : .09),
      Paint()..color = sun.withValues(alpha: subtle ? (dark ? .06 : .10) : .9),
    );
    final top = subtle ? .69 : .22;
    for (var layer = 0; layer < 3; layer++) {
      final y = h * (top + layer * .12);
      final path = Path()
        ..moveTo(0, h)
        ..lineTo(0, y + h * .23)
        ..lineTo(w * .16, y + h * .10)
        ..lineTo(w * .29, y + h * .20)
        ..lineTo(w * .52, y)
        ..lineTo(w * .70, y + h * .20)
        ..lineTo(w * .86, y + h * .07)
        ..lineTo(w, y + h * .24)
        ..lineTo(w, h)
        ..close();
      canvas.drawShadow(
        path,
        fjord.withValues(alpha: subtle ? .08 : .3),
        6,
        false,
      );
      final colors = dark
          ? [
              const Color(0xFF427381),
              const Color(0xFF245461),
              const Color(0xFF102F3A),
            ]
          : [
              const Color(0xFFA5CDD2),
              const Color(0xFF639DA7),
              const Color(0xFF255C6B),
            ];
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[layer].withValues(
            alpha: subtle ? (dark ? .18 : .13) : 1,
          ),
      );
      if (layer == 0 && !subtle) {
        final snow = Path()
          ..moveTo(w * .52, y)
          ..lineTo(w * .44, y + h * .07)
          ..lineTo(w * .51, y + h * .05)
          ..lineTo(w * .56, y + h * .09)
          ..lineTo(w * .59, y + h * .08)
          ..close();
        canvas.drawPath(snow, Paint()..color = const Color(0xFFE8F3F4));
      }
    }
  }

  @override
  bool shouldRepaint(MountainPainter old) =>
      old.dark != dark ||
      old.subtle != subtle ||
      old.transparentSky != transparentSky;
}

class NordicLandscape extends StatelessWidget {
  const NordicLandscape({super.key, this.height = 112});
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: MountainPainter(
            dark: Theme.of(context).brightness == Brightness.dark,
            transparentSky: true,
          ),
        ),
      ),
    ),
  );
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
              ? [const Color(0xFF244957), const Color(0xFF142F3C)]
              : [Colors.white.withValues(alpha: .97), const Color(0xFFE4F0F0)],
        ),
        border: Border.all(
          color: (dark ? const Color(0xFF94D7DF) : Colors.white).withValues(
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
  });
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool secondary;
  final bool large;
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
                    colors: widget.secondary
                        ? [const Color(0xFFB1E3E4), const Color(0xFF70BAC5)]
                        : [const Color(0xFFFFD49A), sun],
                  ),
            color: disabled ? const Color(0xFFD3D9D9) : null,
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: widget.secondary
                          ? const Color(0xFF346B79)
                          : const Color(0xFFA95729),
                      offset: Offset(0, down ? 1 : 4),
                    ),
                  ],
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: Size(48, widget.large ? 76 : 56),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              textStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: widget.large ? 21 : 16,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: fjord,
              disabledForegroundColor: const Color(0xFF405C66),
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
