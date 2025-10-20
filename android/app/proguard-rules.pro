# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Keep all classes in the main package and MainActivity specifically
-keep class com.fiandev.my_note.** { *; }
-keep class com.fiandev.my_note.MainActivity { *; }

# Keep all Activities
-keep class * extends android.app.Activity { *; }

# Keep SharedPreferences related classes
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$Editor { *; }

# General Flutter rules
-dontwarn io.flutter.**
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception