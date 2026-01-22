plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cold_chain_monitor"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.cold_chain_monitor"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
}

/**
 * ✅ FIX: Copy APK into Flutter expected folder so flutter run can find it
 * Works safely with Kotlin DSL + AGP 8+
 */
val copyDebugApkToFlutter = tasks.register("copyDebugApkToFlutter") {
    doLast {
        val apkFrom = file("$buildDir/outputs/apk/debug/app-debug.apk")
        val apkToDir = file("${rootProject.projectDir.parentFile}/build/app/outputs/flutter-apk")

        apkToDir.mkdirs()

        if (apkFrom.exists()) {
            apkFrom.copyTo(file("$apkToDir/app-debug.apk"), overwrite = true)
            println("✅ Copied APK to: $apkToDir/app-debug.apk")
        } else {
            println("❌ APK not found at: $apkFrom")
        }
    }
}

/**
 * ✅ attach after assembleDebug safely
 */
tasks.matching { it.name == "assembleDebug" }.configureEach {
    finalizedBy(copyDebugApkToFlutter)
}
