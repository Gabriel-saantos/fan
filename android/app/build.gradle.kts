plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tooapps.fan"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.tooapps.fan"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // LOCAL TEST ONLY. Add your own upload keystore before Play Store distribution.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter { source = "../.." }

// FlutterFire configured via Dart FirebaseOptions; no google-services.json
// or Google Services Gradle plugin is required for the basic integration.
