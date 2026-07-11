# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.playhandler.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Prevent obfuscation of R classes
-keep class **.R$* {
    *;
}
-keep class **.R {
    *;
}

# Flutter Play Store Split / Deferred components
-dontwarn com.google.android.play.core.**

