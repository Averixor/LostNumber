# Consumer rules merged into the app when this AAR is a dependency.
# Keep only our plugin entry; Firebase Auth shrinks via app R8 + android/proguard-rules.pro.

-keep class com.averixor.lostnumber.firebase.** { *; }

-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.auth.** { *; }

-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
