import java.io.File

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fiandev.my_note"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.fiandev.my_note"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Remove ndk.abiFilters to avoid conflicts with split-per-abi
        // ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a") }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug") // tetap untuk testing
            isMinifyEnabled = false // Temporarily disable for testing
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }


    packaging {
        resources {
            excludes += setOf(
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Rename output file untuk testing
// afterEvaluate {
//     tasks.matching { it.name.startsWith("package") && it.name.endsWith("Release") }.configureEach {
//         doLast {
//             val outputDir = File("$buildDir/outputs/flutter-apk")
//             outputDir.listFiles()?.forEach { file ->
//                 if (file.name.endsWith(".apk")) {
//                     val newName = "com.fiandev.my_note-${file.name}"
//                     file.renameTo(File(outputDir, newName))
//                 }
//             }
//         }
//     }
// }
