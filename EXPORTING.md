# Mobile export handoff

The project is already configured around a fixed 360×640 portrait canvas, integer scaling, touch controls, and the mobile-compatible GL renderer.

## Android

1. Install the Android SDK/JDK components requested by Godot 4.7.
2. Configure their paths in Godot's Editor Settings.
3. Install the matching Godot Android export template.
4. Add an Android export preset and choose a unique reverse-domain package name.
5. Use a debug keystore for device testing, then a protected release keystore for store builds.
6. Test touch targets, audio resume, pause/background behavior, and several screen aspect ratios on real hardware.

## iOS

1. Open the project on macOS with Godot 4.7 and Xcode installed.
2. Install the matching iOS export template.
3. Add an iOS preset, bundle identifier, Apple development team, and signing profile.
4. Export the Xcode project, build from Xcode, and verify safe areas and audio interruption behavior on a physical device.

Signing identities, package identifiers, store metadata, icons, and platform SDK installations are deliberately not fabricated in source control. They require the owner's accounts and release choices.
