import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// AD-19: the release keystore lives outside git. android/key.properties (gitignored)
// points at it. Release builds never fall back to the debug key.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) {
        keyPropertiesFile.inputStream().use { load(it) }
    }
}

android {
    // applicationId never changes (AD-19).
    namespace = "com.mordehay.groupay"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mordehay.groupay"
        minSdk = 35
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".dev"
        }
        // Flutter's plugin creates `profile` via initWith(debug) before the
        // block above runs, so it needs the suffix too: it must never install
        // as com.mordehay.groupay signed with the debug key.
        getByName("profile") {
            applicationIdSuffix = ".dev"
        }
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Fail loudly when a release task runs without key.properties.
gradle.taskGraph.whenReady {
    val needsReleaseKey = allTasks.any { task ->
        task.project == project && task.name.contains("Release")
    }
    if (needsReleaseKey && !keyPropertiesFile.exists()) {
        throw GradleException(
            "Release signing requires android/key.properties " +
                "(storeFile, storePassword, keyAlias, keyPassword) pointing at the " +
                "GrouPay release keystore. It is missing at ${keyPropertiesFile.absolutePath}. " +
                "Restore it from backup; never sign a release with the debug key."
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
