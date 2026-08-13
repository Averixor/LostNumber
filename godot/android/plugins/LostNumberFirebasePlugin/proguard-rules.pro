# Keep Godot plugin entry + Firebase Auth reflection surfaces used by Sign-In.
-keep class com.averixor.lostnumber.firebase.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
