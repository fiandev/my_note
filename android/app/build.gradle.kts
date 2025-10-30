import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fiandev.my_note"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // --- Load key.properties ---
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    defaultConfig {
        applicationId = "com.fiandev.my_note"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    packaging {
        resources.excludes += setOf(
            "META-INF/LICENSE",
            "META-INF/LICENSE.txt",
            "META-INF/NOTICE",
            "META-INF/NOTICE.txt"
        )
    }
}

flutter {
    source = "../.."
}

gradle.taskGraph.whenReady {
    allTasks.forEach { task ->
        if (
            task.name.contains("bundleRelease", ignoreCase = true) ||
            task.name.contains("assembleRelease", ignoreCase = true)
        ) {
            // pastikan path absolut dari android/app
            val pubspec = project.projectDir.resolve("../../pubspec.yaml").normalize()
            if (pubspec.exists()) {
                val lines = pubspec.readLines().toMutableList()
                val index = lines.indexOfFirst { it.trim().startsWith("version:") }

                if (index >= 0) {
                    val line = lines[index]
                    val version = line.substringAfter("version:").trim()
                    val parts = version.split("+")
                    val name = parts[0].trim()
                    val code = parts.getOrNull(1)?.toIntOrNull() ?: 1
                    val newCode = code + 1

                    lines[index] = "version: $name+$newCode"
                    pubspec.writeText(lines.joinToString("\n"))
                } else {
                }
            } else {
                println("⚠️ pubspec.yaml tidak ditemukan di ${pubspec.absolutePath}")
            }
        }
    }
}
