import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Light palette (defaults)
const Color kBackground = Color(0xFFFDFFFC);
const Color kTextGreen = Color(0xFF3D6F3D);
const Color kMint = Color(0xFFE5FFE4);
const Color kAccentGreen = Color(0xFF7ED957);

// Night palette
const Color kNightBackground = Color(0xFF082801);
const Color kNightText = Color(0xFF7ED957);
const Color kNightCloseButton = Color(0xFFF7FFF4);

/// 135° border gradient: transparent #fdfffc → mint → #7ed957
const LinearGradient kBorderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0x00FDFFFC),
    kMint,
    kAccentGreen,
  ],
);

/// 135° fill gradient: transparent white → mint
const LinearGradient kFillGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0x00FFFFFF),
    kMint,
  ],
);

/// Night 135° fill/border gradient: transparent white → #082801
const LinearGradient kNightGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0x00FFFFFF),
    kNightBackground,
  ],
);

/// App-specific colors that switch with night mode.
class NomNomTheme extends ThemeExtension<NomNomTheme> {
  const NomNomTheme({
    required this.background,
    required this.text,
    required this.accent,
    required this.mint,
    required this.closeButtonBackground,
    required this.closeButtonIcon,
    required this.borderGradient,
    required this.fillGradient,
  });

  final Color background;
  final Color text;
  final Color accent;
  final Color mint;
  final Color closeButtonBackground;
  final Color closeButtonIcon;
  final LinearGradient borderGradient;
  final LinearGradient fillGradient;

  static const NomNomTheme light = NomNomTheme(
    background: kBackground,
    text: kTextGreen,
    accent: kAccentGreen,
    mint: kMint,
    closeButtonBackground: kTextGreen,
    closeButtonIcon: Colors.white,
    borderGradient: kBorderGradient,
    fillGradient: kFillGradient,
  );

  static const NomNomTheme night = NomNomTheme(
    background: kNightBackground,
    text: kNightText,
    accent: kAccentGreen,
    mint: kMint,
    closeButtonBackground: kNightCloseButton,
    closeButtonIcon: kNightBackground,
    borderGradient: kNightGradient,
    fillGradient: kNightGradient,
  );

  @override
  NomNomTheme copyWith({
    Color? background,
    Color? text,
    Color? accent,
    Color? mint,
    Color? closeButtonBackground,
    Color? closeButtonIcon,
    LinearGradient? borderGradient,
    LinearGradient? fillGradient,
  }) {
    return NomNomTheme(
      background: background ?? this.background,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      mint: mint ?? this.mint,
      closeButtonBackground:
          closeButtonBackground ?? this.closeButtonBackground,
      closeButtonIcon: closeButtonIcon ?? this.closeButtonIcon,
      borderGradient: borderGradient ?? this.borderGradient,
      fillGradient: fillGradient ?? this.fillGradient,
    );
  }

  @override
  NomNomTheme lerp(ThemeExtension<NomNomTheme>? other, double t) {
    if (other is! NomNomTheme) return this;
    return NomNomTheme(
      background: Color.lerp(background, other.background, t)!,
      text: Color.lerp(text, other.text, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      closeButtonBackground:
          Color.lerp(closeButtonBackground, other.closeButtonBackground, t)!,
      closeButtonIcon: Color.lerp(closeButtonIcon, other.closeButtonIcon, t)!,
      borderGradient:
          t < 0.5 ? borderGradient : other.borderGradient,
      fillGradient: t < 0.5 ? fillGradient : other.fillGradient,
    );
  }
}

NomNomTheme nomnomTheme(BuildContext context) =>
    Theme.of(context).extension<NomNomTheme>()!;

ThemeData buildAppTheme({required bool nightMode}) {
  final palette = nightMode ? NomNomTheme.night : NomNomTheme.light;
  final textTheme = GoogleFonts.anticTextTheme(
    ThemeData.light().textTheme,
  ).apply(
    bodyColor: palette.text,
    displayColor: palette.text,
  );

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.text,
      brightness: nightMode ? Brightness.dark : Brightness.light,
      surface: palette.background,
    ),
    scaffoldBackgroundColor: palette.background,
    textTheme: textTheme,
    iconTheme: IconThemeData(color: palette.text),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.background,
    ),
    extensions: [palette],
  );
}
