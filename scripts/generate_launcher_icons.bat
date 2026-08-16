@echo off
echo Generating launcher icons from assets/images/app_logo.png
echo Running flutter pub get...
flutter pub get

echo Running flutter_launcher_icons...
flutter pub run flutter_launcher_icons:main

if %ERRORLEVEL% NEQ 0 (
  echo Error: launcher icon generation failed.
  pause
  exit /b %ERRORLEVEL%
)

echo Launcher icons generated. Rebuild the app to apply the new icons to installed devices.
echo Android (example): flutter build apk --release
echo Android app bundle: flutter build appbundle --release
echo iOS (example): flutter build ipa --release (or open Xcode and archive)
pause
