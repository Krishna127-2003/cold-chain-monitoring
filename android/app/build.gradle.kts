import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

/**
 * 🔐 Load keystore properties (for release signing)
 */
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.marken.coldchain"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ FIX: Required for flutter_local_notifications to work on older Android versions
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.marken.coldchain"
        // ✅ Ensure minSdk is at least 21 for multidex/notifications
        minSdk = flutter.minSdkVersion 
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ FIX: Prevents "DexArchiveMergerException" if the app grows large
        multiDexEnabled = true
    }

    /**
     * 🔑 Signing configs
     */
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true 
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    /**
     * ✅ FIX: Support 16 KB memory page sizes (Required for Android 15+)
     */
    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
    
    // ✅ FIX: The library that enables modern Java features (Desugaring)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

/**
 * ✅ FIX: Copy APK into Flutter expected folder so flutter run can find it
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
