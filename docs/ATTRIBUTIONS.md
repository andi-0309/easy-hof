# Design & dependencies

Nordic Elements v1.1, supplied by Andreas Aichele: snow #EFF5F5, ice #CEE8EE,
petrol #075B68, sun #FFAA5B and fjord #102F3A. Mountain artwork extracted from the
user-supplied styleguide; used as a decorative asset, without text overlays.

Manrope and Inter variable fonts are bundled locally. See their SIL Open Font
License files in `assets/fonts/`. No online font requests occur at runtime.

The phone-only watch installer uses LibADB Android 3.1.1 by Muntashir Al-Islam
(dual Apache-2.0 / GPL-3.0-or-later; used under Apache-2.0) and Conscrypt 2.5.3
(Apache-2.0). LibADB includes Bouncy Castle and spake2-java dependencies. Upstream:
https://github.com/MuntashirAkon/libadb-android and https://conscrypt.org/.
These libraries are absent from the watch flavor. AndroidKeyStore holds the
installation identity privately on the phone. No keystore is shipped in source.

Flutter uses the BSD-3-Clause license. AndroidX, Kotlin and Material icons use
Apache-2.0. Google Play services for Wearable follows Google's SDK terms.
See Flutter's license registry and upstream packages for their notices.
