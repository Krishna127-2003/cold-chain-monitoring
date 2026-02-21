# Flutter engine
-keep class io.flutter.** { *; }

# Flutter plugins
-keep class io.flutter.plugins.** { *; }

# JSON parsing
-keep class org.json.** { *; }
-keep class com.google.gson.** { *; }

# Local notifications plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep model fields (prevents broken JSON mapping)
-keepclassmembers class * {
    <fields>;
}

# Don't warn on missing optional libs
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# Flutter Play Core (fix R8 missing classes)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
