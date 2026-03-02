# Add project-specific ProGuard rules here.
# By default, the rules in this file are appended at the end of the specified ProGuard configuration.

# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; } # In case Firebase is added later

# Keep the models if you use JSON serialization
-keep class com.example.einhod_water.models.** { *; }

# Keep Riverpod/other libraries if they need reflection
-keep class com.google.crypto.tink.** { *; }
-keep class net.sqlcipher.** { *; }

# Ignore missing Google Play Core classes
-dontwarn com.google.android.play.core.**
