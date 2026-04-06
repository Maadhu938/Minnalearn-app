# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google API
-keep class com.google.api.** { *; }
-dontwarn com.google.api.**

# OkHttp (used by Firebase)
-dontwarn okhttp3.**
-dontwarn okio.**

# Google Play Core (Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Gson (used by scheduling payloads)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
