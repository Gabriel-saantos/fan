import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingFile = rootProject.file("key.properties")
val signingProperties = Properties().apply {
    if (signingFile.exists()) signingFile.inputStream().use { load(it) }
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

    signingConfigs {
        if (signingFile.exists()) {
            create("release") {
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
                storePassword = signingProperties.getProperty("storePassword")
                storeFile = rootProject.file(signingProperties.getProperty("storeFile"))
            }
        }
    }

    buildTypes {
        release {
            // Production builds use an explicit upload key; never the debug certificate.
            if (signingFile.exists()) signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter { source = "../.." }

// FlutterFire configured via Dart FirebaseOptions; no google-services.json
// or Google Services Gradle plugin is required for the basic integration.
