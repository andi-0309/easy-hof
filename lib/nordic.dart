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
    scaffoldBackgroundColor: scheme.surface,
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
      backgroundColor: scheme.surface,
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
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
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

class NordicLandscape extends StatelessWidget {
  const NordicLandscape({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/nordic-mountains.webp',
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

class SunButton extends StatefulWidget {
  const SunButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.play_arrow_rounded,
  });
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
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
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFC584), sun],
                  ),
            color: disabled ? const Color(0xFFD3D9D9) : null,
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFFA95729),
                      offset: Offset(0, down ? 1 : 4),
                    ),
                  ],
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
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
