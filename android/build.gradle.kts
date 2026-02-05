plugins {
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // ✅ FORCE lStar FIX: This overrides the internal library version for all plugins
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core" && requested.name == "core") {
                useVersion("1.13.1")
            }
            if (requested.group == "androidx.core" && requested.name == "core-ktx") {
                useVersion("1.13.1")
            }
        }
    }
}

// ✅ FORCE SDK 36: This forces google_mlkit_commons to use a modern SDK
subprojects {
    afterEvaluate {
        // We use 'project' specifically to target the plugin modules
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            // Force the plugins to compile against SDK 36 to support lStar
            compileSdkVersion(36)
            buildToolsVersion("36.1.0")
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}