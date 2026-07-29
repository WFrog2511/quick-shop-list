import 'package:flutter/material.dart';

/// テーマ(ライト/ダーク)に応じて切り替わるアプリ独自カラー定義。
/// ThemeExtensionとして登録し、`AppColors.of(context)` で
/// 現在のテーマに対応した色を取得する。
class AppColors extends ThemeExtension<AppColors> {
  final Color primaryGreen;
  final Color lightGreen;
  final Color accentBlue;
  final Color background;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color checkedGray;

  const AppColors({
    required this.primaryGreen,
    required this.lightGreen,
    required this.accentBlue,
    required this.background,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.checkedGray,
  });

  /// 現在のテーマに対応するAppColorsを取得するショートカット
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? light;
  }

  /// Style 1: マテリアルデザイン準拠のライトテーマ(グリーン基調)
  static const AppColors light = AppColors(
    primaryGreen: Color(0xFF2E7D32),
    lightGreen: Color(0xFFE8F5E9),
    accentBlue: Color(0xFF1565C0),
    background: Color(0xFFFAFAFA),
    cardBackground: Colors.white,
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF757575),
    divider: Color(0xFFE0E0E0),
    checkedGray: Color(0xFFBDBDBD),
  );

  /// ダークテーマ(グリーン基調は保ちつつ、目に優しい暗色パレット)
  static const AppColors dark = AppColors(
    primaryGreen: Color(0xFF66BB6A),
    lightGreen: Color(0xFF1F3B22),
    accentBlue: Color(0xFF64B5F6),
    background: Color(0xFF121212),
    cardBackground: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFECECEC),
    textSecondary: Color(0xFFA6A6A6),
    divider: Color(0xFF3A3A3A),
    checkedGray: Color(0xFF6B6B6B),
  );

  @override
  AppColors copyWith({
    Color? primaryGreen,
    Color? lightGreen,
    Color? accentBlue,
    Color? background,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? checkedGray,
  }) {
    return AppColors(
      primaryGreen: primaryGreen ?? this.primaryGreen,
      lightGreen: lightGreen ?? this.lightGreen,
      accentBlue: accentBlue ?? this.accentBlue,
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      checkedGray: checkedGray ?? this.checkedGray,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primaryGreen: Color.lerp(primaryGreen, other.primaryGreen, t)!,
      lightGreen: Color.lerp(lightGreen, other.lightGreen, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      background: Color.lerp(background, other.background, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      checkedGray: Color.lerp(checkedGray, other.checkedGray, t)!,
    );
  }
}

ThemeData buildLightTheme() => _buildTheme(AppColors.light, Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(AppColors.dark, Brightness.dark);

ThemeData _buildTheme(AppColors colors, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.primaryGreen,
      brightness: brightness,
      primary: colors.primaryGreen,
      secondary: colors.accentBlue,
      surface: colors.cardBackground,
    ),
    extensions: [colors],
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: colors.cardBackground,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.divider, width: 1),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: colors.cardBackground),
    dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.accentBlue,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: colors.accentBlue, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.cardBackground,
      selectedItemColor: colors.primaryGreen,
      unselectedItemColor: colors.textSecondary,
      showUnselectedLabels: true,
      elevation: 8,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const CircleBorder(),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.primaryGreen;
        }
        return Colors.transparent;
      }),
    ),
  );
}
