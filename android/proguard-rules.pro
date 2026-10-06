# Lost Number — R8 / ProGuard rules for Godot Gradle release AAB.
# Copied into godot/android/build/proguard-rules.pro on each export (see scripts/lib/r8-android.sh).

# Godot engine + plugin loader (reflection / JNI).
-keep class org.godotengine.godot.** { *; }
-keep class * extends org.godotengine.godot.plugin.GodotPlugin { *; }
-keepclassmembers class * {
    @org.godotengine.godot.plugin.UsedByGodot *;
}

# Our Android plugins (entry points discovered by Godot).
-keep class com.averixor.lostnumber.firebase.** { *; }
-keep class com.averixor.lostnumber.LostNumberMigrationPlugin { *; }

# Credential Manager + Google ID token (Sign-In).
-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }

# Firebase Auth surfaces used by LostNumberFirebasePlugin (no blanket firebase.** keep).
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.auth.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
