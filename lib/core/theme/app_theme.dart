import 'package:flutter/material.dart';
import 'package:house_note/core/constants/app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: AppColors.primaryColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        accentColor: AppColors.accentColor, // accentColor는 곧 지원 중단될 예정입니다.
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFFFF8A65),
        titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        trackVisibility: WidgetStateProperty.all(true),
        thumbColor: WidgetStateProperty.all(Colors.grey[400]),
        trackColor: WidgetStateProperty.all(Colors.grey[200]),
        radius: const Radius.circular(10),
        thickness: WidgetStateProperty.all(8.0),
        minThumbLength: 48,
      ),
      // ... 기타 테마 설정
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue[700],
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        accentColor: Colors.lightBlueAccent[100],
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.grey[850],
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFFFF8A65),
        titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        trackVisibility: WidgetStateProperty.all(true),
        thumbColor: WidgetStateProperty.all(Colors.grey[400]),
        trackColor: WidgetStateProperty.all(Colors.grey[200]),
        radius: const Radius.circular(10),
        thickness: WidgetStateProperty.all(8.0),
        minThumbLength: 48,
      ),
      // ...
    );
  }
}
